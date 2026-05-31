# Launch Li World Studio (li-studio-demo) on Windows.
# Resolves lic from sibling ../lic; builds demo in studio repo.
param(
    [ValidateSet("game", "sim_rl", "sim_scientific", "sim_robotics", "sim_automotive", "sim_additive", "sim_drug_design")]
    [string]$Profile = "game",
    [int]$Frames = 3,
    [switch]$HostPresent,
    [switch]$CheckOnly,
    [switch]$Build,
    [switch]$SkipPresentHostBuild,
    [switch]$RealWindow
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_studio-paths.ps1"

$StudioRoot = Get-StudioRoot
$LicRoot = Get-LicRoot

function Test-ElfBinary([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $b = [System.IO.File]::ReadAllBytes($Path)
    return $b.Length -ge 4 -and $b[0] -eq 0x7F -and $b[1] -eq 0x45 -and $b[2] -eq 0x4C -and $b[3] -eq 0x46
}

function Resolve-Demo {
    foreach ($name in @("li-studio-demo.exe", "li-studio-demo")) {
        $p = Join-Path $StudioRoot "build\$name"
        if (Test-Path -LiteralPath $p) { return (Resolve-Path -LiteralPath $p).Path }
    }
    return $null
}

function Ensure-PresentHost {
    $demoPath = Resolve-Demo
    $preferWin = $demoPath -and -not (Test-ElfBinary $demoPath)
    if (-not $preferWin) { $preferWin = ($env:OS -eq "Windows_NT") }
    $bin = Resolve-PresentHostBin -StudioRoot $StudioRoot -PreferWindowsNative:$preferWin
    if ($bin) {
        if (Test-PeBinary $bin) { return $bin }
        if (Test-ElfBinary $bin) { return Convert-ToWslPath $bin }
        return $bin
    }
    $build = Join-Path $PSScriptRoot "build-studio-shell-present-host.ps1"
    if (-not (Test-Path -LiteralPath $build)) { throw "Present host missing: $build" }
    Write-Host "Building SDL present host..." -ForegroundColor Yellow
    & $build
    $bin = Resolve-PresentHostBin -StudioRoot $StudioRoot -PreferWindowsNative:$preferWin
    if (-not $bin) { throw "Present host missing after build" }
    if (Test-PeBinary $bin) { return $bin }
    if (Test-ElfBinary $bin) { return Convert-ToWslPath $bin }
    return $bin
}

$lic = Resolve-LicBinary
$demo = Resolve-Demo

if ($CheckOnly) {
    Write-Host "studio: $StudioRoot"; Write-Host "lic: $LicRoot"
    Write-Host "lic bin: $(if ($lic) { $lic } else { '(missing)' })"
    Write-Host "demo: $(if ($demo) { $demo } else { '(missing)' })"
    if (-not $lic -or -not $demo) { exit 1 }; exit 0
}

if ($Build) {
    if (-not $lic) {
        $bash = "C:\Program Files\Git\bin\bash.exe"
        & $bash -lc "cd '$(Convert-ToBashPath $LicRoot)' && bash scripts/wsl-setup-build.sh"
        $lic = Resolve-LicBinary
    }
    if (-not $lic) { throw "lic not found" }
    $out = Join-Path $StudioRoot "build\li-studio-demo"
    New-Item -ItemType Directory -Force -Path (Split-Path $out) | Out-Null
    Write-Host "Building li-studio-demo via WSL (lic package graph)..." -ForegroundColor Yellow
    $wslLic = Convert-ToWslPath $LicRoot
    $wslStudio = Convert-ToWslPath $StudioRoot
    $wslLicBin = Convert-ToWslPath $lic
    wsl -e bash -lc @"
set -euo pipefail
mkdir -p '$wslStudio/build'
'$wslLicBin' build --allow-open-vc --no-lean-verify --numerically-stable '$wslStudio/src/main.li' -o '$wslStudio/build/li-studio-demo'
"@
    if ($LASTEXITCODE -ne 0) { throw "lic build failed (try WSL: clang-22 + --numerically-stable)" }
    $demo = Resolve-Demo
}

if (-not $demo) { Write-Host "Run with -Build"; exit 2 }

$env:STUDIO_DEMO_PROFILE = $Profile
$env:STUDIO_DEMO_FRAMES = "$Frames"
if ($HostPresent) {
    $env:LIG_HOST_PRESENT = "1"
    if (-not $SkipPresentHostBuild) { $env:STUDIO_SHELL_PRESENT_HOST_BIN = Ensure-PresentHost }
} else {
    Remove-Item Env:LIG_HOST_PRESENT -ErrorAction SilentlyContinue
}

if ($RealWindow) {
    & "$PSScriptRoot\start-li-world-studio-window.ps1" -Profile $Profile -Build:$Build
    exit $LASTEXITCODE
}

Write-Host "Li World Studio profile=$Profile demo=$demo host_present=$($HostPresent.IsPresent)" -ForegroundColor Cyan
exit (Invoke-LiStudioDemo -DemoPath $demo -StudioRoot $StudioRoot)
