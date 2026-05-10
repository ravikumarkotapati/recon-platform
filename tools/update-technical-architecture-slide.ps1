param(
  [string]$Path = 'E:\workspace\Enterprise_Reconciliation_Platform.pptx',
  [int]$SlideNumber = 4
)

$ErrorActionPreference = 'Stop'

function Rgb($r,$g,$b){ [int]($r + ($g -shl 8) + ($b -shl 16)) }

$navy = Rgb 20 45 78
$blue = Rgb 26 99 181
$cyan = Rgb 0 169 224
$teal = Rgb 0 142 127
$green = Rgb 31 127 84
$purple = Rgb 101 80 181
$orange = Rgb 210 120 24
$red = Rgb 204 57 57
$gray = Rgb 82 101 126
$lightBlue = Rgb 234 247 255
$lightTeal = Rgb 230 250 246
$lightPurple = Rgb 242 239 255
$lightOrange = Rgb 255 244 228
$lightRed = Rgb 255 238 238
$white = Rgb 255 255 255
$line = Rgb 199 222 240

function SetText($shape, $text, $size, $color, [bool]$bold=$false, $font='Aptos') {
  $shape.TextFrame.TextRange.Text = $text
  $shape.TextFrame.TextRange.Font.Name = $font
  $shape.TextFrame.TextRange.Font.Size = $size
  $shape.TextFrame.TextRange.Font.Color.RGB = $color
  $shape.TextFrame.TextRange.Font.Bold = $(if($bold){-1}else{0})
  $shape.TextFrame.MarginLeft = 7
  $shape.TextFrame.MarginRight = 7
  $shape.TextFrame.MarginTop = 5
  $shape.TextFrame.MarginBottom = 5
  $shape.TextFrame.WordWrap = -1
}

function AddBox($slide, $x,$y,$w,$h,$text,$fill,$border,$size=10,[bool]$bold=$false) {
  $s = $slide.Shapes.AddShape(5,$x,$y,$w,$h)
  $s.Fill.ForeColor.RGB = $fill
  $s.Line.ForeColor.RGB = $border
  $s.Line.Weight = 1.2
  SetText $s $text $size $navy $bold
  $s.TextFrame.VerticalAnchor = 3
  $s.Shadow.Visible = -1
  $s.Shadow.ForeColor.RGB = Rgb 170 195 218
  $s.Shadow.Transparency = 0.82
  $s.Shadow.Blur = 4
  $s.Shadow.OffsetX = 1
  $s.Shadow.OffsetY = 2
  return $s
}

function AddHeader($slide, $x,$y,$w,$text,$color) {
  $s = $slide.Shapes.AddTextbox(1,$x,$y,$w,18)
  SetText $s $text 8.5 $color $true
  $s.Line.Visible = 0
  $s.Fill.Visible = 0
  return $s
}

function AddSmallText($slide, $x,$y,$w,$h,$text,$size=8.5,$color=$gray,[bool]$bold=$false) {
  $s = $slide.Shapes.AddTextbox(1,$x,$y,$w,$h)
  SetText $s $text $size $color $bold
  $s.Line.Visible = 0
  $s.Fill.Visible = 0
  return $s
}

function AddArrow($slide, $x1,$y1,$x2,$y2,$color,$label='') {
  $l = $slide.Shapes.AddLine($x1,$y1,$x2,$y2)
  $l.Line.ForeColor.RGB = $color
  $l.Line.Weight = 1.8
  $l.Line.EndArrowheadStyle = 3
  if($label -ne ''){
    $lx = [Math]::Min($x1,$x2) + ([Math]::Abs($x2-$x1)/2) - 38
    $ly = [Math]::Min($y1,$y2) - 15
    if([Math]::Abs($y2-$y1) -gt [Math]::Abs($x2-$x1)){ $lx = $x1 + 6; $ly = [Math]::Min($y1,$y2)+([Math]::Abs($y2-$y1)/2)-8 }
    AddSmallText $slide $lx $ly 76 17 $label 7.2 $gray $true | Out-Null
  }
  return $l
}

function AddDashedArrow($slide, $x1,$y1,$x2,$y2,$color,$label='') {
  $l = AddArrow $slide $x1 $y1 $x2 $y2 $color $label
  $l.Line.DashStyle = 4
  return $l
}

function AddQueueCard($slide, $x,$y,$w,$h,$name,$desc,$fill,$border) {
  $q = $slide.Shapes.AddShape(5,$x,$y,$w,$h)
  $q.Fill.ForeColor.RGB = $fill
  $q.Line.ForeColor.RGB = $border
  $q.Line.Weight = 1
  SetText $q "$name`r$desc" 7.6 $navy $false
  $q.TextFrame.TextRange.Paragraphs(1).Font.Bold = -1
  return $q
}

$ppt = New-Object -ComObject PowerPoint.Application
$ppt.Visible = -1
$pres = $ppt.Presentations.Open($Path, $false, $false, $false)
$slide = $pres.Slides.Item($SlideNumber)

# Remove old technical architecture content but keep the common template/title/footer.
for($i=$slide.Shapes.Count; $i -ge 1; $i--){
  $shape = $slide.Shapes.Item($i)
  if($shape.Name -like 'codex_template_*'){ continue }
  $txt = ''
  try { if($shape.HasTextFrame -and $shape.TextFrame.HasText){ $txt = $shape.TextFrame.TextRange.Text.Trim() } } catch { }
  $keepTitle = ($shape.Top -lt 130 -and $txt -match 'Technical Architecture')
  if(-not $keepTitle){ try { $shape.Delete() } catch { } }
}

# Normalize title in case it was left from previous formatting.
foreach($shape in $slide.Shapes){
  $txt=''
  try { if($shape.HasTextFrame -and $shape.TextFrame.HasText){ $txt=$shape.TextFrame.TextRange.Text.Trim() } } catch {}
  if($txt -match 'Technical Architecture'){
    $shape.Left=64; $shape.Top=70; $shape.Width=820; $shape.Height=42
    $shape.Line.Visible=0; $shape.Fill.Transparency=1; $shape.Shadow.Visible=0
    SetText $shape 'High Level Technical Architecture' 28 $navy $true 'Aptos Display'
  }
}

# Main canvas.
$canvas = $slide.Shapes.AddShape(1, 48, 150, 864, 286)
$canvas.Fill.ForeColor.RGB = $white
$canvas.Fill.Transparency = 0.06
$canvas.Line.ForeColor.RGB = $line
$canvas.Line.Weight = 1
$canvas.Shadow.Visible = -1
$canvas.Shadow.ForeColor.RGB = Rgb 180 203 225
$canvas.Shadow.Transparency = 0.85
$canvas.Shadow.Blur = 5
$canvas.ZOrder(1) | Out-Null

AddHeader $slide 68 162 200 '1. PRODUCER APPLICATION' $blue | Out-Null
$producer = AddBox $slide 60 184 150 118 "Java 17 / Spring Boot`rTPS scheduler`rValid + invalid generator`rJMS publisher" $lightBlue $blue 8.7 $false

AddHeader $slide 262 162 170 '2. IBM MQ TOPOLOGY' $purple | Out-Null
$mq = AddBox $slide 245 184 190 158 "IBM MQ Queue Manager: QM1" $lightPurple $purple 9.0 $true
AddQueueCard $slide 260 214 160 26 'RECON.IN' 'primary persistent queue' $white $purple | Out-Null
AddQueueCard $slide 260 246 160 26 'RECON.RETRY' 'delayed retry path' $white $purple | Out-Null
AddQueueCard $slide 260 278 160 26 'RECON.BACKOUT' 'poison / max retry' $lightRed $red | Out-Null
AddQueueCard $slide 260 310 160 26 'SYSTEM.DLQ' 'undeliverable messages' $lightOrange $orange | Out-Null

AddHeader $slide 490 162 220 '3. CONSUMER / RECONCILIATION' $green | Out-Null
$consumer = AddBox $slide 470 184 180 138 "Java 17 / Spring Boot`rJMS listener pool`rValidation + matching`rIdempotency check`rDB transaction boundary" $lightTeal $green 8.5 $false
$reliability = AddBox $slide 470 334 180 48 "Resilience4j`rRetry, circuit breaker, bulkhead" $white $green 7.8 $false

AddHeader $slide 718 162 150 '4. POSTGRESQL SYSTEM OF RECORD' $orange | Out-Null
$db = $slide.Shapes.AddShape(13, 710, 190, 150, 92)
$db.Fill.ForeColor.RGB = $lightOrange
$db.Line.ForeColor.RGB = $orange
$db.Line.Weight = 1.2
SetText $db "Amazon RDS`rPostgreSQL" 10 $navy $true
$db.Shadow.Visible=-1; $db.Shadow.Transparency=0.84; $db.Shadow.Blur=4
AddSmallText $slide 698 292 178 56 "Tables: reconciliation_record, recon_audit_event, processed_message, failed_transaction" 7.6 $gray $false | Out-Null

$api = AddBox $slide 700 360 170 50 "Dashboard / API`rStatus, failures, replay, backlog" (Rgb 246 251 255) $cyan 8.2 $false

# Core flow arrows.
AddArrow $slide 210 243 245 243 $blue 'JMS put' | Out-Null
AddArrow $slide 435 243 470 243 $purple 'JMS listen' | Out-Null
AddArrow $slide 650 243 710 243 $green 'JDBC tx' | Out-Null
AddArrow $slide 785 360 785 282 $orange 'read/write' | Out-Null

# Retry and failure flows.
AddDashedArrow $slide 560 322 420 292 $red 'backout' | Out-Null
AddDashedArrow $slide 560 322 420 260 $purple 'retry' | Out-Null
AddDashedArrow $slide 560 322 420 324 $orange 'DLQ' | Out-Null
AddDashedArrow $slide 700 385 435 326 $cyan 'replay / depth' | Out-Null

# Trace/correlation lane.
$trace = $slide.Shapes.AddShape(1, 66, 404, 612, 20)
$trace.Fill.ForeColor.RGB = Rgb 239 249 253
$trace.Line.ForeColor.RGB = $cyan
$trace.Line.DashStyle = 4
$trace.Line.Weight = 1
SetText $trace 'Correlation contract: JMSCorrelationID + traceparent carried producer -> MQ -> consumer -> PostgreSQL audit' 7.6 $gray $false

# Observability strip.
$obs = $slide.Shapes.AddShape(5, 694, 404, 188, 24)
$obs.Fill.ForeColor.RGB = Rgb 245 248 252
$obs.Line.ForeColor.RGB = $line
SetText $obs 'OpenTelemetry | Prometheus | Logs' 7.5 $gray $true
AddDashedArrow $slide 135 385 135 404 $cyan '' | Out-Null
AddDashedArrow $slide 560 385 560 404 $cyan '' | Out-Null
AddDashedArrow $slide 770 350 770 404 $cyan '' | Out-Null

# Updated note panel.
$note = $slide.Shapes.AddShape(1, 60, 454, 875, 44)
$note.Fill.ForeColor.RGB = Rgb 250 253 255
$note.Fill.Transparency = 0.08
$note.Line.ForeColor.RGB = $line
$note.Line.Weight = 1
SetText $note "- Producer and consumer are decoupled through IBM MQ; PostgreSQL is the durable reconciliation system of record.`r- Retry, backout, DLQ and replay are explicit paths, not hidden exception handling.`r- Correlation ID and W3C trace context allow end-to-end troubleshooting across JMS, JDBC and REST." 8.5 $gray $false

$pres.Save()
$pres.Close()
$ppt.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($pres) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($ppt) | Out-Null
Write-Output "Updated technical architecture slide in $Path"
