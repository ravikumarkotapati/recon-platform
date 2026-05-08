# AWS Secrets Manager Configuration

This application does not store MQ or database passwords in committed property files.

`application.yml` contains only placeholders. Runtime secrets are loaded from AWS Secrets Manager when this flag is enabled:

```text
AWS_SECRETS_ENABLED=true
```

## Required IntelliJ Environment Variables

Set these in `Run -> Edit Configurations -> Environment variables`:

```text
AWS_SECRETS_ENABLED=true;AWS_REGION=ap-southeast-1;AWS_SECRET_NAME=<secret-name>
```

For local development without AWS, you may set the individual environment variables directly in IntelliJ instead of enabling Secrets Manager.

## Producer Secret

Secret name example:

```text
ntt/reconciliation/producer
```

Secret value JSON:

```json
{
  "MQ_QMGR": "QM1",
  "MQ_CHANNEL": "DEV.APP.SVRCONN",
  "MQ_CONN_NAME": "localhost(1414)",
  "MQ_USER": "app",
  "MQ_PASSWORD": "replace-with-real-secret"
}
```

## Consumer Secret

Secret name example:

```text
ntt/reconciliation/consumer
```

Secret value JSON:

```json
{
  "DB_URL": "jdbc:postgresql://localhost:5432/reconciliation",
  "DB_USER": "recon",
  "DB_PASSWORD": "replace-with-real-secret",
  "MQ_QMGR": "QM1",
  "MQ_CHANNEL": "DEV.APP.SVRCONN",
  "MQ_CONN_NAME": "localhost(1414)",
  "MQ_USER": "app",
  "MQ_PASSWORD": "replace-with-real-secret"
}
```

## Dashboard/API Secret

Secret name example:

```text
ntt/reconciliation/dashboard
```

Secret value JSON:

```json
{
  "DB_URL": "jdbc:postgresql://localhost:5432/reconciliation",
  "DB_USER": "recon",
  "DB_PASSWORD": "replace-with-real-secret",
  "MQ_QMGR": "QM1",
  "MQ_CHANNEL": "DEV.APP.SVRCONN",
  "MQ_CONN_NAME": "localhost(1414)",
  "MQ_USER": "app",
  "MQ_PASSWORD": "replace-with-real-secret"
}
```

## AWS CLI Create Commands

Producer:

```bash
aws secretsmanager create-secret \
  --region ap-southeast-1 \
  --name ntt/reconciliation/producer \
  --secret-string '{"MQ_QMGR":"QM1","MQ_CHANNEL":"DEV.APP.SVRCONN","MQ_CONN_NAME":"localhost(1414)","MQ_USER":"app","MQ_PASSWORD":"replace-with-real-secret"}'
```

Consumer:

```bash
aws secretsmanager create-secret \
  --region ap-southeast-1 \
  --name ntt/reconciliation/consumer \
  --secret-string '{"DB_URL":"jdbc:postgresql://localhost:5432/reconciliation","DB_USER":"recon","DB_PASSWORD":"replace-with-real-secret","MQ_QMGR":"QM1","MQ_CHANNEL":"DEV.APP.SVRCONN","MQ_CONN_NAME":"localhost(1414)","MQ_USER":"app","MQ_PASSWORD":"replace-with-real-secret"}'
```

Dashboard/API:

```bash
aws secretsmanager create-secret \
  --region ap-southeast-1 \
  --name ntt/reconciliation/dashboard \
  --secret-string '{"DB_URL":"jdbc:postgresql://localhost:5432/reconciliation","DB_USER":"recon","DB_PASSWORD":"replace-with-real-secret","MQ_QMGR":"QM1","MQ_CHANNEL":"DEV.APP.SVRCONN","MQ_CONN_NAME":"localhost(1414)","MQ_USER":"app","MQ_PASSWORD":"replace-with-real-secret"}'
```

## Required IAM Permission

Each application runtime identity needs only read access to its own secret.

Example policy statement:

```json
{
  "Effect": "Allow",
  "Action": [
    "secretsmanager:GetSecretValue"
  ],
  "Resource": "arn:aws:secretsmanager:ap-southeast-1:<account-id>:secret:ntt/reconciliation/*"
}
```

For Kubernetes on AWS EKS, use IAM Roles for Service Accounts instead of static AWS access keys.
