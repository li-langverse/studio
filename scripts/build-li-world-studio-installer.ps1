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

function Ensure-DemoBinary {
    param(
        [string]$StudioRoot,
        [string]$LicRoot,
        [string]$LicBin
    )

    $buildDir = Join-Path $StudioRoot "build"
    $out = Join-Path $buildDir "li-studio-demo"
    $outExe = Join-Path $buildDir "li-studio-demo.exe"
    New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

    if (Test-Path -LiteralPath $outExe) {
        return $outExe
    }
    if (Test-Path -LiteralPath $out) {
        Copy-Item -LiteralPath $out -Destination $outExe -Force
        return $outExe
    }

    Write-Host "Building li-studio-demo via WSL (lic package graph)..." -ForegroundColor Yellow
    $wslLic = Convert-ToWslPath $LicRoot
    $wslStudio = Convert-ToWslPath $StudioRoot
    $wslLicBin = "$wslLic/build-wsl/compiler/lic/lic"
    if (-not (Test-Path -LiteralPath $LicBin)) {
        $wslLicBin = "$wslLic/build/compiler/lic/lic"
    } else {
        $wslLicBin = Convert-ToWslPath $LicBin
    }

    wsl -e bash -lc @"
set -euo pipefail
mkdir -p '$wslStudio/build'
if [[ -x '$wslLicBin' ]]; then
  cd '$wslLic'
  '$wslLicBin' build --allow-open-vc --no-lean-verify --numerically-stable '$wslStudio/src/main.li' -o '$wslStudio/build/li-studio-demo'
fi
"@

    if (Test-Path -LiteralPath $out) {
        Copy-Item -LiteralPath $out -Destination $outExe -Force
        return $outExe
    }

    $licDemo = Join-Path $LicRoot "build\li-studio-demo"
    if (Test-Path -LiteralPath $licDemo) {
        Write-Host "Using prebuilt demo from lic/build..." -ForegroundColor Yellow
        Copy-Item -LiteralPath $licDemo -Destination $outExe -Force
        return $outExe
    }

    throw "li-studio-demo missing. Build in lic (WSL): lic build ../studio/src/main.li -o ../studio/build/li-studio-demo"
}

$StudioRoot = Get-StudioRoot
$LicRoot = Get-LicRoot
$lic = Resolve-LicBinary

if (-not $lic) {
    Write-Host "Building lic via WSL..." -ForegroundColor Yellow
    $bash = "C:\Program Files\Git\bin\bash.exe"
    if (-not (Test-Path $bash)) { throw "Git Bash required to build lic" }
    & $bash -lc "cd '$(Convert-ToBashPath $LicRoot)' && bash scripts/wsl-setup-build.sh"
    $lic = Resolve-LicBinary
}
if (-not $lic) { throw "lic binary not found under $LicRoot" }

if (-not $SkipDemoBuild) {
    $null = Ensure-DemoBinary -StudioRoot $StudioRoot -LicRoot $LicRoot -LicBin $lic
}

if (-not $SkipPresentHost) {
    & "$PSScriptRoot\build-studio-shell-present-host.ps1" -WindowsNative:$($env:OS -eq "Windows_NT")
}

& "$PSScriptRoot\ensure-studio-installer-assets.ps1"

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
