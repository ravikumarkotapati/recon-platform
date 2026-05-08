param(
    [string]$Region = "ap-southeast-1",
    [string]$SecretName = "recon/prod/app",
    [string]$Namespace = "recon-platform"
)

$secretJson = aws secretsmanager get-secret-value `
    --region $Region `
    --secret-id $SecretName `
    --query SecretString `
    --output text

$secret = $secretJson | ConvertFrom-Json

kubectl create secret generic ibm-mq-runtime `
    --namespace $Namespace `
    --from-literal=MQ_APP_PASSWORD=$($secret.MQ_APP_PASSWORD) `
    --from-literal=MQ_ADMIN_PASSWORD=$($secret.MQ_ADMIN_PASSWORD) `
    --dry-run=client `
    -o yaml | kubectl apply -f -
