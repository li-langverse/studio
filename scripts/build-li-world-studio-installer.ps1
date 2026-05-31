# Build Li World Studio Windows installer (Inno Setup).
param(
    [switch]$SkipDemoBuild,
    [switch]$SkipPresentHost,
    [switch]$InstallInno
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_studio-paths.ps1"

function Find-InnoSetupIscc {
    $cmd = Get-Command iscc -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe")
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
        "C:\Program Files\Inno Setup 6\ISCC.exe"
    )
    foreach ($p in $candidates) {
        if (Test-Path -LiteralPath $p) {
            return (Resolve-Path -LiteralPath $p).Path
        }
    }
    return $null
}

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

$isccPath = Find-InnoSetupIscc
if (-not $isccPath -and $InstallInno) {
    Write-Host "Inno Setup not found; installing via winget..." -ForegroundColor Yellow
    winget install --id JRSoftware.InnoSetup -e --accept-package-agreements --accept-source-agreements
    $isccPath = Find-InnoSetupIscc
}
if (-not $isccPath) {
    throw @"
Inno Setup 6 (ISCC.exe) not found. Checked PATH, %LOCALAPPDATA%\Programs\Inno Setup 6, and Program Files.

Install manually from https://jrsoftware.org/isinfo.php or run:
  winget install --id JRSoftware.InnoSetup -e --accept-package-agreements

Then re-run this script, or pass -InstallInno to install automatically.
"@
}

Push-Location $StudioRoot
try {
    & $isccPath /Qp "installer\LiWorldStudio.iss"
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup compile failed (exit $LASTEXITCODE)" }
    Write-Host "Installer: $StudioRoot\installer\out\LiWorldStudio-Setup.exe" -ForegroundColor Green
} finally {
    Pop-Location
}
