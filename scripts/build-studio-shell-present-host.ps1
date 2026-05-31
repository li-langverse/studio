# Build SDL present host for Li World Studio (WSL preferred; Git Bash fallback).
param(
    [switch]$WindowsNative
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_studio-paths.ps1"

$StudioRoot = Get-StudioRoot
$native = Join-Path $StudioRoot "deploy\studio-demo\native"
$src = Join-Path $native "studio_shell_present_host.c"
$paintFb = Join-Path $native "studio_shell_paint_fb.c"
$linuxOut = Join-Path $native "studio_shell_present_host"
$winOut = Join-Path $native "studio_shell_present_host.exe"

if (-not (Test-Path -LiteralPath $src)) { throw "Missing $src" }
if (-not (Test-Path -LiteralPath $paintFb)) { throw "Missing $paintFb" }

New-Item -ItemType Directory -Force -Path $native | Out-Null

function Build-PresentHostViaWsl {
    param([string]$StudioRoot, [string]$NativeOut)
    $wslNative = "$(Convert-ToWslPath $StudioRoot)/deploy/studio-demo/native"
    $cmd = 'set -euo pipefail; cd "' + $wslNative + '"; chmod +x ./native-sdl-build.sh 2>/dev/null || true; gcc -std=c11 -Wall -Wextra -O2 studio_shell_present_host.c studio_shell_paint_fb.c -o studio_shell_present_host $(pkg-config --cflags --libs sdl2)'
    wsl -e bash -lc $cmd
    if ($LASTEXITCODE -ne 0) { return $false }
    return (Test-Path -LiteralPath $NativeOut)
}

function Build-PresentHostViaGitBash {
    param([string]$StudioRoot, [string]$NativeOut)
    $bash = "C:\Program Files\Git\bin\bash.exe"
    if (-not (Test-Path $bash)) { return $false }
    $bashNative = "$(Convert-ToBashPath $StudioRoot)/deploy/studio-demo/native"
    $cmd = 'set -euo pipefail; cd "' + $bashNative + '"; gcc -std=c11 -Wall -Wextra -O2 studio_shell_present_host.c studio_shell_paint_fb.c -o studio_shell_present_host $(pkg-config --cflags --libs sdl2)'
    & $bash -lc $cmd
    if ($LASTEXITCODE -ne 0) { return $false }
    return (Test-Path -LiteralPath $NativeOut)
}

if ($WindowsNative) {
    $gcc = Get-Command x86_64-w64-mingw32-gcc -ErrorAction SilentlyContinue
    if (-not $gcc) { throw "x86_64-w64-mingw32-gcc not found" }
    & $gcc.Source -std=c11 -Wall -Wextra -O2 $src $paintFb -o $winOut
    Write-Host "Built $winOut"
    exit 0
}

$built = $false
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    $built = Build-PresentHostViaWsl -StudioRoot $StudioRoot -NativeOut $linuxOut
}
if (-not $built) {
    $built = Build-PresentHostViaGitBash -StudioRoot $StudioRoot -NativeOut $linuxOut
}
if (-not $built) { throw "Present host build failed (install SDL2 in WSL: sudo apt install libsdl2-dev)" }
Write-Host "Built $linuxOut" -ForegroundColor Green