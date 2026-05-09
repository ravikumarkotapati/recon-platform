# MQRC 2035 Failure Analysis and Recovery Walkthrough

This document captures a real production-style incident observed during the AWS EKS deployment:

```text
JMSWMQ2008: Failed to open MQ queue 'RECON.IN'
MQRC_NOT_AUTHORIZED, reason '2035'
```

This is an important presentation point because it demonstrates IBM MQ authorization troubleshooting, runtime observability, failure isolation, and controlled recovery without exposing secrets.

## Incident Summary

| Item | Detail |
|---|---|
| Date observed | 2026-05-09 |
| Environment | AWS EKS, namespace `recon-platform` |
| Impact | Applications were running, but no reconciliation messages were processed |
| Affected components | `recon-producer-app`, `recon-consumer-app` |
| Root cause | IBM MQ application principal `app` did not have sufficient OAM authority on reconciliation queues |
| MQ error | `MQRC 2035 - MQRC_NOT_AUTHORIZED` |
| Security outcome | Credentials were not logged; only MQ reason code and queue names were visible |

## Symptoms

Pods appeared healthy from Kubernetes:

```powershell
kubectl get pods -n recon-platform
```

Example:

```text
ibm-mq-0                               1/1 Running
recon-producer-app-...                 1/1 Running
recon-consumer-app-...                 1/1 Running
recon-dashboard-api-...                1/1 Running
```

However, producer and consumer logs showed authorization failures.

Producer symptom:

```text
event=producer_backpressure_depth_check_failed queue=RECON.IN
MQRC_NOT_AUTHORIZED, reason '2035'
```

Consumer symptom:

```text
Setup of JMS message listener invoker failed for destination 'RECON.IN'
MQRC_NOT_AUTHORIZED, reason '2035'
```

Retry queue symptom:

```text
Setup of JMS message listener invoker failed for destination 'RECON.RETRY'
MQRC_NOT_AUTHORIZED, reason '2035'
```

## Why Kubernetes Still Showed Pods as Running

This was not a container crash. The applications started successfully, health endpoints were available, and Spring JMS kept retrying the queue connection in the background.

That is expected behavior for a resilient consumer:

- The process stays alive.
- Health endpoints remain available.
- JMS listener recovery continues.
- Logs and metrics expose the failure reason.
- No secrets are printed.

## Root Cause

The IBM MQ queue manager accepted the client connection, but the `app` principal did not have required object authorities.

Required authorities:

| Object | Required authority |
|---|---|
| Queue manager | `CONNECT`, `INQ`, `DSP` |
| `RECON.IN` | `PUT`, `GET`, `BROWSE`, `INQ`, `DSP` |
| `RECON.RETRY` | `PUT`, `GET`, `BROWSE`, `INQ`, `DSP` |
| `RECON.BACKOUT` | `PUT`, `GET`, `BROWSE`, `INQ`, `DSP` |
| `RECON.REPLAY` | `PUT`, `GET`, `BROWSE`, `INQ`, `DSP` |
| `SYSTEM.DEAD.LETTER.QUEUE` | `PUT`, `GET`, `BROWSE`, `INQ`, `DSP` |

The producer needs `PUT` to publish to `RECON.IN`.

The consumer needs `GET` from `RECON.IN` and `RECON.RETRY`, and `PUT` to retry/backout/DLQ queues.

The dashboard/API needs queue browse/depth visibility for backlog reporting.

## Recovery Commands

Run the following against the running MQ pod. These commands grant the minimum queue authorities needed by the application principal.

## Exact Commands Used to Diagnose and Fix

Use these commands in order during the demo.

1. Confirm pods are running:

```powershell
kubectl get pods -n recon-platform
```

2. Check producer logs:

```powershell
kubectl logs -n recon-platform deploy/recon-producer-app --tail=160
```

Expected failure before fix:

```text
event=producer_backpressure_depth_check_failed queue=RECON.IN
MQRC_NOT_AUTHORIZED, reason '2035'
```

3. Check consumer logs:

```powershell
kubectl logs -n recon-platform deploy/recon-consumer-app --tail=160
```

Expected failure before fix:

```text
Setup of JMS message listener invoker failed for destination 'RECON.IN'
MQRC_NOT_AUTHORIZED, reason '2035'
```

4. Apply MQ OAM authorities:

```powershell
cd E:\workspace
powershell -ExecutionPolicy Bypass -File aws-kubernetes\scripts\apply-mq-oam-authorities.ps1
```

5. Restart producer and consumer so JMS connections are recreated:

```powershell
kubectl rollout restart deployment/recon-producer-app -n recon-platform
kubectl rollout restart deployment/recon-consumer-app -n recon-platform
```

6. Wait for deployments to become ready:

```powershell
kubectl rollout status deployment/recon-producer-app -n recon-platform
kubectl rollout status deployment/recon-consumer-app -n recon-platform
```

7. Confirm pods are healthy after restart:

```powershell
kubectl get pods -n recon-platform
```

8. Validate producer is publishing:

```powershell
kubectl logs -n recon-platform deploy/recon-producer-app --tail=80
```

Expected success after fix:

```text
event=transaction_published
```

9. Validate consumer is processing:

```powershell
kubectl logs -n recon-platform deploy/recon-consumer-app --tail=120
```

Expected success after fix:

```text
event=transaction_consumed
event=reconciliation_persisted
```

10. Check MQ queue depth directly:

```powershell
kubectl exec -n recon-platform ibm-mq-0 -- bash -lc "echo 'DISPLAY QLOCAL(RECON.IN) CURDEPTH' | runmqsc QM1"
kubectl exec -n recon-platform ibm-mq-0 -- bash -lc "echo 'DISPLAY QLOCAL(RECON.RETRY) CURDEPTH' | runmqsc QM1"
kubectl exec -n recon-platform ibm-mq-0 -- bash -lc "echo 'DISPLAY QLOCAL(RECON.BACKOUT) CURDEPTH' | runmqsc QM1"
```

11. Validate dashboard/API status:

```powershell
kubectl port-forward -n recon-platform svc/recon-dashboard-api 8083:8083
curl http://localhost:8083/api/reconciliation/status
curl http://localhost:8083/api/reconciliation/queues
curl http://localhost:8083/api/reconciliation/failed
```

Scripted option:

```powershell
cd E:\workspace
powershell -ExecutionPolicy Bypass -File aws-kubernetes\scripts\apply-mq-oam-authorities.ps1
```

Manual option:

```powershell
kubectl exec -n recon-platform ibm-mq-0 -- bash -lc "cat <<'EOF' | runmqsc QM1
SET AUTHREC OBJTYPE(QMGR) PRINCIPAL('app') AUTHADD(CONNECT,INQ,DSP)
SET AUTHREC PROFILE('RECON.IN') OBJTYPE(QUEUE) PRINCIPAL('app') AUTHADD(PUT,GET,BROWSE,INQ,DSP)
SET AUTHREC PROFILE('RECON.RETRY') OBJTYPE(QUEUE) PRINCIPAL('app') AUTHADD(PUT,GET,BROWSE,INQ,DSP)
SET AUTHREC PROFILE('RECON.BACKOUT') OBJTYPE(QUEUE) PRINCIPAL('app') AUTHADD(PUT,GET,BROWSE,INQ,DSP)
SET AUTHREC PROFILE('RECON.REPLAY') OBJTYPE(QUEUE) PRINCIPAL('app') AUTHADD(PUT,GET,BROWSE,INQ,DSP)
SET AUTHREC PROFILE('SYSTEM.DEAD.LETTER.QUEUE') OBJTYPE(QUEUE) PRINCIPAL('app') AUTHADD(PUT,GET,BROWSE,INQ,DSP)
REFRESH SECURITY TYPE(AUTHSERV)
EOF"
```

Restart producer and consumer so they reconnect cleanly:

```powershell
kubectl rollout restart deployment/recon-producer-app -n recon-platform
kubectl rollout restart deployment/recon-consumer-app -n recon-platform
kubectl rollout status deployment/recon-producer-app -n recon-platform
kubectl rollout status deployment/recon-consumer-app -n recon-platform
```

## Validation

Check producer logs:

```powershell
kubectl logs -n recon-platform deploy/recon-producer-app --tail=80
```

Expected:

```text
event=transaction_published
```

Check consumer logs:

```powershell
kubectl logs -n recon-platform deploy/recon-consumer-app --tail=120
```

Expected:

```text
event=transaction_consumed
event=reconciliation_persisted
```

Check queue depth in MQ:

```powershell
kubectl exec -n recon-platform ibm-mq-0 -- bash -lc "echo 'DISPLAY QLOCAL(RECON.IN) CURDEPTH' | runmqsc QM1"
kubectl exec -n recon-platform ibm-mq-0 -- bash -lc "echo 'DISPLAY QLOCAL(RECON.RETRY) CURDEPTH' | runmqsc QM1"
kubectl exec -n recon-platform ibm-mq-0 -- bash -lc "echo 'DISPLAY QLOCAL(RECON.BACKOUT) CURDEPTH' | runmqsc QM1"
```

Check dashboard/API:

```powershell
kubectl port-forward -n recon-platform svc/recon-dashboard-api 8083:8083
curl http://localhost:8083/api/reconciliation/status
curl http://localhost:8083/api/reconciliation/queues
curl http://localhost:8083/api/reconciliation/failed
```

## Presentation Walkthrough

Use this flow in the assessment demo:

1. Show all pods are running.
2. Show that no records are being processed.
3. Show producer and consumer logs with `MQRC 2035`.
4. Explain that this is an authorization failure, not an application crash.
5. Explain MQ object-level security: queue manager authority and queue authority are separate.
6. Apply the OAM recovery commands.
7. Restart producer and consumer.
8. Show `transaction_published` and `transaction_consumed` logs.
9. Show dashboard status and queue depth.
10. Explain why credentials were not committed or logged.

## Design Decision

The platform intentionally treats `MQRC 2035` as a diagnosable operational failure:

- It logs the MQ reason code.
- It avoids logging passwords or secret values.
- It keeps health endpoints available.
- It allows Kubernetes to keep the pod running while JMS reconnect logic retries.
- It provides a clear runbook for MQ administrators to fix authority.

This matches banking-grade support expectations because production MQ authorization is commonly managed separately from application deployment.

## Long-Term Hardening

Recommended production improvements:

- Manage MQ OAM records through versioned infrastructure automation.
- Use distinct MQ principals for producer, consumer, and dashboard/API.
- Grant least privilege per component:
  - Producer: `PUT` on `RECON.IN`
  - Consumer: `GET` on input/retry, `PUT` on retry/backout/DLQ
  - Dashboard/API: `BROWSE` and `INQ` only where needed
- Alert on repeated `MQRC 2035` log events.
- Add a synthetic MQ authorization check during release validation.
- Keep MQ credentials in AWS Secrets Manager and rotate them periodically.
