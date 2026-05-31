# Launch Li World Studio native SDL window (no li-studio-demo exe required).
# Paints real shell chrome via studio_shell_paint_fb -> SDL texture upload.
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
$native = Join-Path $StudioRoot "deploy\studio-demo\native"
$srcHost = Join-Path $native "studio_shell_present_host.c"
$srcFb = Join-Path $native "studio_shell_paint_fb.c"
$linuxBin = Join-Path $native "studio_shell_present_host"
$winBin = Join-Path $native "studio_shell_present_host.exe"
$outDir = Join-Path $native "out"
$outPpm = Join-Path $outDir "frame-000.ppm"
$outPng = Join-Path $StudioRoot "docs\demo\media\native-verticals\png\launch-native-window.png"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $outPng) | Out-Null

function Build-PresentHost {
    if ($WindowsNative) {
        $gcc = Get-Command x86_64-w64-mingw32-gcc -ErrorAction SilentlyContinue
        if (-not $gcc) { throw "x86_64-w64-mingw32-gcc not found (install MSYS2 mingw-w64 + mingw-w64-SDL2)" }
        $sdl = & sdl2-config --cflags --libs 2>$null
        & $gcc.Source -std=c11 -Wall -Wextra -O2 $srcFb $srcHost -o $winBin $sdl
        return
    }
    $wslNative = "$(Convert-ToWslPath $StudioRoot)/deploy/studio-demo/native"
    wsl -e bash -lc "set -euo pipefail; cd '$wslNative'; cc -std=c11 -Wall -Wextra -O2 studio_shell_paint_fb.c studio_shell_present_host.c -o studio_shell_present_host \`$(pkg-config --cflags --libs sdl2)"
}

$bin = if ($WindowsNative) { $winBin } else { $linuxBin }
$needBuild = -not (Test-Path -LiteralPath $bin)
if ($needBuild -or ((Get-Item $srcHost).LastWriteTime -gt (Get-Item $bin).LastWriteTime)) {
    Write-Host "Building studio_shell_present_host..." -ForegroundColor Cyan
    Build-PresentHost
}

$args = @("--width", $Width, "--height", $Height, "--profile-id", $ProfileId, "--screenshot", $outPpm)
if (-not $Headless) { $args += "--persist" }

if ($Profile) { $env:STUDIO_DEMO_PROFILE = $Profile }

Write-Host "Launching native window (profile=$ProfileId, ${Width}x${Height})..." -ForegroundColor Green
Write-Host "  bin: $bin"
Write-Host "  Close with Escape or window X when --persist is set."

if ($WindowsNative) {
    & $bin @args
} else {
    $wslBin = "$(Convert-ToWslPath $StudioRoot)/deploy/studio-demo/native/studio_shell_present_host"
    $wslPpm = "$(Convert-ToWslPath $outPpm)"
    $wslArgs = ($args | ForEach-Object {
        if ($_ -eq $outPpm) { "'$wslPpm'" } else { "'$_'" }
    }) -join " "
    $profileEnv = if ($Profile) { "STUDIO_DEMO_PROFILE='$Profile' " } else { "" }
    wsl -e bash -lc "${profileEnv}'$wslBin' $wslArgs"
}

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
  - SDL window on desktop (WSLg or native Windows), not HTML mock
  - Pixels from studio_shell_paint_fb (mirrors li-gui studio_shell_layout_hd)
  - backend=sdl_paint_blit, pixel_source=paint_blit (not cpu_chip_only stub)

lic runtime:
  `$env:LIG_HOST_PRESENT = '1'
  `$env:STUDIO_SHELL_PRESENT_HOST_BIN = '$bin'
"@
