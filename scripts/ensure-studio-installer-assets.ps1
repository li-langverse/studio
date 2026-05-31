# Generate Inno Setup branding assets (dark studio theme) when missing.
param([switch]$Force)

$ErrorActionPreference = "Stop"
$Assets = Join-Path (Split-Path $PSScriptRoot -Parent) "installer\assets"
$null = New-Item -ItemType Directory -Force -Path $Assets

$ico = Join-Path $Assets "app.ico"
$wiz = Join-Path $Assets "wizard.bmp"
$wizSm = Join-Path $Assets "wizard-small.bmp"
$readme = Join-Path $Assets "README.txt"

if (-not (Test-Path $readme) -or $Force) {
    @"
Optional branding files for Li World Studio installer:
  app.ico          - 256x256 application icon
  wizard.bmp       - 164x314 sidebar (Inno standard)
  wizard-small.bmp - 55x55 top-right

Colors: docs/design/studio-design-tokens.toml (bg #0d1117, accent #3dd6ff)
"@ | Set-Content -Path $readme -Encoding UTF8
}

if (-not $Force -and (Test-Path $ico) -and (Test-Path $wiz) -and (Test-Path $wizSm)) {
    Write-Host "Installer assets: $Assets" -ForegroundColor Green
    return
}

Add-Type -AssemblyName System.Drawing

function New-StudioBitmap([int]$W, [int]$H) {
    $bmp = New-Object System.Drawing.Bitmap $W, $H
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $bg = [System.Drawing.Color]::FromArgb(255, 13, 17, 23)
    $accent = [System.Drawing.Color]::FromArgb(255, 61, 214, 255)
    $g.Clear($bg)
    $brush = New-Object System.Drawing.SolidBrush $accent
    $g.FillRectangle($brush, 12, [int]($H * 0.12), [int]($W * 0.55), 28)
    $fontSize = [Math]::Max(9, [int]($H / 22))
    $font = New-Object System.Drawing.Font("Segoe UI", [single]$fontSize, [System.Drawing.FontStyle]::Bold)
    $g.DrawString("Li World Studio", $font, $brush, 12, [int]($H * 0.22))
    $g.Dispose()
    $brush.Dispose()
    $font.Dispose()
    return $bmp
}

function Save-Bmp24([System.Drawing.Bitmap]$Bmp, [string]$Path) {
    $Bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Bmp)
}

$master = New-StudioBitmap 64 64
try {
    $hIcon = $master.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($hIcon)
    $fs = [System.IO.File]::Create($ico)
    $icon.Save($fs)
    $fs.Close()
    $icon.Dispose()
}
finally {
    $master.Dispose()
}

$w = New-StudioBitmap 164 314
$ws = New-StudioBitmap 55 55
try {
    Save-Bmp24 $w $wiz
    Save-Bmp24 $ws $wizSm
}
finally {
    $w.Dispose()
    $ws.Dispose()
}

Write-Host "Installer assets: $Assets" -ForegroundColor Green
