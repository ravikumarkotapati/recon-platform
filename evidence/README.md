# Demonstration Evidence Capture

This folder is the place to store assessment evidence: Kubernetes state, application logs, MQ evidence, database/API checks, Grafana screenshots, Jaeger traces, and GitHub Actions proof.

## Current Status

The implementation already contains observability and runbooks, but screenshots and exported cluster logs should be captured per demo run and saved here.

Use:

```powershell
powershell -ExecutionPolicy Bypass -File E:\workspace\tools\capture-demo-evidence.ps1
```

The script creates a timestamped folder:

```text
E:\workspace\evidence\runs\<timestamp>\
```

## Screenshot Checklist

Save screenshots into the generated `screenshots` folder:

1. GitHub Actions successful run for `Build and Deploy to AWS EKS`.
2. AWS EKS workload view showing producer, consumer, dashboard, IBM MQ, Prometheus, Grafana, and Jaeger pods.
3. `kubectl get pods -n recon-platform` output.
4. Dashboard API status endpoint showing total, reconciled, invalid, failed counts.
5. Dashboard API queue backlog endpoint showing live MQ queue depths.
6. Grafana SRE dashboard showing total messages published, total messages processed, TPS, retry/backout/DLQ, and queue depth.
7. Jaeger trace showing producer-to-consumer trace propagation.
8. RDS PostgreSQL database instance in the same VPC as EKS.
9. AWS Secrets Manager secret metadata page, without exposing secret values.
10. Failure recovery demonstration, for example MQRC 2035, consumer crash recovery, duplicate replay, or deadlock retry.

## Evidence Naming

Use clear names:

```text
01-github-actions-success.png
02-eks-pods-running.png
03-dashboard-status.png
04-dashboard-queue-depth.png
05-grafana-sre-dashboard.png
06-jaeger-trace-correlation.png
07-rds-postgresql.png
08-secrets-manager-metadata.png
09-failure-recovery-mqrc2035.png
```

Do not capture passwords, AWS secret values, access keys, or database credentials.

