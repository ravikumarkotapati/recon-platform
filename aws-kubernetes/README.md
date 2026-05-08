# AWS EKS Kubernetes Deployment

Raw Kubernetes manifests for deploying the reconciliation platform on AWS EKS.

## Target Architecture

- EKS hosts:
  - `recon-producer-app`
  - `recon-consumer-app`
  - `recon-dashboard-api`
  - IBM MQ StatefulSet with EBS-backed persistent storage
- Amazon RDS PostgreSQL hosts reconciliation data.
- AWS Secrets Manager stores DB/MQ credentials and runtime secret values.
- IRSA gives the application pods read access to Secrets Manager.
- HPA scales stateless application pods.
- Readiness/liveness probes use Spring Boot Actuator.

## Folder Layout

```text
aws-kubernetes/
  manifests/
    00-namespace.yaml
    00-storageclass-gp3.yaml
    01-serviceaccounts.yaml
    02-configmap.yaml
    03-mq-configmap.yaml
    04-mq-statefulset.yaml
    05-producer-deployment.yaml
    06-consumer-deployment.yaml
    07-dashboard-deployment.yaml
    08-services.yaml
    09-hpa.yaml
    10-pdb.yaml
    11-network-policy.yaml
    kustomization.yaml
  scripts/
    build-and-push-ecr.ps1
    create-aws-secret-template.json
    sync-mq-runtime-secret.ps1
  sql/
    001-reconciliation-schema.sql
```

## Prerequisites

Install/configure:

- AWS CLI
- Docker
- kubectl
- eksctl
- An EKS cluster with:
  - OIDC provider enabled for IRSA
  - EBS CSI driver installed
  - Metrics Server installed for HPA

## 1. Create ECR Repositories

```powershell
aws ecr create-repository --repository-name recon-producer-app --region ap-southeast-1
aws ecr create-repository --repository-name recon-consumer-app --region ap-southeast-1
aws ecr create-repository --repository-name recon-dashboard-api --region ap-southeast-1
```

## 2. Build and Push Images

Edit account/region values in:

[build-and-push-ecr.ps1](<E:\workspace\aws-kubernetes\scripts\build-and-push-ecr.ps1>)

Then run:

```powershell
cd E:\workspace\aws-kubernetes\scripts
.\build-and-push-ecr.ps1
```

## 3. Create AWS Secrets Manager Secret

Use this template:

[create-aws-secret-template.json](<E:\workspace\aws-kubernetes\scripts\create-aws-secret-template.json>)

Create the secret after replacing placeholder values locally:

```powershell
aws secretsmanager create-secret `
  --name recon/prod/app `
  --secret-string file://create-aws-secret-template.json `
  --region ap-southeast-1
```

Do not commit real secret values.

## 4. Create MQ Runtime Kubernetes Secret from AWS Secrets Manager

IBM MQ container startup needs runtime passwords as environment variables. This script reads AWS Secrets Manager and creates a Kubernetes Secret without storing secrets in Git:

```powershell
cd E:\workspace\aws-kubernetes\scripts
.\sync-mq-runtime-secret.ps1
```

## 5. Configure Placeholders

Replace placeholders in manifests:

- `<AWS_ACCOUNT_ID>`
- `<AWS_REGION>`
- `<ECR_REGISTRY>`
- `<IRSA_ROLE_ARN>`
- `<DASHBOARD_HOSTNAME>`

For example:

```text
<ECR_REGISTRY> = 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com
<IRSA_ROLE_ARN> = arn:aws:iam::123456789012:role/recon-platform-secrets-role
```

## 6. Apply Manifests

```powershell
cd E:\workspace\aws-kubernetes\manifests
kubectl apply -f 00-namespace.yaml
kubectl apply -f 00-storageclass-gp3.yaml
kubectl apply -f 01-serviceaccounts.yaml
kubectl apply -f 02-configmap.yaml
kubectl apply -f 03-mq-configmap.yaml
kubectl apply -f 04-mq-statefulset.yaml
kubectl apply -f 05-producer-deployment.yaml
kubectl apply -f 06-consumer-deployment.yaml
kubectl apply -f 07-dashboard-deployment.yaml
kubectl apply -f 08-services.yaml
kubectl apply -f 09-hpa.yaml
kubectl apply -f 10-pdb.yaml
kubectl apply -f 11-network-policy.yaml
```

Or apply the whole folder:

```powershell
kubectl apply -k E:\workspace\aws-kubernetes\manifests
```

## 7. Verify

```powershell
kubectl get pods -n recon-platform
kubectl get svc -n recon-platform
kubectl get hpa -n recon-platform
kubectl logs -n recon-platform deploy/recon-producer-app
kubectl logs -n recon-platform deploy/recon-consumer-app
kubectl logs -n recon-platform deploy/recon-dashboard-api
```

Health:

```powershell
kubectl port-forward -n recon-platform svc/recon-dashboard-api 8083:8083
curl http://localhost:8083/actuator/health
curl http://localhost:8083/api/reconciliation/status
```

## Production Notes

- Use RDS Multi-AZ for PostgreSQL.
- Use EBS gp3 for IBM MQ persistent volume.
- Use IRSA for AWS Secrets Manager access.
- Use NetworkPolicies to restrict pod-to-pod traffic.
- Use HPA for producer, consumer, and dashboard.
- Use PDBs for availability during node drain/rolling updates.
- For production ingress, prefer AWS Load Balancer Controller with TLS.
