# Launch Li World Studio native SDL window (I/O-only host + optional Li --rgb-ppm blit).
param(
    [int]$ProfileId = 1,
    [string]$Profile = "",
    [int]$Width = 1280,
    [int]$Height = 720,
    [int]$HoldMs = 0,
    [switch]$Headless,
    [switch]$WindowsNative
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_studio-paths.ps1"

$StudioRoot = Get-StudioRoot
$paths = Get-PresentHostPaths $StudioRoot
$outDir = Join-Path $paths.NativeDir "out"
$outPpm = Join-Path $outDir "frame-000.ppm"
$outPng = Join-Path $StudioRoot "docs\demo\media\native-verticals\png\launch-native-window.png"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $outPng) | Out-Null

function Ensure-Built {
    $preferWin = $WindowsNative.IsPresent -or ($env:OS -eq "Windows_NT")
    $bin = Resolve-PresentHostBin -StudioRoot $StudioRoot -PreferWindowsNative:$preferWin
    if ($bin) { return $bin }
    if ($WindowsNative) {
        & "$PSScriptRoot\build-studio-shell-present-host.ps1" -WindowsNative
    } else {
        & "$PSScriptRoot\build-studio-shell-present-host.ps1"
    }
    $bin = Resolve-PresentHostBin -StudioRoot $StudioRoot -PreferWindowsNative:$preferWin
    if (-not $bin) { throw "Present host build failed" }
    return $bin
}

$bin = Ensure-Built
$hostArgs = @("--width", $Width, "--height", $Height, "--screenshot", $outPpm)
if (-not $Headless) { $hostArgs += "--persist" }

$hostEnv = @{}
if ($Profile) { $hostEnv.STUDIO_DEMO_PROFILE = $Profile }

Write-Host "Launching native window (profile=$ProfileId, ${Width}x${Height})..." -ForegroundColor Green
Write-Host "  bin: $bin"
Write-Host "  platform: $(if (Test-PeBinary $bin) { 'Windows native' } else { 'WSL SDL' })"
Write-Host "  Close with Escape or window X when --persist is set."

$rc = Invoke-PresentHost -HostBin $bin -HostArgs $hostArgs -Env $hostEnv
if ($rc -ne 0) { exit $rc }

if (Test-Path -LiteralPath $outPpm) {
    python "$StudioRoot\scripts\studio-ppm-to-png.py" $outDir $outDir 2>$null
    if (Test-Path -LiteralPath (Join-Path $outDir "frame-000.png")) {
        Copy-Item -Force (Join-Path $outDir "frame-000.png") $outPng
        Write-Host "Screenshot: $outPng" -ForegroundColor Green
    } else {
        Write-Host "PPM frame: $outPpm" -ForegroundColor Green
    }
}

Write-Host @"

REAL because:
  - SDL window on desktop (Windows native or WSLg), not HTML mock
  - I/O-only host; product pixels via Li raster --rgb-ppm blit when wired
  - backend=sdl_li_blit or sdl_io_only (not cpu_chip_only stub)

lic runtime:
  `$env:LIG_HOST_PRESENT = '1'
  `$env:STUDIO_SHELL_PRESENT_HOST_BIN = '$bin'
"@
