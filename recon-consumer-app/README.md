# recon-consumer-app

Consumer/Reconciliation Service for Phase 1.

## Responsibility

- Consume IBM MQ messages.
- Process reconciliation transactions.
- Persist records into PostgreSQL.
- Handle retries and failures.
- Implement idempotency.
- Support concurrent processing safely.

## Does Not Contain

- No producer scheduler/generator.
- No dashboard API controller.

## Run Locally

Boot the service without AWS, PostgreSQL, or an active MQ listener:

```powershell
mvn spring-boot:run "-Dspring-boot.run.profiles=local"
```

The local profile uses an in-memory H2 database and sets `spring.jms.listener.auto-startup=false`, so it is useful for smoke testing the web/actuator startup path only.

## Run With Real Dependencies

Main class: `com.ntt.recon.ReconConsumerApplication`

Port: `8082`

Set the required environment variables first. `DB_URL` must be a JDBC URL, for example `jdbc:postgresql://localhost:5432/reconciliation`.

```powershell
mvn clean spring-boot:run
```

## Secrets

Credentials are not stored in `application.yml`. Use AWS Secrets Manager for MQ and database credentials.

See:

```text
AWS_SECRETS_MANAGER.md
```
