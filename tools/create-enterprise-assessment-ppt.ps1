param(
    [string]$OutputPath = "E:\workspace\Enterprise_Reconciliation_Platform_Principal_Engineer_Assessment.pptx"
)

$ErrorActionPreference = "Stop"

function Rgb($r, $g, $b) {
    return [int]($r + ($g -shl 8) + ($b -shl 16))
}

$darkBg = Rgb 248 251 255
$darkBg2 = Rgb 237 247 255
$panel = Rgb 255 255 255
$panel2 = Rgb 245 250 255
$navy = Rgb 24 48 78
$blue = Rgb 0 118 210
$teal = Rgb 0 153 136
$orange = Rgb 238 151 38
$red = Rgb 213 79 79
$purple = Rgb 112 94 198
$cyan = Rgb 0 169 224
$gray = Rgb 91 110 134
$lightBlue = Rgb 226 241 255
$lightGreen = Rgb 225 248 244
$lightOrange = Rgb 255 242 221
$lightRed = Rgb 255 232 232
$lightPurple = Rgb 239 235 255
$lightCyan = Rgb 222 246 255
$lightGray = Rgb 247 250 253
$white = Rgb 255 255 255

function Set-Text($shape, [string]$text, [int]$size = 16, [int]$color = $navy, [bool]$bold = $false) {
    $shape.TextFrame.TextRange.Text = $text
    $shape.TextFrame.MarginLeft = 8
    $shape.TextFrame.MarginRight = 8
    $shape.TextFrame.MarginTop = 6
    $shape.TextFrame.MarginBottom = 6
    $shape.TextFrame.WordWrap = -1
    $shape.TextFrame.TextRange.Font.Name = "Aptos"
    $shape.TextFrame.TextRange.Font.Size = $size
    $shape.TextFrame.TextRange.Font.Color.RGB = $color
    if ($bold) { $shape.TextFrame.TextRange.Font.Bold = -1 } else { $shape.TextFrame.TextRange.Font.Bold = 0 }
}

function Add-TextBox($slide, [double]$x, [double]$y, [double]$w, [double]$h, [string]$text, [int]$size = 16, [int]$color = $navy, [bool]$bold = $false) {
    $shape = $slide.Shapes.AddTextbox(1, $x, $y, $w, $h)
    Set-Text $shape $text $size $color $bold
    $shape.Line.Visible = 0
    return $shape
}

function Add-TechnicalBackground($slide) {
    $bg = $slide.Shapes.AddShape(1, 0, 0, 960, 540)
    $bg.Fill.ForeColor.RGB = $darkBg
    $bg.Line.Visible = 0

    $rightWash = $slide.Shapes.AddShape(1, 735, 0, 225, 540)
    $rightWash.Fill.ForeColor.RGB = Rgb 232 246 255
    $rightWash.Fill.Transparency = 0.08
    $rightWash.Line.Visible = 0

    $diag1 = $slide.Shapes.AddShape(7, 805, -35, 210, 210)
    $diag1.Fill.ForeColor.RGB = Rgb 214 240 255
    $diag1.Fill.Transparency = 0.12
    $diag1.Line.Visible = 0
    $diag1.Rotation = 24

    $diag2 = $slide.Shapes.AddShape(7, 820, 360, 220, 220)
    $diag2.Fill.ForeColor.RGB = Rgb 229 247 244
    $diag2.Fill.Transparency = 0.1
    $diag2.Line.Visible = 0
    $diag2.Rotation = 24

    $accent = $slide.Shapes.AddShape(1, 0, 0, 960, 8)
    $accent.Fill.ForeColor.RGB = $cyan
    $accent.Line.Visible = 0

    $accent2 = $slide.Shapes.AddShape(1, 0, 8, 960, 3)
    $accent2.Fill.ForeColor.RGB = $navy
    $accent2.Fill.Transparency = 0.15
    $accent2.Line.Visible = 0

    $softBand = $slide.Shapes.AddShape(1, 0, 11, 960, 92)
    $softBand.Fill.ForeColor.RGB = $darkBg2
    $softBand.Fill.Transparency = 0.18
    $softBand.Line.Visible = 0
    $bottomLine = $slide.Shapes.AddLine(0, 103, 960, 103)
    $bottomLine.Line.ForeColor.RGB = Rgb 221 235 247
    $bottomLine.Line.Weight = 1
}

function Add-Box($slide, [double]$x, [double]$y, [double]$w, [double]$h, [string]$text, [int]$fill, [int]$line, [int]$size = 14, [bool]$bold = $false, [int]$textColor = $navy) {
    $shape = $slide.Shapes.AddShape(5, $x, $y, $w, $h)
    $shape.Fill.ForeColor.RGB = $fill
    $shape.Fill.Transparency = 0
    $shape.Line.ForeColor.RGB = $line
    $shape.Line.Weight = 1.6
    $shape.Shadow.Visible = -1
    $shape.Shadow.ForeColor.RGB = Rgb 187 204 222
    $shape.Shadow.Transparency = 0.72
    $shape.Shadow.Blur = 6
    $shape.Shadow.OffsetX = 1
    $shape.Shadow.OffsetY = 2
    Set-Text $shape $text $size $textColor $bold
    return $shape
}

function Add-Header($slide, [string]$title, [string]$section = "") {
    Add-TechnicalBackground $slide
    if ($section.Length -gt 0) {
        Add-TextBox $slide 40 20 350 20 ($section.ToUpper()) 10 $cyan $true | Out-Null
    }
    Add-TextBox $slide 38 40 800 40 $title 24 $navy $true | Out-Null
    $line = $slide.Shapes.AddLine(40, 82, 420, 82)
    $line.Line.ForeColor.RGB = $cyan
    $line.Line.Weight = 2.4
    if ($section.Length -gt 0) {
        Add-TextBox $slide 805 24 125 22 "2026" 9 $gray $false | Out-Null
    }
}

function Add-Footer($slide, [int]$n) {
    Add-TextBox $slide 28 516 700 16 "Enterprise Reconciliation Platform | Principal Engineer / Architect Assessment" 8 $gray $false | Out-Null
    Add-TextBox $slide 900 516 35 16 "$n" 8 $gray $false | Out-Null
}

function Add-Line($slide, [double]$x1, [double]$y1, [double]$x2, [double]$y2, [int]$color = $gray, [bool]$arrow = $true) {
    $line = $slide.Shapes.AddLine($x1, $y1, $x2, $y2)
    $line.Line.ForeColor.RGB = $color
    $line.Line.Weight = 1.8
    if ($arrow) { $line.Line.EndArrowheadStyle = 3 }
    return $line
}

function Add-Bullets($slide, [double]$x, [double]$y, [double]$w, [double]$h, [string[]]$items, [int]$size = 15, [int]$color = $gray) {
    $text = ($items | ForEach-Object { "- $_" }) -join "`r"
    return Add-TextBox $slide $x $y $w $h $text $size $color $false
}

function Add-TwoColumnSlide($pres, [string]$title, [string]$section, [string]$leftTitle, [string[]]$leftItems, [string]$rightTitle, [string[]]$rightItems, [int]$n) {
    $slide = $pres.Slides.Add($pres.Slides.Count + 1, 12)
    Add-Header $slide $title $section
    Add-Box $slide 45 95 405 360 $leftTitle $lightBlue $blue 18 $true | Out-Null
    Add-Bullets $slide 65 150 365 285 $leftItems 14 $navy | Out-Null
    Add-Box $slide 510 95 405 360 $rightTitle $lightGreen $teal 18 $true | Out-Null
    Add-Bullets $slide 530 150 365 285 $rightItems 14 $navy | Out-Null
    Add-Footer $slide $n
}

$ppt = New-Object -ComObject PowerPoint.Application
$ppt.Visible = -1
$pres = $ppt.Presentations.Add()
$pres.PageSetup.SlideWidth = 960
$pres.PageSetup.SlideHeight = 540

$slideNo = 1

# 1
$slide = $pres.Slides.Add($slideNo, 12)
Add-TechnicalBackground $slide
Add-TextBox $slide 58 72 310 24 "EXECUTIVE SUMMARY" 12 $cyan $true | Out-Null
$under = $slide.Shapes.AddLine(58, 105, 270, 105)
$under.Line.ForeColor.RGB = $cyan
$under.Line.Weight = 1.4
Add-TextBox $slide 54 130 660 102 "Enterprise Reconciliation`rPlatform Assessment" 40 $navy $true | Out-Null
Add-TextBox $slide 58 265 640 82 "Working end-to-end reconciliation platform demonstrating production Java engineering, IBM MQ messaging, AWS Kubernetes deployment, resiliency patterns, observability and AI-assisted delivery." 18 $gray $false | Out-Null
Add-Box $slide 750 96 135 66 "Producer" $lightBlue $blue 12 $true | Out-Null
Add-Box $slide 750 230 135 66 "IBM MQ`rQueues" $lightCyan $cyan 12 $true | Out-Null
Add-Box $slide 750 306 135 66 "PostgreSQL`rState" $lightPurple $purple 12 $true | Out-Null
Add-Line $slide 818 162 818 230 $cyan $true | Out-Null
Add-Line $slide 818 296 818 306 $cyan $true | Out-Null
Add-Line $slide 706 263 750 263 $cyan $true | Out-Null
Add-Box $slide 60 420 250 62 "Business Outcome`rReliable transaction reconciliation" $lightBlue $blue 12 $true | Out-Null
Add-Box $slide 355 420 250 62 "Engineering Evidence`rCode, tests, MQ, database, APIs" $lightGreen $teal 12 $true | Out-Null
Add-Box $slide 650 420 250 62 "Operational Readiness`rKubernetes, dashboards, recovery" $lightOrange $orange 12 $true | Out-Null
Add-TextBox $slide 60 490 780 20 "Principal Architect Level - 2026" 12 $gray $false | Out-Null
Add-Footer $slide $slideNo

# 2
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "Assessment Coverage and Evidence Map" "Overview"
$headers = @("Evaluation Area", "Implemented Evidence", "Where Demonstrated")
$rows = @(
    @("Enterprise-grade design", "Separated producer, consumer and dashboard; MQ topology; security; HA/DR; capacity planning", "Architecture docs + Draw.io"),
    @("Hands-on production code", "Java 17 Spring Boot apps, tests, exception handling, idempotency, Dockerfiles", "GitHub repository"),
    @("Messaging and resiliency", "Retry queues, backout, DLQ, replay, MQRC 2035 runbook, poison handling", "Phase 2 docs and code"),
    @("Cloud-native deployment", "AWS EKS, ECR, RDS PostgreSQL, Secrets Manager, raw Kubernetes manifests", "aws-kubernetes folder"),
    @("SRE and observability", "Prometheus, Grafana, Jaeger, OpenTelemetry, queue depth, TPS, alerts", "Phase 6 docs + dashboard"),
    @("AI-assisted workflow", "Prompting, generated-code validation, troubleshooting corrections, architecture prompt pack", "Phase 5 slides")
)
$x = 35; $y = 92; $w = @(190, 430, 250); $h = 42
for ($i=0; $i -lt 3; $i++) { Add-Box $slide ($x + ($w[0..($i-1)] | Measure-Object -Sum).Sum) $y $w[$i] $h $headers[$i] $panel $cyan 13 $true $white | Out-Null }
$y += $h
foreach ($row in $rows) {
    $curX = $x
    for ($i=0; $i -lt 3; $i++) {
        Add-Box $slide $curX $y $w[$i] 52 $row[$i] $lightGray $gray 11 $false | Out-Null
        $curX += $w[$i]
    }
    $y += 52
}
Add-Footer $slide $slideNo

# 3
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "Solution Context: Three Independent Applications" "Phase 1"
Add-Box $slide 55 120 250 150 "Producer Application`rPort 8081`r- Publishes reconciliation transactions`r- Configurable TPS and interval`r- Generates valid and invalid payloads`r- Adds correlationId, traceId, traceparent`r- Backpressure guard limits queue growth" $lightBlue $blue 13 $true | Out-Null
Add-Box $slide 355 120 250 150 "Consumer / Reconciliation Service`rPort 8082`r- Consumes IBM MQ messages`r- Validates and persists records`r- Idempotency and duplicate detection`r- Concurrent listeners`r- Retry, backout and DLQ handling" $lightGreen $teal 13 $true | Out-Null
Add-Box $slide 655 120 250 150 "Dashboard API`rPort 8083`r- Status endpoint`r- Failed transaction view`r- Queue backlog visibility`r- Replay API`r- Liveness and readiness health" $lightOrange $orange 13 $true | Out-Null
Add-Line $slide 305 195 355 195 $gray $true | Out-Null
Add-Line $slide 605 195 655 195 $gray $true | Out-Null
Add-Box $slide 105 340 750 85 "Design intent`rEach runtime has a clear responsibility, independent scaling profile, independent health probes, and separate deployment artifact. This prevents the producer, reconciliation worker and dashboard/API surfaces from becoming a single operational failure domain." $lightGray $gray 14 $false | Out-Null
Add-Footer $slide $slideNo

# 4
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "Repository and Deliverable Structure" "Phase 7"
Add-Box $slide 55 95 390 355 "Source repository layout`rrecon-producer-app/`rrecon-consumer-app/`rrecon-dashboard-api/`rrecon-local-dependencies/`raws-kubernetes/`rarchitecture/`rPHASE2_RESILIENCY_RUNBOOK.md`rPHASE2_MQRC2035_FAILURE_ANALYSIS.md`rPHASE4_ARCHITECTURE_DESIGN.md`rPHASE6_OBSERVABILITY_SRE.md" $lightBlue $blue 15 $true | Out-Null
Add-Box $slide 515 95 390 355 "Deployment artifacts`r- Dockerfiles for each Java service`r- Raw Kubernetes manifests`r- ConfigMaps, HPAs, PDBs and services`r- IBM MQ StatefulSet and MQSC queue setup`r- AWS Secrets Manager scripts`r- RDS SQL initialization scripts`r- GitHub Actions CI/CD workflow`r- Draw.io architecture file" $lightGreen $teal 15 $true | Out-Null
Add-Footer $slide $slideNo

# 5
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "End-to-End Message Flow" "Phase 1"
$a = Add-Box $slide 45 170 145 88 "Producer`rJava 17`rRandom transactions" $lightBlue $blue 13 $true
$b = Add-Box $slide 235 155 150 118 "IBM MQ`rRECON.IN`rPersistent message" $lightOrange $orange 13 $true
$c = Add-Box $slide 430 170 160 88 "Consumer`rConcurrent JMS`rReconcile" $lightGreen $teal 13 $true
$d = Add-Box $slide 650 155 170 118 "PostgreSQL`rreconciliation_record`rStatus + audit" $lightPurple $purple 13 $true
$e = Add-Box $slide 430 330 160 90 "Dashboard API`rStatus / failed`rQueue / replay" $lightGray $gray 13 $true
$f = Add-Box $slide 235 330 150 90 "Retry / Backout`rDLQ paths`rReplay support" $lightRed $red 13 $true
Add-Line $slide 190 214 235 214 $blue $true | Out-Null
Add-Line $slide 385 214 430 214 $teal $true | Out-Null
Add-Line $slide 590 214 650 214 $purple $true | Out-Null
Add-Line $slide 510 330 510 258 $gray $true | Out-Null
Add-Line $slide 430 374 385 374 $red $true | Out-Null
Add-TextBox $slide 52 92 830 40 "The message is the contract boundary: JSON TextMessage plus JMSCorrelationID and W3C tracing headers." 16 $navy $false | Out-Null
Add-Bullets $slide 55 455 830 45 @("Business invalid transactions are persisted as INVALID, not silently dropped", "Retryable technical failures follow retry/backout/DLQ paths", "Dashboard can prove current status and replay recoverable failures") 13 $navy | Out-Null
Add-Footer $slide $slideNo

# 6
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "Functional Architecture" "Architecture"
Add-TextBox $slide 55 96 820 35 "Business view: actors, business capabilities, transaction lifecycle and operational outcomes. No deployment technology decisions here." 14 $gray $false | Out-Null
Add-Box $slide 50 155 160 82 "Business Actors`rOperations analyst`rUpstream systems`rSupport engineer" $lightBlue $blue 11 $true | Out-Null
Add-Box $slide 270 145 150 102 "Capture Transaction`rCreate reconciliation item`rMark valid/invalid input`rAttach audit identity" $panel $blue 11 $true | Out-Null
Add-Box $slide 455 145 150 102 "Reconcile`rValidate business rules`rCompare state`rDecide outcome" $panel $teal 11 $true | Out-Null
Add-Box $slide 640 145 150 102 "Record Outcome`rReconciled`rInvalid`rFailed`rDLQ / backout" $panel $purple 11 $true | Out-Null
Add-Box $slide 825 145 100 102 "Operate`rStatus`rFailed view`rReplay" $panel $orange 11 $true | Out-Null
Add-Line $slide 210 196 270 196 $cyan $true | Out-Null
Add-Line $slide 420 196 455 196 $cyan $true | Out-Null
Add-Line $slide 605 196 640 196 $cyan $true | Out-Null
Add-Line $slide 790 196 825 196 $cyan $true | Out-Null
Add-Box $slide 70 325 230 110 "Business Rules`rPositive amount`rSupported currency`rRequired transaction identity`rDuplicate handling by business key" $lightGreen $teal 11 $true | Out-Null
Add-Box $slide 365 325 230 110 "Exception Outcomes`rRecoverable failure: retry`rPoison message: backout`rUndeliverable: DLQ`rOperator replay after review" $lightRed $red 11 $true | Out-Null
Add-Box $slide 660 325 230 110 "Business KPIs`rTotal processed`rReconciled vs invalid`rFailed transaction count`rQueue backlog / recovery status" $lightOrange $orange 11 $true | Out-Null
Add-Footer $slide $slideNo

# 7
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "Technical Architecture" "Architecture"
Add-TextBox $slide 55 96 835 35 "Application/component view: services, APIs, protocols, data contracts, code modules and engineering patterns." 14 $gray $false | Out-Null
Add-Box $slide 50 150 245 120 "Producer Service`rSpring Boot 3 / Java 17`rScheduler + generator`rJmsTemplate publisher`rTrace header writer`rBackpressure guard" $lightBlue $blue 11 $true | Out-Null
Add-Box $slide 355 150 245 120 "Consumer Service`rJMS listener container`rReconciliationService`rRetry/backout publisher`rJPA Repository`rResilience4j policies" $lightGreen $teal 11 $true | Out-Null
Add-Box $slide 660 150 245 120 "Dashboard API`rREST controllers`rStatus query service`rFailed transaction paging`rQueue-depth service`rReplay command API" $lightOrange $orange 11 $true | Out-Null
Add-Line $slide 295 210 355 210 $cyan $true | Out-Null
Add-Line $slide 600 210 660 210 $cyan $true | Out-Null
Add-Box $slide 65 330 170 92 "Message Contract`rJSON TextMessage`rJMSCorrelationID`rtraceparent`rsimulationMode" $lightCyan $cyan 10 $true | Out-Null
Add-Box $slide 280 330 170 92 "Persistence Model`rreconciliation_record`runique transaction key`rstatus and audit columns`ridempotency check" $lightPurple $purple 10 $true | Out-Null
Add-Box $slide 495 330 170 92 "Resiliency Module`rdeadlock retry`rexponential backoff`rcircuit breaker`rbulkhead isolation" $lightRed $red 10 $true | Out-Null
Add-Box $slide 710 330 170 92 "Observability Module`rstructured logging`rMicrometer metrics`rOpenTelemetry spans`rActuator health" $lightGray $gray 10 $true | Out-Null
Add-Line $slide 172 270 150 330 $cyan $true | Out-Null
Add-Line $slide 478 270 365 330 $purple $true | Out-Null
Add-Line $slide 478 270 580 330 $red $true | Out-Null
Add-Line $slide 782 270 795 330 $gray $true | Out-Null
Add-Footer $slide $slideNo

# 8
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "Infrastructure Architecture" "Architecture"
Add-TextBox $slide 55 96 830 35 "Deployment/topology view: cloud resources, Kubernetes objects, network/security boundaries, storage and CI/CD path." 14 $gray $false | Out-Null
Add-Box $slide 40 150 880 290 "AWS Cloud - ap-southeast-1 / VPC" $panel $cyan 12 $true | Out-Null
Add-Box $slide 80 215 245 155 "Public / Access Layer`rDashboard LoadBalancer`rGrafana LoadBalancer`rJaeger Query LoadBalancer`rGitHub Actions OIDC`rECR image registry" $lightBlue $blue 10 $true | Out-Null
Add-Box $slide 365 195 250 205 "EKS Cluster recon-eks`rNamespace recon-platform:`r- producer deployment + HPA`r- consumer deployment + HPA`r- dashboard deployment`r- IBM MQ StatefulSet + PVC`rNamespace observability:`r- Prometheus, Grafana, Jaeger" $lightGreen $teal 10 $true | Out-Null
Add-Box $slide 655 215 225 155 "Private Data / Control Plane`rRDS PostgreSQL private endpoint`rEBS gp3 volume for MQ`rAWS Secrets Manager`rIAM roles for service accounts`rSecurity groups and network policy" $lightOrange $orange 10 $true | Out-Null
Add-Line $slide 325 292 365 292 $cyan $true | Out-Null
Add-Line $slide 615 292 655 292 $cyan $true | Out-Null
Add-Box $slide 75 435 225 55 "Rolling deployments + probes drive Kubernetes auto-recovery" $lightGray $gray 10 $true | Out-Null
Add-Box $slide 365 435 225 55 "Persistent MQ + RDS backups protect state" $lightPurple $purple 10 $true | Out-Null
Add-Box $slide 655 435 225 55 "IRSA + Secrets Manager avoid credential hardcoding" $lightRed $red 10 $true | Out-Null
Add-Footer $slide $slideNo

# 6
$slideNo++
Add-TwoColumnSlide $pres "Producer Engineering Design" "Phase 1" "Capabilities" @(
    "Configurable TPS using PRODUCER_TPS and PRODUCER_INTERVAL_MS",
    "Random valid and invalid transaction generation",
    "Correlation metadata: correlationId, traceId and traceparent",
    "Backpressure guard reads queue depth before publishing",
    "Structured logging and Micrometer counters"
) "Production controls" @(
    "No secrets in source code or properties",
    "AWS Secrets Manager loaded at startup",
    "MQRC 2035 is logged clearly without exposing credentials",
    "Queue-depth cap prevents uncontrolled message growth",
    "Prometheus metric: recon_producer_messages_total"
) $slideNo

# 7
$slideNo++
Add-TwoColumnSlide $pres "Consumer / Reconciliation Engineering Design" "Phase 1" "Core processing" @(
    "JMS listener consumes RECON.IN and RECON.RETRY",
    "Business validation marks records RECONCILED or INVALID",
    "PostgreSQL persistence with unique transaction/correlation keys",
    "Idempotency prevents duplicate processing side effects",
    "Concurrent processing controlled through configuration"
) "Reliability controls" @(
    "Deadlock retry with exponential backoff",
    "Circuit breaker around database calls",
    "Bulkhead isolation protects worker threads",
    "Poison messages move to RECON.BACKOUT",
    "Prometheus counters for retries, failures and deadlocks"
) $slideNo

# 8
$slideNo++
Add-TwoColumnSlide $pres "Dashboard/API Engineering Design" "Phase 1" "API surface" @(
    "GET /api/reconciliation/status",
    "GET /api/reconciliation/failed",
    "GET /api/reconciliation/queues",
    "POST /api/reconciliation/replay",
    "Actuator liveness and readiness probes"
) "Operational value" @(
    "Shows total, reconciled, invalid, failed and DLQ counts",
    "Exposes queue backlog visibility",
    "Provides controlled replay mechanism",
    "Supports live demo and recovery walkthrough",
    "Feeds Prometheus queue-depth metrics"
) $slideNo

# 9
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "IBM MQ Topology and Recovery Paths" "Phase 2"
Add-Box $slide 65 95 170 80 "RECON.IN`rPrimary input" $lightOrange $orange 14 $true | Out-Null
Add-Box $slide 300 95 170 80 "RECON.RETRY`rRetry queue" $lightOrange $orange 14 $true | Out-Null
Add-Box $slide 535 95 170 80 "RECON.BACKOUT`rPoison/exhausted" $lightRed $red 14 $true | Out-Null
Add-Box $slide 770 95 170 80 "SYSTEM.DLQ`rUndeliverable" $lightRed $red 14 $true | Out-Null
Add-Line $slide 235 135 300 135 $orange $true | Out-Null
Add-Line $slide 470 135 535 135 $red $true | Out-Null
Add-Line $slide 705 135 770 135 $red $true | Out-Null
Add-Box $slide 65 250 250 145 "MQ features demonstrated`r- Retry queues`r- Backout queue`r- Dead-letter queue handling`r- MQRC 2035 diagnosis and correction`r- Poison message handling`r- Message replay through dashboard" $lightGray $gray 13 $true | Out-Null
Add-Box $slide 360 250 250 145 "Recovery behavior`r- Retryable failures are isolated`r- Poison messages stop blocking the main queue`r- DLQ is visible and measurable`r- Replay path is explicit and auditable`r- Correlation metadata is preserved" $lightGreen $teal 13 $true | Out-Null
Add-Box $slide 655 250 250 145 "Operational evidence`r- MQRC 2035 failure runbook`r- OAM authority script`r- Queue depth metrics`r- Logs with correlationId`r- Dashboard status confirms DB results" $lightBlue $blue 13 $true | Out-Null
Add-Footer $slide $slideNo

# 10
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "Failure Simulation and Recovery Matrix" "Phase 2"
$rows = @(
    @("Database deadlock", "Simulated by message mode", "Deadlock retry + exponential backoff", "recon_db_deadlock_retries_total"),
    @("MQ outage", "Stop/scale MQ pod", "JMS reconnect and health visibility", "Pod logs + readiness"),
    @("Consumer crash", "Simulation mode or pod delete", "Kubernetes restart + MQ redelivery", "Pod restart + consumed count"),
    @("Slow database", "Simulated sleep path", "Bulkhead + circuit breaker", "latency p95 + error rate"),
    @("Duplicate message", "Replay same transaction/correlation", "Idempotency lookup + DB uniqueness", "duplicate counter"),
    @("MQRC 2035", "OAM authority missing", "Authorize app principal on QM/queues", "failure analysis document")
)
$x = 30; $y = 86; $w = @(160, 190, 250, 250)
$heads = @("Failure", "Simulation", "Recovery pattern", "Evidence")
for ($i=0; $i -lt 4; $i++) { Add-Box $slide ($x + ($w[0..($i-1)] | Measure-Object -Sum).Sum) $y $w[$i] 38 $heads[$i] $panel $cyan 12 $true $white | Out-Null }
$y += 38
foreach ($r in $rows) {
    $curX = $x
    for ($i=0; $i -lt 4; $i++) {
        Add-Box $slide $curX $y $w[$i] 55 $r[$i] $lightGray $gray 10 $false | Out-Null
        $curX += $w[$i]
    }
    $y += 55
}
Add-Footer $slide $slideNo

# 11
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "AWS and Kubernetes Deployment Architecture" "Phase 3"
Add-Box $slide 45 95 870 360 "AWS ap-southeast-1 / EKS recon-eks" $lightOrange $orange 16 $true | Out-Null
Add-Box $slide 80 160 520 240 "Namespace: recon-platform" $white $gray 14 $true | Out-Null
Add-Box $slide 115 220 135 75 "Producer`rDeployment`rHPA" $lightBlue $blue 12 $true | Out-Null
Add-Box $slide 285 220 135 75 "Consumer`rDeployment`rHPA" $lightGreen $teal 12 $true | Out-Null
Add-Box $slide 455 220 135 75 "Dashboard`rDeployment`rLoadBalancer" $lightGray $gray 12 $true | Out-Null
Add-Box $slide 200 340 150 75 "IBM MQ`rStatefulSet`rgp3 PVC" $lightOrange $orange 12 $true | Out-Null
Add-Box $slide 415 340 150 75 "ConfigMaps`rSecrets via IRSA`rProbes/PDB" $lightPurple $purple 12 $true | Out-Null
Add-Box $slide 660 160 210 110 "RDS PostgreSQL`rPrivate access`rSecurity group permits EKS only" $lightPurple $purple 12 $true | Out-Null
Add-Box $slide 660 315 210 110 "AWS Secrets Manager`rrecon/prod/app`rNo source hardcoding" $lightRed $red 12 $true | Out-Null
Add-Line $slide 250 257 285 257 $gray $true | Out-Null
Add-Line $slide 420 257 455 257 $gray $true | Out-Null
Add-Line $slide 420 257 660 215 $purple $true | Out-Null
Add-Line $slide 520 340 660 370 $red $true | Out-Null
Add-Footer $slide $slideNo

# 12
$slideNo++
Add-TwoColumnSlide $pres "Kubernetes Objects Implemented" "Phase 3" "Raw manifests" @(
    "Deployments for producer, consumer and dashboard",
    "StatefulSet for IBM MQ",
    "Services for app access and MQ internal routing",
    "ConfigMaps for runtime configuration and MQSC setup",
    "Secrets and IRSA for runtime credentials",
    "HPAs, PDBs, liveness and readiness probes"
) "Operational behavior" @(
    "RollingUpdate deployments with controlled availability",
    "Persistent storage through gp3 StorageClass",
    "Auto-recovery when pods crash",
    "Consumer scaling controlled through HPA and concurrency settings",
    "GitHub Actions builds and deploys container images to EKS"
) $slideNo

# 13
$slideNo++
Add-TwoColumnSlide $pres "Security Model" "Phase 4" "Identity and secrets" @(
    "GitHub Actions uses AWS OIDC, not static AWS keys",
    "Applications use IRSA service account role",
    "Credentials stored in AWS Secrets Manager",
    "No confidential values in Java properties or source code",
    "MQ runtime secret synchronized separately"
) "Network and runtime controls" @(
    "RDS deployed private, PostgreSQL allowed only from EKS security group",
    "IBM MQ exposed internally through ClusterIP",
    "Dashboard LoadBalancer used for controlled assessment access",
    "Containers run as non-root and drop capabilities",
    "NetworkPolicies restrict traffic paths"
) $slideNo

# 14
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "CI/CD: GitHub to AWS" "Phase 3"
Add-Box $slide 55 170 160 90 "Developer Push`rmain branch" $lightGray $gray 14 $true | Out-Null
Add-Box $slide 270 155 180 120 "GitHub Actions`rBuild`rUnit tests`rContainerize" $lightBlue $blue 14 $true | Out-Null
Add-Box $slide 505 170 160 90 "Amazon ECR`rVersioned images" $lightOrange $orange 14 $true | Out-Null
Add-Box $slide 720 155 180 120 "Amazon EKS`rkubectl apply`rrollout status" $lightGreen $teal 14 $true | Out-Null
Add-Line $slide 215 215 270 215 $gray $true | Out-Null
Add-Line $slide 450 215 505 215 $gray $true | Out-Null
Add-Line $slide 665 215 720 215 $gray $true | Out-Null
Add-Box $slide 90 345 780 88 "Deploy role pattern`rGitHub assumes an AWS IAM role through OIDC. The workflow builds all three services, pushes images to ECR, applies raw Kubernetes manifests, and waits for rollout completion. Kubernetes access still depends on EKS access entry or aws-auth mapping." $lightGray $gray 14 $false | Out-Null
Add-Footer $slide $slideNo

# 15
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "Observability Stack" "Phase 6"
Add-Box $slide 60 105 230 120 "Structured Logs`rJSON console logs`revent names`rcorrelationId`rtransactionId" $lightOrange $orange 13 $true | Out-Null
Add-Box $slide 365 105 230 120 "Metrics`rActuator Prometheus`rTPS counters`rqueue depth`rretry/deadlock/error rate" $lightCyan $cyan 13 $true | Out-Null
Add-Box $slide 670 105 230 120 "Distributed Tracing`rOpenTelemetry`rW3C traceparent`rJaeger search by traceId" $lightPurple $purple 13 $true | Out-Null
Add-Box $slide 60 310 230 120 "Prometheus Alerts`rApp down`rQueue backlog`rDLQ movement`rDeadlock spikes`rHigh error rate" $lightRed $red 13 $true | Out-Null
Add-Box $slide 365 310 230 120 "Grafana Dashboard`rProducer TPS`rConsumer TPS`rTotal published`rTotal processed`rMQ depth" $lightGreen $teal 13 $true | Out-Null
Add-Box $slide 670 310 230 120 "Failure Analysis`rLogs + metrics + traces`rReplay evidence`rKubernetes pod behavior`rRunbook commands" $lightBlue $blue 13 $true | Out-Null
Add-Footer $slide $slideNo

# 16
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "SRE Dashboard Metrics and Current Evidence" "Phase 6"
Add-Box $slide 55 95 190 105 "Producer TPS`rsum(rate(recon_producer_messages_total[1m]))`rLive throughput" $lightBlue $blue 11 $true | Out-Null
Add-Box $slide 275 95 190 105 "Consumer TPS`rsum(rate(recon_consumer_messages_total[1m]))`rLive processing rate" $lightGreen $teal 11 $true | Out-Null
Add-Box $slide 495 95 190 105 "Total Published`rsum(recon_producer_messages_total)`rCumulative count" $lightOrange $orange 11 $true | Out-Null
Add-Box $slide 715 95 190 105 "Total Processed`rsum(recon_consumer_messages_total)`rCumulative count" $lightPurple $purple 11 $true | Out-Null
Add-Box $slide 80 285 360 115 "Last checked API evidence`r/api/reconciliation/status`rtotal=3084`rreconciled=2768`rinvalid=316`rfailed=0, dlq=0" $lightGray $gray 14 $true | Out-Null
Add-Box $slide 520 285 360 115 "Last checked MQ/log evidence`rpublished_5m=600`rconsumed_5m=248`rdb_insert_logs_5m=248`rRECON.IN CURDEPTH=0" $lightGray $gray 14 $true | Out-Null
Add-Footer $slide $slideNo

# 17
$slideNo++
Add-TwoColumnSlide $pres "Distributed Correlation and Tracing" "Phase 6" "Message metadata" @(
    "JMSCorrelationID carries the application correlationId",
    "traceId and W3C traceparent travel as JMS properties",
    "Producer creates publish span and message headers",
    "Consumer extracts parent context and starts consume span",
    "Retry/backout/replay preserve trace metadata"
) "Troubleshooting value" @(
    "Find a transaction in logs by correlationId",
    "Open Jaeger by traceId to see cross-service path",
    "Connect producer publish, MQ delay, consumer processing and DB outcome",
    "Prove recovery path during replay or retry scenarios",
    "Support banking-style auditability"
) $slideNo

# 18
$slideNo++
Add-TwoColumnSlide $pres "Testing and Code Quality" "Engineering" "Unit and integration focus" @(
    "Producer tests validate generation, scheduling and publish behavior",
    "Consumer tests validate reconciliation, retry, idempotency and failure paths",
    "Dashboard tests validate API status, failed view, replay and queue visibility",
    "Exception handling paths are covered explicitly",
    "Target coverage: 80 percent or higher"
) "Production code practices" @(
    "Java 17 and Spring Boot conventions",
    "No credential hardcoding",
    "Structured exceptions and domain-specific failure types",
    "ObjectMapper configured for Java time serialization",
    "Clean separation of app responsibilities"
) $slideNo

# 19
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "Troubleshooting Case Study: MQRC 2035" "Phase 2"
Add-Box $slide 55 105 250 120 "Symptom`rProducer and consumer started but failed to open MQ queues.`rIBM MQ returned MQRC 2035 authorization failure." $lightRed $red 13 $true | Out-Null
Add-Box $slide 355 105 250 120 "Diagnosis`rLogs showed authorization failure, not network or credential parsing issue.`rQueue manager and queue OAM were inspected." $lightOrange $orange 13 $true | Out-Null
Add-Box $slide 655 105 250 120 "Correction`rApplied OAM authorities for app principal on QM1 and queues using documented script." $lightGreen $teal 13 $true | Out-Null
Add-Box $slide 115 310 730 100 "Why this matters`rThis is the kind of real production issue the assessment is asking for: a cloud deployment worked at the platform layer, but MQ object authorization blocked message flow. The recovery was diagnosed, fixed through MQ authority commands, documented, and validated by end-to-end transaction processing." $lightGray $gray 14 $false | Out-Null
Add-Footer $slide $slideNo

# 20
$slideNo++
Add-TwoColumnSlide $pres "AI-Assisted Engineering Workflow" "Phase 5" "How AI was used" @(
    "Clarified the assessment into phased engineering deliverables",
    "Generated initial scaffolding for Java services and Kubernetes manifests",
    "Produced architecture documentation, Draw.io structure and prompt packs",
    "Assisted troubleshooting of AWS, EKS, MQ, Grafana and serialization issues",
    "Prepared demo scripts and validation commands"
) "Engineering judgement applied" @(
    "Validated generated code with unit tests and live deployments",
    "Corrected secret handling to use AWS Secrets Manager instead of properties",
    "Fixed ObjectMapper Java time serialization in JMS converter",
    "Added queue backpressure to avoid unbounded MQ growth",
    "Separated TPS panels from cumulative total panels in Grafana"
) $slideNo

# 21
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "Prompt Engineering Examples and Corrections" "Phase 5"
Add-Box $slide 45 95 275 300 "Example prompts used`r- Build three independent Java 17 services for producer, consumer and dashboard.`r- Add IBM MQ retry, backout, DLQ and replay patterns.`r- Move confidential runtime config to AWS Secrets Manager.`r- Create Kubernetes manifests for EKS with HPA, probes and persistent MQ storage.`r- Generate architecture diagrams and SRE walkthrough." $lightBlue $blue 12 $true | Out-Null
Add-Box $slide 350 95 275 300 "AI-generated sections`r- Spring Boot project structure`r- JMS configuration`r- Reconciliation service skeleton`r- Kubernetes Deployment/StatefulSet YAML`r- Prometheus/Grafana manifests`r- Runbook and architecture documentation" $lightGreen $teal 12 $true | Out-Null
Add-Box $slide 655 95 275 300 "Manual corrections`r- Removed property-file secrets and used Secrets Manager`r- Added exception handling and production logging`r- Fixed MQ OAM authorization and documented MQRC 2035`r- Added JavaTime ObjectMapper support`r- Added total processed Grafana panels`r- Tuned TPS/backpressure for cloud cost and stability" $lightOrange $orange 12 $true | Out-Null
Add-Footer $slide $slideNo

# 22
$slideNo++
Add-TwoColumnSlide $pres "Architecture Decisions and Trade-Offs" "Phase 4" "Decisions" @(
    "IBM MQ selected for durable enterprise messaging and MQ-specific assessment coverage",
    "PostgreSQL selected for transactional reconciliation state",
    "Three services selected for independent scaling and failure isolation",
    "Raw Kubernetes manifests selected for transparent operational assessment",
    "In-cluster Prometheus/Grafana selected for portable demo evidence"
) "Trade-offs" @(
    "Single MQ StatefulSet is cost-effective for assessment, but production HA should use replicated MQ pattern",
    "Dashboard LoadBalancer is simple for demo, but production should use TLS, SSO and WAF",
    "HPA on CPU is simple, but queue-depth based scaling would be stronger for production",
    "RDS single instance is cost-conscious; production should use Multi-AZ",
    "Raw YAML is explicit; Helm/Terraform improves repeatability at scale"
) $slideNo

# 23
$slideNo++
Add-TwoColumnSlide $pres "HA/DR, Capacity and Cost Strategy" "Phase 4" "Production HA/DR path" @(
    "Run EKS worker nodes across multiple availability zones",
    "Use RDS Multi-AZ and automated backups/PITR",
    "Adopt replicated IBM MQ / native HA queue manager pattern",
    "Version all container images in ECR",
    "Recreate infrastructure from manifests and future Terraform"
) "Capacity and cost management" @(
    "Keep consumer capacity greater than producer TPS",
    "Monitor RECON.IN queue depth slope and p95 DB latency",
    "Tune JMS concurrency, DB pool and RDS instance class",
    "Scale workloads to zero when idle for assessment cost control",
    "Right-size EKS node groups after observing real metrics"
) $slideNo

# 24
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "Deliverables Checklist" "Phase 7"
Add-Box $slide 55 95 390 150 "1. Source code repository`r- Full working code`r- Clean project structure`r- README with setup steps`r- Unit tests and production code patterns" $lightBlue $blue 13 $true | Out-Null
Add-Box $slide 515 95 390 150 "2. Deployment artifacts`r- Dockerfiles`r- Kubernetes YAMLs`r- AWS scripts`r- SQL scripts`r- MQ setup commands`r- GitHub Actions workflow" $lightGreen $teal 13 $true | Out-Null
Add-Box $slide 55 290 390 150 "3. Architecture documentation`r- Draw.io multi-page architecture`r- Mermaid diagrams`r- Design walkthrough`r- Trade-off analysis`r- HA/DR strategy" $lightOrange $orange 13 $true | Out-Null
Add-Box $slide 515 290 390 150 "4. Demonstration evidence`r- Logs and metrics`r- Grafana dashboard`r- Kubernetes pod behavior`r- Failure recovery walkthrough`r- MQRC 2035 case study" $lightPurple $purple 13 $true | Out-Null
Add-Footer $slide $slideNo

# 25
$slideNo++
$slide = $pres.Slides.Add($slideNo, 12)
Add-Header $slide "Recommended Demo Walkthrough" "Close"
Add-Box $slide 55 90 850 360 "1. Show repository structure and explain the three-app boundary.`r`r2. Open Draw.io architecture and walk through executive, MQ, Kubernetes, security and SRE pages.`r`r3. Start or verify EKS workloads, then show pods, deployments and services.`r`r4. Open dashboard API status and Grafana SRE dashboard to show total messages, TPS, queue depth and errors.`r`r5. Demonstrate trace correlation in Jaeger using traceId/correlationId.`r`r6. Walk through Phase 2 recovery: deadlock retry, consumer crash recovery, MQRC 2035 case study, retry/backout/DLQ/replay.`r`r7. Close with trade-offs: production HA, security hardening, queue-depth autoscaling, IaC and cost controls." $lightGray $gray 15 $false | Out-Null
Add-TextBox $slide 75 470 760 30 "Positioning: this is not only a theoretical design; it is a working, deployed, observable reconciliation system with documented failure recovery." 15 $navy $true | Out-Null
Add-Footer $slide $slideNo

# Presentation story order:
# 1 Executive Summary
# 2 Functional Architecture
# 3 Technical Architecture
# 4 Infrastructure Architecture
# The architecture slides are generated after the initial evidence slides so move them up before saving.
$pres.Slides.Item(6).MoveTo(2)
$pres.Slides.Item(7).MoveTo(3)
$pres.Slides.Item(8).MoveTo(4)

if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Force
}

$pres.SaveAs($OutputPath, 24)
$pres.Close()
$ppt.Quit()

[System.Runtime.InteropServices.Marshal]::ReleaseComObject($pres) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($ppt) | Out-Null

Write-Output $OutputPath
