param(
    [string]$Namespace = "recon-platform",
    [string]$ObservabilityNamespace = "observability",
    [string]$OutRoot = "E:\workspace\evidence\runs"
)

$ErrorActionPreference = "Continue"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runDir = Join-Path $OutRoot $timestamp
$logsDir = Join-Path $runDir "logs"
$clusterDir = Join-Path $runDir "cluster"
$screenshotsDir = Join-Path $runDir "screenshots"

New-Item -ItemType Directory -Force -Path $logsDir, $clusterDir, $screenshotsDir | Out-Null

function Save-Command {
    param(
        [string]$Name,
        [string]$Command
    )

    $path = Join-Path $clusterDir $Name
    "COMMAND: $Command" | Out-File -LiteralPath $path -Encoding utf8
    "CAPTURED_AT: $(Get-Date -Format o)" | Out-File -LiteralPath $path -Encoding utf8 -Append
    "" | Out-File -LiteralPath $path -Encoding utf8 -Append

    try {
        Invoke-Expression $Command 2>&1 | Out-File -LiteralPath $path -Encoding utf8 -Append
    }
    catch {
        "ERROR: $($_.Exception.Message)" | Out-File -LiteralPath $path -Encoding utf8 -Append
    }
}

function Save-Logs {
    param(
        [string]$Name,
        [string]$Selector,
        [string]$Ns
    )

    $path = Join-Path $logsDir "$Name.log"
    $cmd = "kubectl logs -n $Ns -l $Selector --all-containers=true --tail=500"
    "COMMAND: $cmd" | Out-File -LiteralPath $path -Encoding utf8
    "CAPTURED_AT: $(Get-Date -Format o)" | Out-File -LiteralPath $path -Encoding utf8 -Append
    "" | Out-File -LiteralPath $path -Encoding utf8 -Append

    try {
        Invoke-Expression $cmd 2>&1 | Out-File -LiteralPath $path -Encoding utf8 -Append
    }
    catch {
        "ERROR: $($_.Exception.Message)" | Out-File -LiteralPath $path -Encoding utf8 -Append
    }
}

Save-Command "00-current-context.txt" "kubectl config current-context"
Save-Command "01-recon-pods.txt" "kubectl get pods -n $Namespace -o wide"
Save-Command "02-recon-deployments.txt" "kubectl get deployments -n $Namespace -o wide"
Save-Command "03-recon-services.txt" "kubectl get services -n $Namespace -o wide"
Save-Command "04-recon-hpa.txt" "kubectl get hpa -n $Namespace"
Save-Command "05-recon-pvc.txt" "kubectl get pvc -n $Namespace"
Save-Command "06-observability-pods.txt" "kubectl get pods -n $ObservabilityNamespace -o wide"
Save-Command "07-observability-services.txt" "kubectl get services -n $ObservabilityNamespace -o wide"
Save-Command "08-recon-events.txt" "kubectl get events -n $Namespace --sort-by=.lastTimestamp"
Save-Command "09-observability-events.txt" "kubectl get events -n $ObservabilityNamespace --sort-by=.lastTimestamp"
Save-Command "10-configmap.txt" "kubectl get configmap recon-runtime-config -n $Namespace -o yaml"
Save-Command "11-serviceaccount.txt" "kubectl get serviceaccount recon-app-sa -n $Namespace -o yaml"

Save-Logs "producer" "app=recon-producer-app" $Namespace
Save-Logs "consumer" "app=recon-consumer-app" $Namespace
Save-Logs "dashboard-api" "app=recon-dashboard-api" $Namespace
Save-Logs "ibm-mq" "app=ibm-mq" $Namespace
Save-Logs "prometheus" "app=prometheus" $ObservabilityNamespace
Save-Logs "grafana" "app=grafana" $ObservabilityNamespace
Save-Logs "jaeger" "app=jaeger" $ObservabilityNamespace

$readmePath = Join-Path $runDir "README.md"
@"
# Evidence Run $timestamp

Captured Kubernetes state and logs into:

- cluster: `$clusterDir`
- logs: `$logsDir`
- screenshots: `$screenshotsDir`

Add manual screenshots into the screenshots folder:

1. GitHub Actions success
2. AWS EKS pods/workloads
3. Dashboard API status
4. Dashboard API queue backlog
5. Grafana SRE dashboard
6. Jaeger correlation trace
7. RDS PostgreSQL
8. Secrets Manager metadata without values
9. Failure recovery demonstration

Do not store credentials or AWS secret values.
"@ | Out-File -LiteralPath $readmePath -Encoding utf8

Write-Host "Evidence folder created:"
Write-Host $runDir
Write-Host ""
Write-Host "Put screenshots here:"
Write-Host $screenshotsDir

