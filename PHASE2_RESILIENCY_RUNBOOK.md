# Phase 2 - Messaging and Resiliency Engineering Runbook

This runbook demonstrates the required IBM MQ and resiliency scenarios for the three separate applications:

- Producer: `E:\workspace\recon-producer-app`, port `8081`
- Consumer/Reconciliation: `E:\workspace\recon-consumer-app`, port `8082`
- Dashboard/API: `E:\workspace\recon-dashboard-api`, port `8083`

## Implemented Capabilities

| Requirement | Implementation |
|---|---|
| Retry queues | Consumer moves first processing failures to `RECON.RETRY` with `reconRetryAttempt` metadata. |
| Backout queues | Consumer moves exhausted retries or poison redeliveries to `RECON.BACKOUT`. |
| Dead-letter queue handling | Consumer listens to `SYSTEM.DEAD.LETTER.QUEUE` and records/logs DLQ messages. |
| MQRC 2035 handling | Producer, consumer, and dashboard classify MQ authorization failures and log `mqrc=2035`. |
| Poison message handling | Null/invalid/failing payloads are retried, then moved to backout after retry threshold. |
| Message replay | Dashboard `POST /api/reconciliation/replay` republishes a transaction with replay metadata. |
| Deadlock retry handling | Consumer retries `DeadlockLoserDataAccessException` with exponential backoff. |
| Exponential backoff | Consumer backoff doubles per retry attempt and caps at 2 seconds. |
| Circuit breaker | `databaseCircuitBreaker` protects DB reconciliation calls. |
| Graceful degradation | Circuit breaker fallback logs and throws controlled retryable failure. |
| Controlled consumer scaling | JMS listener concurrency is configured via `CONSUMER_CONCURRENCY` and `CONSUMER_MAX_CONCURRENCY`. |
| Bulkhead isolation | `databaseBulkhead` limits concurrent DB reconciliation work. |

## Start Local Dependencies

```powershell
cd E:\workspace\recon-local-dependencies
Copy-Item .env.example .env
docker compose up -d
Get-Content .\mq\mq-setup.mqsc | docker exec -i recon-ibm-mq runmqsc QM1
```

## Start the Apps from IntelliJ

Use Java 17 and the `local` Spring profile for each app.

Producer VM/profile:

```text
SPRING_PROFILES_ACTIVE=local
```

Consumer VM/profile:

```text
SPRING_PROFILES_ACTIVE=local
```

Dashboard VM/profile:

```text
SPRING_PROFILES_ACTIVE=local
```

Health checks:

```powershell
curl http://localhost:8081/actuator/health
curl http://localhost:8082/actuator/health
curl http://localhost:8083/actuator/health
```

## Normal Flow

Producer defaults to `NORMAL` mode and publishes transactions to `RECON.IN`.

Check status:

```powershell
curl http://localhost:8083/api/reconciliation/status
curl http://localhost:8083/api/reconciliation/failed
curl http://localhost:8083/api/reconciliation/queues
```

## Simulation Modes

Change producer mode:

```powershell
curl -X PUT http://localhost:8081/api/simulation/DB_DEADLOCK
curl -X PUT http://localhost:8081/api/simulation/SLOW_DATABASE
curl -X PUT http://localhost:8081/api/simulation/DUPLICATE_MESSAGE
curl -X PUT http://localhost:8081/api/simulation/MQ_OUTAGE
curl -X PUT http://localhost:8081/api/simulation/CONSUMER_CRASH
curl -X POST http://localhost:8081/api/simulation/reset
```

## Scenario 1 - Database Deadlock

```powershell
curl -X PUT http://localhost:8081/api/simulation/DB_DEADLOCK
```

Expected behavior:

- Consumer receives messages.
- `ReconciliationService` throws simulated deadlock.
- Consumer retries internally using exponential backoff.
- If exhausted, message is moved to `RECON.RETRY`.
- After retry attempts are exhausted, message moves to `RECON.BACKOUT`.
- Metrics increase: `recon_db_deadlock_retries_total`, `recon_retry_messages_total`, `recon_backout_messages_total`.

Recovery:

```powershell
curl -X POST http://localhost:8081/api/simulation/reset
```

Replay a failed transaction through dashboard:

```powershell
curl -X POST http://localhost:8083/api/reconciliation/replay `
  -H "Content-Type: application/json" `
  -d '{"originalCorrelationId":"corr-from-log","transaction":{"transactionId":"manual-replay-1","sourceSystem":"CARD","accountNumber":"ACCT-1","amount":10.00,"currency":"SGD","transactionTime":"2026-05-08T00:00:00Z","intentionallyInvalid":false,"simulationMode":"NORMAL","tracing":{}}}'
```

## Scenario 2 - MQ Outage

```powershell
curl -X PUT http://localhost:8081/api/simulation/MQ_OUTAGE
```

Expected behavior:

- Producer intentionally stops publishing and logs `mq_outage_simulated=true`.
- No duplicate or partial records are written.
- Existing queued messages continue to drain.

Recovery:

```powershell
curl -X POST http://localhost:8081/api/simulation/reset
```

## Scenario 3 - Consumer Crash

```powershell
curl -X PUT http://localhost:8081/api/simulation/CONSUMER_CRASH
```

Expected behavior:

- Consumer exits with code `137` when it receives the message.
- In Kubernetes, the pod restarts automatically.
- Locally, restart the consumer app from IntelliJ.
- The unacknowledged MQ message is redelivered because processing did not commit.

Recovery:

```powershell
curl -X POST http://localhost:8081/api/simulation/reset
```

Restart consumer, then observe processing continues.

## Scenario 4 - Slow Database

```powershell
curl -X PUT http://localhost:8081/api/simulation/SLOW_DATABASE
```

Expected behavior:

- Consumer sleeps based on `recon.db-slow-threshold-ms`.
- Bulkhead limits concurrent DB work.
- Circuit breaker opens if failures exceed configured threshold.
- Health and metrics remain available.

Recovery:

```powershell
curl -X POST http://localhost:8081/api/simulation/reset
```

## Scenario 5 - Duplicate Messages

```powershell
curl -X PUT http://localhost:8081/api/simulation/DUPLICATE_MESSAGE
```

Expected behavior:

- Producer publishes deliberate duplicate correlation IDs.
- Consumer idempotency checks `correlation_id`.
- Duplicate is ignored or unique constraint race is treated as duplicate.
- Metric increases: `recon_duplicate_messages_total`.

Recovery:

```powershell
curl -X POST http://localhost:8081/api/simulation/reset
```

## Scenario 6 - MQRC 2035 Authorization Failure

Temporarily run one app with a bad MQ password or bad user:

```text
MQ_USER=bad-user
MQ_PASSWORD=bad-password
```

Expected behavior:

- App logs contain `event=mq_authorization_failed mqrc=2035`.
- Failure does not expose secrets.
- Recovery is to restore the correct AWS Secrets Manager value or local environment variable.

## Queue Inspection

```powershell
docker exec -it recon-ibm-mq runmqsc QM1
DISPLAY QLOCAL(RECON.IN) CURDEPTH
DISPLAY QLOCAL(RECON.RETRY) CURDEPTH
DISPLAY QLOCAL(RECON.BACKOUT) CURDEPTH
DISPLAY QLOCAL(SYSTEM.DEAD.LETTER.QUEUE) CURDEPTH
END
```

Prometheus metrics:

```powershell
curl http://localhost:8081/actuator/prometheus
curl http://localhost:8082/actuator/prometheus
curl http://localhost:8083/actuator/prometheus
```
