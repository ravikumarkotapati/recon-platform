# Phase 6 - Observability and SRE Walkthrough

This phase adds an operational observability layer for the reconciliation platform on EKS.

## What Is Implemented

| Requirement | Implementation |
|---|---|
| Structured logging | JSON console logs through Logstash Logback encoder in all three apps |
| Correlation IDs | JMS correlation ID and MDC `correlationId` included in app logs |
| Distributed tracing | Micrometer/OpenTelemetry OTLP export to Jaeger, plus W3C `traceparent` propagation across IBM MQ |
| Metrics collection | Spring Boot Actuator Prometheus endpoint on every app |
| Queue depth monitoring | `mq_queue_depth{queue="..."}` gauge from dashboard API |
| Deadlock monitoring | `recon_db_deadlock_retries_total` counter |
| TPS metrics | `recon_producer_messages_total` and `recon_consumer_messages_total` rates |
| Retry metrics | `recon_retry_messages_total`, `recon_backout_messages_total`, `recon_dead_letter_messages_total` |
| Producer back-pressure | `recon_producer_backpressure_skips_total` and `recon_producer_input_queue_depth_observed` prevent endless queue growth |
| Error-rate dashboards | Grafana dashboard panel and Prometheus alert |
| Alerts | Prometheus alert rules for app down, retry backlog, backout, DLQ, deadlocks, error rate |

## Deployed Components

Namespace:

```text
observability
```

Pods:

```text
prometheus
grafana
jaeger
```

Services:

```text
prometheus       ClusterIP
grafana          LoadBalancer
jaeger-query     LoadBalancer
jaeger-collector ClusterIP
```

## Deploy

The observability manifests are included in the existing kustomize bundle:

```powershell
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
$grafanaPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
kubectl create secret generic grafana-admin-credentials -n observability --from-literal=admin-user=admin --from-literal=admin-password=$grafanaPassword --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -k E:\workspace\aws-kubernetes\manifests
```

GitHub Actions also deploys these manifests automatically on `main` and creates the Grafana Secret if it is missing.

## Verify

```powershell
kubectl get pods -n observability
kubectl get svc -n observability
kubectl get pods -n recon-platform
```

All pods should be `Running`.

## Access Grafana

Get the external URL:

```powershell
kubectl get svc grafana -n observability
```

Open:

```text
http://<grafana-load-balancer>
```

Credentials are stored in the `grafana-admin-credentials` Kubernetes Secret. GitHub Actions creates the Secret with a random password if it does not already exist.

Get the username:

```powershell
kubectl get secret grafana-admin-credentials -n observability -o jsonpath="{.data.admin-user}" | ForEach-Object { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) }
```

Get the password:

```powershell
kubectl get secret grafana-admin-credentials -n observability -o jsonpath="{.data.admin-password}" | ForEach-Object { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) }
```

For a production deployment, rotate this Secret through a managed process or use SSO.

Open dashboard:

```text
Dashboards -> Reconciliation -> Reconciliation Platform SRE
```

Dashboard panels:

- Producer TPS
- Consumer TPS
- Consumer error rate
- Deadlock retries
- MQ queue depth
- Retry/backout/dead-letter message movement
- Application availability
- HTTP p95 latency

## Access Jaeger

Get the external URL:

```powershell
kubectl get svc jaeger-query -n observability
```

Open:

```text
http://<jaeger-query-load-balancer>
```

Search services:

```text
recon-producer-app
recon-consumer-app
recon-dashboard-api
```

Use Jaeger to demonstrate:

- HTTP API trace for dashboard requests
- Trace IDs in app logs
- Correlation from user request to service behavior

## Access Prometheus

Prometheus is internal by default:

```powershell
kubectl port-forward -n observability svc/prometheus 9090:9090
```

Open:

```text
http://localhost:9090
```

Useful queries:

```promql
up{namespace="recon-platform"}
rate(recon_producer_messages_total[1m])
increase(recon_producer_backpressure_skips_total[5m])
recon_producer_input_queue_depth_observed
rate(recon_consumer_messages_total[1m])
mq_queue_depth
increase(recon_retry_messages_total[5m])
increase(recon_backout_messages_total[5m])
increase(recon_dead_letter_messages_total[5m])
increase(recon_db_deadlock_retries_total[5m])
rate(recon_consumer_processing_failures_total[5m]) / clamp_min(rate(recon_consumer_messages_total[5m]), 1)
histogram_quantile(0.95, sum(rate(http_server_requests_seconds_bucket[5m])) by (le, app, uri))
```

Alert rules:

```powershell
kubectl get configmap prometheus-alert-rules -n observability -o yaml
```

Prometheus alert page:

```text
http://localhost:9090/alerts
```

## Correlation Tracing Demo

1. Generate traffic with producer running normally.

2. Watch producer logs:

```powershell
kubectl logs -n recon-platform deploy/recon-producer-app --tail=50
```

Look for:

```text
event=transaction_published
correlationId
traceId
spanId
```

3. Watch consumer logs:

```powershell
kubectl logs -n recon-platform deploy/recon-consumer-app --tail=80
```

Look for the same `correlationId`.

4. Search Jaeger by service and time range.

The producer writes W3C trace context to each MQ message:

```text
traceparent=00-<traceId>-<spanId>-01
traceId=<traceId>
```

The consumer extracts `traceparent`, adds `traceId` and `spanId` to structured logs, and preserves the same trace context when moving messages to retry or backout queues.

5. Use the dashboard API to inspect status:

```powershell
Invoke-RestMethod http://<dashboard-load-balancer>/api/reconciliation/status
```

## Failure Analysis Scenarios

### Retry Queue Backlog

Simulate retry-generating failures from the producer simulation API if exposed internally, or temporarily set simulation mode in the app during local testing.

Observe:

```promql
mq_queue_depth{queue="RECON.RETRY"}
increase(recon_retry_messages_total[5m])
```

Expected:

- Retry counter increases.
- Retry queue depth rises.
- Alert `ReconRetryQueueBacklog` fires if backlog remains above threshold.

### Deadlock Monitoring

Use the DB deadlock simulation mode.

Observe:

```promql
increase(recon_db_deadlock_retries_total[5m])
```

Expected:

- Consumer performs bounded retries.
- Metric increments.
- Alert `ReconDeadlockRetriesHigh` fires if retries are sustained.

### Poison Message / Backout

Generate invalid or repeatedly failing messages.

Observe:

```promql
mq_queue_depth{queue="RECON.BACKOUT"}
increase(recon_backout_messages_total[5m])
```

Expected:

- Failed messages move from input/retry to backout queue.
- Backout alert fires.
- Failed transactions are visible from dashboard API:

```powershell
Invoke-RestMethod http://<dashboard-load-balancer>/api/reconciliation/failed?page=0"&"size=25
```

### Dead-Letter Queue

Force MQ routing or authorization failure during a controlled test.

Observe:

```promql
mq_queue_depth{queue="SYSTEM.DEAD.LETTER.QUEUE"}
increase(recon_dead_letter_messages_total[5m])
```

Expected:

- DLQ listener logs `event=dead_letter_received`.
- DLQ alert fires.

## Operational Notes

- Prometheus uses `emptyDir` storage for this assessment. For production, use EBS-backed PVC with retention sizing.
- Grafana credentials are stored in a Kubernetes Secret. Use SSO or centralized secret rotation for production.
- Jaeger all-in-one uses in-memory storage. For production, use Elasticsearch/OpenSearch or managed tracing backend.
- Dashboards and alerts are committed as code, so GitHub Actions keeps the observability layer reproducible.
