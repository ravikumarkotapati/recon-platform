# recon-producer-app

Producer Application for Phase 1.

## Responsibility

- Publish reconciliation transactions into IBM MQ.
- Support configurable TPS.
- Generate valid and invalid transactions.
- Include correlation IDs and tracing metadata.

## Does Not Contain

- No reconciliation processing service.
- No database entity/repository.
- No dashboard/API controllers.

## Run

Main class: `com.ntt.recon.ReconProducerApplication`

Port: `8081`

```powershell
mvn clean spring-boot:run
```

## Secrets

Credentials are not stored in `application.yml`. Use AWS Secrets Manager for MQ and database credentials.

See:

```text
AWS_SECRETS_MANAGER.md
```
