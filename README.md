# NTT Reconciliation Platform

Enterprise-grade reconciliation platform built with Java 17, IBM MQ, PostgreSQL, Docker, Kubernetes, AWS EKS, AWS Secrets Manager, and GitHub Actions.

## Repository Layout

```text
recon-producer-app/        Producer service, publishes reconciliation messages to IBM MQ
recon-consumer-app/        Consumer/reconciliation service, persists records to PostgreSQL
recon-dashboard-api/       Dashboard/API service, exposes status and replay APIs
recon-local-dependencies/  Local Docker Compose dependencies
aws-kubernetes/            EKS manifests, SQL schema, and deployment scripts
PHASE2_RESILIENCY_RUNBOOK.md
PHASE2_MQRC2035_FAILURE_ANALYSIS.md
```

## Local Build

```powershell
mvn -f recon-producer-app/pom.xml verify
mvn -f recon-consumer-app/pom.xml verify
mvn -f recon-dashboard-api/pom.xml verify
```

## AWS Deployment

The GitHub Actions workflow in `.github/workflows/aws-ci-cd.yml` builds all three apps, pushes images to ECR, updates the EKS deployments, and waits for rollout.

Required GitHub secret:

```text
AWS_GITHUB_ACTIONS_ROLE_ARN
```

Create the AWS role for GitHub Actions OIDC:

```powershell
powershell -ExecutionPolicy Bypass -File aws-kubernetes/scripts/create-github-actions-deploy-role.ps1 `
  -GitHubOwner <your-github-user-or-org> `
  -GitHubRepo <your-repo-name>
```

Copy the printed role ARN into the GitHub repository secret named `AWS_GITHUB_ACTIONS_ROLE_ARN`.

The AWS role should be assumable by GitHub OIDC and have least-privilege access to:

```text
ecr:GetAuthorizationToken
ecr:BatchCheckLayerAvailability
ecr:CompleteLayerUpload
ecr:CreateRepository
ecr:DescribeRepositories
ecr:InitiateLayerUpload
ecr:PutImage
ecr:UploadLayerPart
eks:DescribeCluster
```

Kubernetes deployment authorization still depends on the EKS access entry or `aws-auth` mapping for that AWS role.

## Runtime Secrets

Runtime DB and MQ credentials are stored in AWS Secrets Manager, not in Git.

Secret name used by the manifests:

```text
recon/prod/app
```

Use `aws-kubernetes/scripts/create-aws-secret-template.json` only as a local template and replace placeholders locally before creating/updating the AWS secret.

## Producer Traffic Controls

The producer continuously generates randomized reconciliation messages while it is running:

```text
PRODUCER_TPS              messages per scheduled run
PRODUCER_INTERVAL_MS      scheduler interval
INVALID_PERCENT           percentage of generated invalid transactions
MAX_INPUT_QUEUE_DEPTH     pause publishing when RECON.IN reaches this depth
```

The EKS default is intentionally conservative for the assessment cluster: `2 TPS`, `10%` invalid messages, and producer back-pressure at `250` messages in `RECON.IN`.
