param(
    [Parameter(Mandatory = $true)]
    [string]$GitHubOwner,

    [Parameter(Mandatory = $true)]
    [string]$GitHubRepo,

    [string]$AccountId = "860510876120",
    [string]$Region = "ap-southeast-1",
    [string]$ClusterName = "recon-eks",
    [string]$Branch = "main",
    [string]$RoleName = "recon-github-actions-deploy-role"
)

$ErrorActionPreference = "Stop"

$oidcUrl = "https://token.actions.githubusercontent.com"
$oidcHost = "token.actions.githubusercontent.com"
$providerArn = "arn:aws:iam::$AccountId:oidc-provider/$oidcHost"
$roleArn = "arn:aws:iam::$AccountId:role/$RoleName"
$policyName = "$RoleName-policy"
$policyArn = "arn:aws:iam::$AccountId:policy/$policyName"
$repoSubject = "repo:$GitHubOwner/$GitHubRepo`:ref:refs/heads/$Branch"

$providers = aws iam list-open-id-connect-providers | ConvertFrom-Json
$providerExists = $providers.OpenIDConnectProviderList.Arn -contains $providerArn

if (-not $providerExists) {
    aws iam create-open-id-connect-provider `
        --url $oidcUrl `
        --client-id-list sts.amazonaws.com `
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 | Out-Null
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

try {
    aws iam get-role --role-name $RoleName | Out-Null
    aws iam update-assume-role-policy `
        --role-name $RoleName `
        --policy-document "file://$trustFile" | Out-Null
} catch {
    aws iam create-role `
        --role-name $RoleName `
        --assume-role-policy-document "file://$trustFile" | Out-Null
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

try {
    aws iam get-policy --policy-arn $policyArn | Out-Null
    aws iam create-policy-version `
        --policy-arn $policyArn `
        --policy-document "file://$policyFile" `
        --set-as-default | Out-Null
} catch {
    aws iam create-policy `
        --policy-name $policyName `
        --policy-document "file://$policyFile" | Out-Null
}

aws iam attach-role-policy `
    --role-name $RoleName `
    --policy-arn $policyArn | Out-Null

try {
    aws eks create-access-entry `
        --region $Region `
        --cluster-name $ClusterName `
        --principal-arn $roleArn `
        --type STANDARD | Out-Null
} catch {
    Write-Host "EKS access entry already exists or could not be created automatically. Continuing..."
}

try {
    aws eks associate-access-policy `
        --region $Region `
        --cluster-name $ClusterName `
        --principal-arn $roleArn `
        --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy `
        --access-scope type=cluster | Out-Null
} catch {
    Write-Host "EKS access policy already associated or could not be created automatically. Continuing..."
}

Write-Host "GitHub Actions role ARN:"
Write-Host $roleArn
