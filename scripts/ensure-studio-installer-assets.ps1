# Ensure optional Inno Setup branding assets exist (creates placeholders when missing).
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$assets = Join-Path (Split-Path $PSScriptRoot -Parent) "installer\assets"
New-Item -ItemType Directory -Force -Path $assets | Out-Null

$readme = Join-Path $assets "README.txt"
if (-not (Test-Path $readme) -or $Force) {
    @"
Optional branding files for Li World Studio installer:
  app.ico          - 256x256 application icon
  wizard.bmp       - 164x314 sidebar (Inno standard)
  wizard-small.bmp - 55x55 top-right

Colors: docs/design/studio-design-tokens.toml (bg #0d1117, accent #3dd6ff)
"@ | Set-Content -Path $readme -Encoding UTF8
}

foreach ($name in @("app.ico", "wizard.bmp", "wizard-small.bmp")) {
    $path = Join-Path $assets $name
    if (-not (Test-Path $path)) {
        Write-Host "WARN: missing installer asset $name (Inno may fail if referenced)" -ForegroundColor Yellow
    }
}

Write-Host "Installer assets dir: $assets"
