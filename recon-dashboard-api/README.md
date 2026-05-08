# recon-dashboard-api

Dashboard/API Application for Phase 1.

## Responsibility

- Expose reconciliation status.
- Expose failed transaction view.
- Expose queue backlog visibility.
- Expose health endpoints.
- Provide replay endpoint for failed/backout messages.

## Does Not Contain

- No producer scheduler/generator.
- No MQ consumer listener.
- No reconciliation processing service.

## Run

Main class: `com.ntt.recon.ReconDashboardApiApplication`

Port: `8083`

```powershell
mvn clean spring-boot:run
```

## Secrets

Credentials are not stored in `application.yml`. Use AWS Secrets Manager for MQ and database credentials.

See:

```text
AWS_SECRETS_MANAGER.md
```
