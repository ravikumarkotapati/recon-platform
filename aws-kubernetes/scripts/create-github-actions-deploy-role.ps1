param(
    [Parameter(Mandatory = $true)]
    [string]$GitHubOwner,

    [Parameter(Mandatory = $true)]
    [string]$GitHubRepo,

    [string]$AccountId = "",
    [string]$Region = "ap-southeast-1",
    [string]$ClusterName = "recon-eks",
    [string]$Branch = "main",
    [string]$RoleName = "recon-github-actions-deploy-role"
)

$ErrorActionPreference = "Stop"
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

function Assert-LastCommandSucceeded {
    param([string]$Action)
    if ($LASTEXITCODE -ne 0) {
        throw "$Action failed. Check the AWS/eksctl error above."
    }
}

if ([string]::IsNullOrWhiteSpace($AccountId)) {
    $AccountId = (aws sts get-caller-identity --query Account --output text).Trim()
    Assert-LastCommandSucceeded "Detect AWS account id"
}

if ([string]::IsNullOrWhiteSpace($AccountId)) {
    throw "AWS account id is empty. Run aws configure / aws sts get-caller-identity first."
}

$oidcUrl = "https://token.actions.githubusercontent.com"
$oidcHost = "token.actions.githubusercontent.com"
$providerArn = "arn:aws:iam::$AccountId`:oidc-provider/$oidcHost"
$roleArn = "arn:aws:iam::$AccountId`:role/$RoleName"
$policyName = "$RoleName-policy"
$policyArn = "arn:aws:iam::$AccountId`:policy/$policyName"
$repoSubject = "repo:$GitHubOwner/$GitHubRepo`:ref:refs/heads/$Branch"

Write-Host "Using AWS account: $AccountId"
Write-Host "Using GitHub subject: $repoSubject"

$providersJson = aws iam list-open-id-connect-providers
Assert-LastCommandSucceeded "List IAM OIDC providers"
$providers = $providersJson | ConvertFrom-Json
$providerExists = $providers.OpenIDConnectProviderList.Arn -contains $providerArn

if (-not $providerExists) {
    Write-Host "Creating GitHub OIDC provider..."
    aws iam create-open-id-connect-provider `
        --url $oidcUrl `
        --client-id-list sts.amazonaws.com `
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 | Out-Null
    Assert-LastCommandSucceeded "Create GitHub OIDC provider"
} else {
    Write-Host "GitHub OIDC provider already exists."
}

$trustPolicy = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Principal = @{
                Federated = $providerArn
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = @{
                StringEquals = @{
                    "$oidcHost`:aud" = "sts.amazonaws.com"
                    "$oidcHost`:sub" = $repoSubject
                }
            }
        }
    )
} | ConvertTo-Json -Depth 10

$trustFile = New-TemporaryFile
$trustPolicy | Set-Content -Path $trustFile -Encoding ascii

$existingRoleArn = (aws iam list-roles --query "Roles[?RoleName=='$RoleName'].Arn | [0]" --output text).Trim()
Assert-LastCommandSucceeded "Check existing IAM role"
if ($existingRoleArn -and $existingRoleArn -ne "None") {
    Write-Host "Updating existing IAM role trust policy..."
    aws iam update-assume-role-policy `
        --role-name $RoleName `
        --policy-document "file://$trustFile" | Out-Null
    Assert-LastCommandSucceeded "Update IAM role trust policy"
} else {
    Write-Host "Creating IAM role..."
    aws iam create-role `
        --role-name $RoleName `
        --assume-role-policy-document "file://$trustFile" | Out-Null
    Assert-LastCommandSucceeded "Create IAM role"
}

$deployPolicy = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Sid = "EcrAuthorization"
            Effect = "Allow"
            Action = @("ecr:GetAuthorizationToken")
            Resource = "*"
        },
        @{
            Sid = "EcrRepositoryPush"
            Effect = "Allow"
            Action = @(
                "ecr:BatchCheckLayerAvailability",
                "ecr:CompleteLayerUpload",
                "ecr:CreateRepository",
                "ecr:DescribeRepositories",
                "ecr:InitiateLayerUpload",
                "ecr:PutImage",
                "ecr:UploadLayerPart"
            )
            Resource = @(
                "arn:aws:ecr:$Region`:$AccountId`:repository/recon-producer-app",
                "arn:aws:ecr:$Region`:$AccountId`:repository/recon-consumer-app",
                "arn:aws:ecr:$Region`:$AccountId`:repository/recon-dashboard-api"
            )
        },
        @{
            Sid = "EksDescribeCluster"
            Effect = "Allow"
            Action = @("eks:DescribeCluster")
            Resource = "arn:aws:eks:$Region`:$AccountId`:cluster/$ClusterName"
        }
    )
} | ConvertTo-Json -Depth 10

$policyFile = New-TemporaryFile
$deployPolicy | Set-Content -Path $policyFile -Encoding ascii

$existingPolicyArn = (aws iam list-policies --scope Local --query "Policies[?PolicyName=='$policyName'].Arn | [0]" --output text).Trim()
Assert-LastCommandSucceeded "Check existing IAM policy"
if ($existingPolicyArn -and $existingPolicyArn -ne "None") {
    Write-Host "Creating new IAM policy version..."
    aws iam create-policy-version `
        --policy-arn $policyArn `
        --policy-document "file://$policyFile" `
        --set-as-default | Out-Null
    Assert-LastCommandSucceeded "Create IAM policy version"
} else {
    Write-Host "Creating IAM policy..."
    aws iam create-policy `
        --policy-name $policyName `
        --policy-document "file://$policyFile" | Out-Null
    Assert-LastCommandSucceeded "Create IAM policy"
}

Write-Host "Attaching IAM policy to role..."
aws iam attach-role-policy `
    --role-name $RoleName `
    --policy-arn $policyArn | Out-Null
Assert-LastCommandSucceeded "Attach IAM policy"

$eksctlCommand = Get-Command eksctl -ErrorAction SilentlyContinue
if ($null -eq $eksctlCommand) {
    Write-Warning "eksctl was not found. Run this manually after installing eksctl:"
    Write-Host "eksctl create iamidentitymapping --cluster $ClusterName --region $Region --arn $roleArn --group system:masters --username github-actions --no-duplicate-arns"
} else {
    Write-Host "Adding GitHub Actions role to EKS aws-auth using eksctl..."
    eksctl create iamidentitymapping `
        --cluster $ClusterName `
        --region $Region `
        --arn $roleArn `
        --group system:masters `
        --username github-actions `
        --no-duplicate-arns
    Assert-LastCommandSucceeded "Create EKS IAM identity mapping"
}

Write-Host ""
Write-Host "GitHub Actions role ARN:"
Write-Host $roleArn
