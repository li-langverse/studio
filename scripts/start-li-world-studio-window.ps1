# Open a real Li World Studio native SDL window (shell chrome paint blit - not HTML mock).
param(
    [ValidateSet("game", "sim_rl", "sim_scientific", "sim_robotics", "sim_automotive", "sim_additive", "sim_drug_design")]
    [string]$Profile = "game",
    [int]$Width = 1280,
    [int]$Height = 720,
    [switch]$Build,
    [switch]$ScreenshotOnly,
    [switch]$SkipLiDemo
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_studio-paths.ps1"

$StudioRoot = Get-StudioRoot
$native = Join-Path $StudioRoot "deploy\studio-demo\native"
$hostBin = Join-Path $native "studio_shell_present_host"
$outDir = Join-Path $StudioRoot "installer\out"
$ppmPath = Join-Path $outDir "frame-000.ppm"
$pngPath = Join-Path $outDir "studio-screenshot-real-window.png"

function Resolve-Demo {
    foreach ($name in @("li-studio-demo.exe", "li-studio-demo")) {
        $p = Join-Path $StudioRoot "build\$name"
        if (Test-Path -LiteralPath $p) { return (Resolve-Path -LiteralPath $p).Path }
    }
    return $null
}

function Ensure-PresentHost {
    if (Test-Path -LiteralPath $hostBin) { return $hostBin }
    & "$PSScriptRoot\build-studio-shell-present-host.ps1"
    if (-not (Test-Path -LiteralPath $hostBin)) {
        throw "Present host missing after build: $hostBin"
    }
    return $hostBin
}

if ($Build) {
    & "$PSScriptRoot\start-li-world-studio.ps1" -Build -Profile $Profile
}

$hostBin = Ensure-PresentHost
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$env:STUDIO_DEMO_PROFILE = $Profile
$wslHost = Convert-ToWslPath $hostBin
$wslOut = Convert-ToWslPath $outDir
$wslStudio = Convert-ToWslPath $StudioRoot

if ($ScreenshotOnly) {
    wsl -e bash -lc @"
set -euo pipefail
export STUDIO_DEMO_PROFILE='$Profile'
'$wslHost' --width $Width --height $Height --screenshot '$wslOut/frame-000.ppm'
python3 '$wslStudio/scripts/studio-ppm-to-png.py' '$wslOut' '$wslOut'
cp '$wslOut/frame-000.png' '$wslOut/studio-screenshot-real-window.png'
"@
    if ($LASTEXITCODE -ne 0) { throw "Screenshot capture failed" }
    Write-Host "Screenshot: $pngPath" -ForegroundColor Green
    exit 0
}

if (-not $SkipLiDemo) {
    $demo = Resolve-Demo
    if ($demo) {
        Write-Host "Running Li present loop (li-studio-demo)..." -ForegroundColor Cyan
        $env:LIG_HOST_PRESENT = "1"
        $env:STUDIO_DEMO_FRAMES = "3"
        $env:STUDIO_SHELL_PRESENT_HOST_BIN = $hostBin
        $rc = Invoke-LiStudioDemo -DemoPath $demo -StudioRoot $StudioRoot
        if ($rc -ne 0) {
            Write-Host "li-studio-demo returned $rc (continuing to open window)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "li-studio-demo not built; opening window only (use -Build or -SkipLiDemo)" -ForegroundColor Yellow
    }
}

Write-Host "Opening Li World Studio window profile=$Profile (Escape to close)" -ForegroundColor Cyan
$env:STUDIO_SHELL_PERSIST = "1"
wsl -e bash -lc @"
export STUDIO_DEMO_PROFILE='$Profile'
export STUDIO_SHELL_PERSIST=1
export DISPLAY=\${DISPLAY:-:0}
'$wslHost' --width $Width --height $Height --persist
"@
exit $LASTEXITCODE
