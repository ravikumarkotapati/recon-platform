# Local Dependencies

This folder starts local IBM MQ and PostgreSQL for the three reconciliation apps.

## Start

```powershell
cd E:\workspace\recon-local-dependencies
Copy-Item .env.example .env
docker compose up -d
docker ps
```

## Create MQ Queues

Wait until the MQ container is healthy, then run:

```powershell
Get-Content .\mq\mq-setup.mqsc | docker exec -i recon-ibm-mq runmqsc QM1
```

## Run Apps Locally

Run each IntelliJ project with:

```text
SPRING_PROFILES_ACTIVE=local
```

The local profile points the apps at this Compose stack.

## Useful URLs

- IBM MQ Console: https://localhost:9443/ibmmq/console
- PostgreSQL: localhost:5432/recondb

## Stop

```powershell
docker compose down
```

To remove local data as well:

```powershell
docker compose down -v
```
