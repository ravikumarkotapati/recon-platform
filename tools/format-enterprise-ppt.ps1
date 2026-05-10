param(
    [string]$Path = "E:\workspace\Enterprise_Reconciliation_Platform.pptx"
)

$ErrorActionPreference = "Stop"

function Rgb($r, $g, $b) {
    return [int]($r + ($g -shl 8) + ($b -shl 16))
}

$navy = Rgb 20 45 78
$blue = Rgb 0 118 210
$cyan = Rgb 0 169 224
$teal = Rgb 0 153 136
$orange = Rgb 238 151 38
$gray = Rgb 86 105 130
$transparent = 1
$lightBg = Rgb 248 251 255
$headerBg = Rgb 236 247 255
$lineColor = Rgb 214 232 246
$white = Rgb 255 255 255

function Send-ToBack($shape) {
    try { $shape.ZOrder(1) | Out-Null } catch { }
}

function Bring-ToFront($shape) {
    try { $shape.ZOrder(0) | Out-Null } catch { }
}

function Set-TextStyle($shape, [bool]$isTitle = $false) {
    try {
        if (-not $shape.HasTextFrame) { return }
        if (-not $shape.TextFrame.HasText) { return }

        $text = $shape.TextFrame.TextRange.Text
        if ([string]::IsNullOrWhiteSpace($text)) { return }

        $neutralText = $text.Replace("NTT Data", "an enterprise architecture review").Replace("NTT", "Enterprise")
        if ($neutralText -ne $text) {
            $shape.TextFrame.TextRange.Text = $neutralText
            $text = $neutralText
        }

        $shape.TextFrame.MarginLeft = 8
        $shape.TextFrame.MarginRight = 8
        $shape.TextFrame.MarginTop = 5
        $shape.TextFrame.MarginBottom = 5
        $shape.TextFrame.WordWrap = -1
        try { $shape.TextFrame.AutoSize = 2 } catch { }
        try { $shape.TextFrame2.AutoSize = 2 } catch { }

        $range = $shape.TextFrame.TextRange
        $range.Font.Name = "Aptos"
        $range.Font.Color.RGB = $gray
        if ($range.Font.Size -lt 9) { $range.Font.Size = 9 }
        if ($range.Font.Size -gt 24 -and -not $isTitle) { $range.Font.Size = 18 }

        if ($text.Length -gt 160 -and -not $isTitle) {
            $range.Font.Size = [Math]::Min($range.Font.Size, 17)
        }
        if ($text.Length -gt 260 -and -not $isTitle) {
            $range.Font.Size = [Math]::Min($range.Font.Size, 14)
        }

        if ($isTitle) {
            $range.Font.Color.RGB = $navy
            $range.Font.Bold = -1
            if ($range.Font.Size -lt 28) { $range.Font.Size = 30 }
            if ($range.Font.Size -gt 42) { $range.Font.Size = 38 }
        }
    } catch { }
}

function Get-ShapeText($shape) {
    try {
        if ($shape.HasTextFrame -and $shape.TextFrame.HasText) {
            return $shape.TextFrame.TextRange.Text.Trim()
        }
    } catch { }
    return ""
}

function Remove-OldFooterAndDecorations($slide) {
    $width = $slide.Parent.PageSetup.SlideWidth
    $height = $slide.Parent.PageSetup.SlideHeight
    for ($i = $slide.Shapes.Count; $i -ge 1; $i--) {
        $shape = $slide.Shapes.Item($i)
        if ($shape.Name -like "codex_template_*") { continue }
        $txt = Get-ShapeText $shape
        try {
            $isOldFooter = ($shape.Top -gt ($height - 48)) -and ($txt -match "Enterprise Reconciliation Platform|Principal Engineer|Architect Assessment|^\d+\s*\d*$")
            $isHeaderRule = ($shape.Top -lt 24 -and $shape.Height -lt 10 -and $shape.Width -gt ($width * 0.65))
            $isLargeEmptyDecoration = ([string]::IsNullOrWhiteSpace($txt) -and (($shape.Width -gt ($width * 0.88) -and $shape.Height -gt 70) -or ($shape.Left -gt ($width * 0.70) -and $shape.Height -gt 180)))
            $isWideStrayLine = ([string]::IsNullOrWhiteSpace($txt) -and $shape.Type -eq 9 -and $shape.Width -gt 250 -and $shape.Top -gt 90 -and $shape.Top -lt 190)
            if ($isOldFooter -or $isHeaderRule -or $isLargeEmptyDecoration -or $isWideStrayLine) {
                $shape.Delete()
            }
        } catch { }
    }
}

function Hide-ImportedTitleBoxes($slide) {
    foreach ($shape in $slide.Shapes) {
        if ($shape.Name -like "codex_template_*") { continue }
        try {
            $txt = Get-ShapeText $shape
            $isEmptyBox = [string]::IsNullOrWhiteSpace($txt)
            $nearHeader = $shape.Top -lt 190 -and $shape.Width -gt 580 -and $shape.Height -lt 110
            $nearFooter = $shape.Top -gt 430 -and $shape.Width -gt 700 -and $shape.Height -lt 105
            if ($nearHeader -or ($nearFooter -and $isEmptyBox)) {
                $shape.Line.Visible = 0
                $shape.Fill.Transparency = 1
                $shape.Shadow.Visible = 0
            }
        } catch { }
    }
}

function Reflow-SlideContent($slide) {
    $minTop = 158
    $height = $slide.Parent.PageSetup.SlideHeight
    $hasNotePanel = $false

    foreach ($candidate in $slide.Shapes) {
        if ($candidate.Name -like "codex_template_*") { continue }
        $candidateText = Get-ShapeText $candidate
        try {
            if ($candidateText.Length -gt 80 -and $candidate.Top -gt 330) {
                $hasNotePanel = $true
            }
        } catch { }
    }

    foreach ($shape in $slide.Shapes) {
        if ($shape.Name -like "codex_template_*") { continue }
        $txt = Get-ShapeText $shape
        try {
            $isTitle = ($shape.Top -lt 130 -and $txt.Length -gt 0 -and $txt.Length -lt 110)
            $isSubtitle = ($shape.Top -lt 210 -and $shape.Top -gt 80 -and $txt.Length -gt 35 -and $shape.Type -eq 17)
            $isFooter = ($shape.Top -gt ($height - 42))
            if ($isTitle -or $isSubtitle -or $isFooter) { continue }

            if ($shape.Type -eq 13) {
                $shape.Top = 158
                $shape.Left = 48
                try { $shape.LockAspectRatio = -1 } catch { }
                if ($hasNotePanel) {
                    $shape.Height = 245
                } else {
                    $shape.Height = 360
                }
                continue
            }

            if ($txt.Length -gt 80 -and $shape.Top -gt 330) {
                $shape.Top = 420
                $shape.Height = 72
                $shape.Left = 60
                $shape.Width = 875
                continue
            }

            if ($shape.Top -lt $minTop) {
                $shape.Top = $minTop
            }
        } catch { }
    }
}
function Remove-LegacyHeaderArtifacts($slide) {
    for ($i = $slide.Shapes.Count; $i -ge 1; $i--) {
        $shape = $slide.Shapes.Item($i)
        if ($shape.Name -like "codex_template_*") { continue }
        $txt = Get-ShapeText $shape
        try {
            $isPhaseOrYear = ($shape.Top -lt 70 -and ($txt -match "^PHASE\s+\d+|^20\d\d$"))
            $isWideOldDivider = ([string]::IsNullOrWhiteSpace($txt) -and $shape.Type -eq 9 -and $shape.Width -gt 220 -and $shape.Top -gt 135 -and $shape.Top -lt 175)
            $isEmptyLowerBox = ([string]::IsNullOrWhiteSpace($txt) -and $shape.Top -gt 430 -and $shape.Width -gt 250 -and $shape.Height -lt 70)
            if ($isPhaseOrYear -or $isWideOldDivider -or $isEmptyLowerBox) {
                $shape.Delete()
            }
        } catch { }
    }
}
function Format-ShapeTree($shape) {
    try {
        if ($shape.Type -eq 6) {
            for ($i = 1; $i -le $shape.GroupItems.Count; $i++) {
                Format-ShapeTree $shape.GroupItems.Item($i)
            }
            return
        }

        $isLikelyTitle = $false
        try {
            if ($shape.HasTextFrame -and $shape.TextFrame.HasText) {
                $txt = $shape.TextFrame.TextRange.Text.Trim()
                $top = $shape.Top
                $fontSize = $shape.TextFrame.TextRange.Font.Size
                if ($top -lt 150 -and $txt.Length -le 90 -and $fontSize -ge 22) {
                    $isLikelyTitle = $true
                }
            }
        } catch { }

        Set-TextStyle $shape $isLikelyTitle

        try {
            if ($shape.HasTextFrame -and $shape.TextFrame.HasText) {
                # Remove Gamma/imported textbox borders so the common template feels clean.
                if ($shape.Type -eq 17 -or $shape.Line.Visible) {
                    $shape.Line.Visible = 0
                }
                if (($shape.Width -gt 600 -and $shape.Height -lt 125) -or $shape.Top -lt 135) {
                    $shape.Line.Visible = 0
                    $shape.Shadow.Visible = 0
                }
                if ($shape.Type -eq 17) {
                    $shape.Shadow.Visible = 0
                }
            }
        } catch { }

        try {
            # Gamma/AI-generated decks often create large transparent rectangle
            # placeholders behind titles and subtitles. They look like random
            # template boxes after applying a common theme, so hide their borders.
            if ($shape.Width -gt 650 -and $shape.Top -lt 190 -and $shape.Height -lt 120) {
                $shape.Line.Visible = 0
                $shape.Fill.Transparency = $transparent
                $shape.Shadow.Visible = 0
            }
            if ($shape.Width -gt 700 -and $shape.Height -lt 95 -and $shape.Top -gt 430) {
                $shape.Line.Visible = 0
                $shape.Fill.Transparency = 1
                $shape.Shadow.Visible = 0
            }
            if ($shape.Width -gt 760 -and $shape.Height -lt 90 -and $shape.Top -gt 450) {
                $shape.Line.Visible = 0
                $shape.Fill.Transparency = 1
                $shape.Shadow.Visible = 0
            }
        } catch { }

        try {
            if ($shape.Width -gt 600 -and $shape.Top -lt 155 -and $shape.Height -lt 140) {
                $shape.Line.Visible = 0
                $shape.Shadow.Visible = 0
            }
            if ($shape.AutoShapeType -gt 0 -and $shape.Width -lt 900 -and $shape.Height -lt 480) {
                $shape.Line.Weight = 1.25
                if ($shape.Line.Visible) {
                    $shape.Line.ForeColor.RGB = $lineColor
                }
                $shape.Shadow.Visible = -1
                $shape.Shadow.ForeColor.RGB = Rgb 185 204 224
                $shape.Shadow.Transparency = 0.78
                $shape.Shadow.Blur = 5
                $shape.Shadow.OffsetX = 1
                $shape.Shadow.OffsetY = 2
            }
        } catch { }
    } catch { }
}

function Normalize-SlideTitle($slide, [int]$slideNumber) {
    try {
        $titleShape = $null
        $subtitleShape = $null

        foreach ($shape in $slide.Shapes) {
            if ($shape.Name -like "codex_template_*") { continue }
            if (-not $shape.HasTextFrame -or -not $shape.TextFrame.HasText) { continue }
            $txt = $shape.TextFrame.TextRange.Text.Trim()
            if ([string]::IsNullOrWhiteSpace($txt)) { continue }

            $fontSize = 0
            try { $fontSize = $shape.TextFrame.TextRange.Font.Size } catch { }

            if ($null -eq $titleShape -and $shape.Top -lt 180 -and $fontSize -ge 22 -and $txt.Length -le 100 -and $shape.Width -gt 300 -and $txt -notmatch "Enterprise Reconciliation Platform|Principal Engineer|Architect Assessment") {
                $titleShape = $shape
                continue
            }

            if ($null -eq $subtitleShape -and $shape.Type -eq 17 -and $shape.Width -gt 500 -and $shape.Top -lt 230 -and $shape.Top -gt 80 -and $txt.Length -gt 40 -and $txt -notmatch "Enterprise Reconciliation Platform|Principal Engineer|Architect Assessment") {
                $subtitleShape = $shape
            }
        }

        if ($titleShape -ne $null) {
            $titleShape.Left = 64
            $titleShape.Top = 70
            $titleShape.Width = 820
            $titleShape.Height = 42
            $titleShape.Line.Visible = 0
            $titleShape.Fill.Transparency = 1
            $titleShape.Shadow.Visible = 0
            $titleShape.TextFrame.MarginLeft = 0
            $titleShape.TextFrame.MarginRight = 0
            $titleShape.TextFrame.MarginTop = 0
            $titleShape.TextFrame.MarginBottom = 0
            $titleShape.TextFrame.WordWrap = -1
            try { $titleShape.TextFrame.AutoSize = 0 } catch { }
            $titleShape.TextFrame.TextRange.Font.Name = "Aptos Display"
            $titleShape.TextFrame.TextRange.Font.Size = 28
            $titleShape.TextFrame.TextRange.Font.Bold = -1
            $titleShape.TextFrame.TextRange.Font.Color.RGB = $navy

            $underline = $slide.Shapes.AddLine(64, 122, 430, 122)
            $underline.Name = "codex_template_title_rule"
            $underline.Line.ForeColor.RGB = $cyan
            $underline.Line.Weight = 2.2
        }

        if ($subtitleShape -ne $null) {
            $subtitleShape.Left = 64
            $subtitleShape.Top = 126
            $subtitleShape.Width = 850
            $subtitleShape.Height = 34
            $subtitleShape.Line.Visible = 0
            $subtitleShape.Fill.Transparency = 1
            $subtitleShape.Shadow.Visible = 0
            $subtitleShape.TextFrame.MarginLeft = 0
            $subtitleShape.TextFrame.MarginRight = 0
            $subtitleShape.TextFrame.MarginTop = 0
            $subtitleShape.TextFrame.MarginBottom = 0
            $subtitleShape.TextFrame.WordWrap = -1
            try { $subtitleShape.TextFrame.AutoSize = 0 } catch { }
            $subtitleShape.TextFrame.TextRange.Font.Name = "Aptos"
            $subtitleShape.TextFrame.TextRange.Font.Size = 14
            $subtitleShape.TextFrame.TextRange.Font.Bold = 0
            $subtitleShape.TextFrame.TextRange.Font.Color.RGB = $gray
        }
    } catch { }
}

function Format-CoverSlide($slide) {
    try {
        for ($i = $slide.Shapes.Count; $i -ge 1; $i--) {
            $shape = $slide.Shapes.Item($i)
            if ($shape.Name -notlike "codex_template_*") {
                try { $shape.Delete() } catch { }
            }
        }

        $label = $slide.Shapes.AddTextbox(1, 70, 92, 360, 28)
        $label.TextFrame.TextRange.Text = "TECHNICAL ASSESSMENT"
        $label.TextFrame.TextRange.Font.Name = "Aptos"
        $label.TextFrame.TextRange.Font.Size = 15
        $label.TextFrame.TextRange.Font.Bold = -1
        $label.TextFrame.TextRange.Font.Color.RGB = $cyan
        $label.Line.Visible = 0

        $line = $slide.Shapes.AddLine(70, 128, 330, 128)
        $line.Line.ForeColor.RGB = $cyan
        $line.Line.Weight = 2

        $title = $slide.Shapes.AddTextbox(1, 70, 175, 710, 115)
        $title.TextFrame.TextRange.Text = "Enterprise-Grade`rReconciliation Platform"
        $title.TextFrame.TextRange.Font.Name = "Aptos"
        $title.TextFrame.TextRange.Font.Size = 39
        $title.TextFrame.TextRange.Font.Bold = -1
        $title.TextFrame.TextRange.Font.Color.RGB = $navy
        $title.Line.Visible = 0

        $subtitle = $slide.Shapes.AddTextbox(1, 74, 320, 760, 80)
        $subtitle.TextFrame.TextRange.Text = "Principal Engineer / Architect assessment demonstrating production Java engineering, IBM MQ messaging, Kubernetes deployment, resiliency patterns and observability."
        $subtitle.TextFrame.TextRange.Font.Name = "Aptos"
        $subtitle.TextFrame.TextRange.Font.Size = 18
        $subtitle.TextFrame.TextRange.Font.Color.RGB = $gray
        $subtitle.Line.Visible = 0

        $cards = @(
            @{x=70;  y=432; text="Java 17 + IBM MQ`rMessage processing"},
            @{x=365; y=432; text="AWS EKS + PostgreSQL`rCloud deployment"},
            @{x=660; y=432; text="Prometheus + Jaeger`rOperational evidence"}
        )
        foreach ($card in $cards) {
            $box = $slide.Shapes.AddShape(5, $card.x, $card.y, 230, 58)
            $box.Fill.ForeColor.RGB = $white
            $box.Line.ForeColor.RGB = $cyan
            $box.Line.Weight = 1.5
            $box.TextFrame.TextRange.Text = $card.text
            $box.TextFrame.TextRange.Font.Name = "Aptos"
            $box.TextFrame.TextRange.Font.Size = 12
            $box.TextFrame.TextRange.Font.Bold = -1
            $box.TextFrame.TextRange.Font.Color.RGB = $navy
            $box.TextFrame.MarginLeft = 8
            $box.TextFrame.MarginRight = 8
            $box.TextFrame.MarginTop = 5
            $box.TextFrame.MarginBottom = 5
            $box.Shadow.Visible = -1
            $box.Shadow.ForeColor.RGB = Rgb 185 204 224
            $box.Shadow.Transparency = 0.78
            $box.Shadow.Blur = 5
        }
    } catch { }
}

function Add-Template($slide, [int]$slideNumber) {
    $width = 960
    $height = 540
    try {
        $width = $slide.Parent.PageSetup.SlideWidth
        $height = $slide.Parent.PageSetup.SlideHeight
    } catch { }

    $bg = $slide.Shapes.AddShape(1, 0, 0, $width, $height)
    $bg.Name = "codex_template_background"
    $bg.Fill.ForeColor.RGB = $lightBg
    $bg.Line.Visible = 0
    Send-ToBack $bg

    $band = $slide.Shapes.AddShape(1, 0, 0, $width, 64)
    $band.Name = "codex_template_header_band"
    $band.Fill.ForeColor.RGB = $headerBg
    $band.Fill.Transparency = 0.05
    $band.Line.Visible = 0
    Send-ToBack $band

    $right = $slide.Shapes.AddShape(1, ($width * 0.78), 0, ($width * 0.22), $height)
    $right.Name = "codex_template_right_wash"
    $right.Fill.ForeColor.RGB = Rgb 231 246 255
    $right.Fill.Transparency = 0.08
    $right.Line.Visible = 0
    Send-ToBack $right

    $accent = $slide.Shapes.AddShape(1, 0, 0, $width, 7)
    $accent.Name = "codex_template_top_accent"
    $accent.Fill.ForeColor.RGB = $cyan
    $accent.Line.Visible = 0
    Bring-ToFront $accent

    $thin = $slide.Shapes.AddLine(0, 64, $width, 64)
    $thin.Name = "codex_template_header_line"
    $thin.Line.ForeColor.RGB = $lineColor
    $thin.Line.Weight = 1

    $footer = $slide.Shapes.AddTextbox(1, 28, $height - 24, $width - 120, 16)
    $footer.Name = "codex_template_footer"
    $footer.TextFrame.TextRange.Text = "Enterprise Reconciliation Platform | Principal Engineer / Architect Assessment"
    $footer.TextFrame.TextRange.Font.Name = "Aptos"
    $footer.TextFrame.TextRange.Font.Size = 8
    $footer.TextFrame.TextRange.Font.Color.RGB = $gray
    $footer.Line.Visible = 0

    $num = $slide.Shapes.AddTextbox(1, $width - 50, $height - 24, 28, 16)
    $num.Name = "codex_template_slide_number"
    $num.TextFrame.TextRange.Text = "$slideNumber"
    $num.TextFrame.TextRange.Font.Name = "Aptos"
    $num.TextFrame.TextRange.Font.Size = 8
    $num.TextFrame.TextRange.Font.Color.RGB = $gray
    $num.Line.Visible = 0
}

$ppt = New-Object -ComObject PowerPoint.Application
$ppt.Visible = -1
$pres = $ppt.Presentations.Open($Path, $false, $false, $false)

for ($s = 1; $s -le $pres.Slides.Count; $s++) {
    $slide = $pres.Slides.Item($s)

    # Remove previous formatter artifacts if rerun.
    for ($i = $slide.Shapes.Count; $i -ge 1; $i--) {
        $shape = $slide.Shapes.Item($i)
        if ($shape.Name -like "codex_template_*") {
            try { $shape.Delete() } catch { }
        }
    }

    Remove-OldFooterAndDecorations $slide
    Add-Template $slide $s

    for ($i = 1; $i -le $slide.Shapes.Count; $i++) {
        $shape = $slide.Shapes.Item($i)
        if ($shape.Name -notlike "codex_template_*") {
            Format-ShapeTree $shape
        }
    }

    if ($s -eq 1) {
        Format-CoverSlide $slide
    } else {
        Normalize-SlideTitle $slide $s
        Hide-ImportedTitleBoxes $slide
        Reflow-SlideContent $slide
        Remove-LegacyHeaderArtifacts $slide
    }
}

$pres.Save()
$pres.Close()
$ppt.Quit()

[System.Runtime.InteropServices.Marshal]::ReleaseComObject($pres) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($ppt) | Out-Null

Write-Output "Formatted: $Path"






