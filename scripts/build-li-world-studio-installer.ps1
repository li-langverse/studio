# Build Li World Studio Windows installer (Inno Setup).
param(
    [switch]$SkipDemoBuild,
    [switch]$SkipPresentHost
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_studio-paths.ps1"

$StudioRoot = Get-StudioRoot
$LicRoot = Get-LicRoot
$lic = Resolve-LicBinary

if (-not $lic) {
    Write-Host "Building lic via WSL..." -ForegroundColor Yellow
    $bash = "C:\Program Files\Git\bin\bash.exe"
    if (-not (Test-Path $bash)) { throw "Git Bash required to build lic" }
    & $bash -lc "cd '$($LicRoot -replace '\\','/')' && bash scripts/wsl-setup-build.sh"
    $lic = Resolve-LicBinary
}
if (-not $lic) { throw "lic binary not found under $LicRoot" }

if (-not $SkipDemoBuild) {
    Write-Host "Building li-studio-demo..."
    $main = Join-Path $StudioRoot "src\main.li"
    $out = Join-Path $StudioRoot "build\li-studio-demo"
    New-Item -ItemType Directory -Force -Path (Split-Path $out) | Out-Null
    & $lic build --allow-open-vc --no-lean-verify $main -o $out
}

if (-not $SkipPresentHost) {
    & "$PSScriptRoot\build-studio-shell-present-host.ps1"
}

$iscc = Get-Command iscc -ErrorAction SilentlyContinue
if (-not $iscc) {
    $default = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
    if (Test-Path $default) { $iscc = @{ Source = $default } }
}
if (-not $iscc) { throw "Inno Setup (iscc) not on PATH" }

Push-Location $StudioRoot
try {
    & $iscc.Source /Qp "installer\LiWorldStudio.iss"
    Write-Host "Installer: $StudioRoot\installer\out\LiWorldStudio-Setup.exe" -ForegroundColor Green
} finally {
    Pop-Location
}
