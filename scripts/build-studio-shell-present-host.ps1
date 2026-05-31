# Build SDL present host for Li World Studio (WSL preferred; Git Bash fallback).
param(
    [switch]$WindowsNative
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_studio-paths.ps1"

$StudioRoot = Get-StudioRoot
$native = Join-Path $StudioRoot "deploy\studio-demo\native"
$src = Join-Path $native "studio_shell_present_host.c"
$linuxOut = Join-Path $native "studio_shell_present_host"
$winOut = Join-Path $native "studio_shell_present_host.exe"

if (-not (Test-Path -LiteralPath $src)) {
    throw "Missing $src"
}

New-Item -ItemType Directory -Force -Path $native | Out-Null

if ($WindowsNative) {
    $gcc = Get-Command x86_64-w64-mingw32-gcc -ErrorAction SilentlyContinue
    if (-not $gcc) { throw "x86_64-w64-mingw32-gcc not found (MSYS2 mingw-w64)" }
    & $gcc.Source -std=c11 -Wall -Wextra -O2 $src -o $winOut $(sdl2-config --cflags --libs 2>$null)
    Write-Host "Built $winOut"
    exit 0
}

function Build-PresentHostViaWsl {
    param([string]$StudioRoot, [string]$NativeOut)
    $wslNative = "$(Convert-ToWslPath $StudioRoot)/deploy/studio-demo/native"
    wsl -e bash -lc @"
set -euo pipefail
mkdir -p '$wslNative'
cd '$wslNative'
chmod +x ./native-sdl-build.sh 2>/dev/null || true
./native-sdl-build.sh studio_shell_present_host.c studio_shell_present_host
"@
    if ($LASTEXITCODE -ne 0) { return $false }
    return (Test-Path -LiteralPath $NativeOut)
}

function Build-PresentHostViaGitBash {
    param([string]$StudioRoot, [string]$NativeOut)
    $bash = "C:\Program Files\Git\bin\bash.exe"
    if (-not (Test-Path $bash)) { return $false }
    $bashNative = "$(Convert-ToBashPath $StudioRoot)/deploy/studio-demo/native"
    & $bash -lc @"
set -euo pipefail
mkdir -p '$bashNative'
cd '$bashNative'
chmod +x ./native-sdl-build.sh 2>/dev/null || true
./native-sdl-build.sh studio_shell_present_host.c studio_shell_present_host
"@
    if ($LASTEXITCODE -ne 0) { return $false }
    return (Test-Path -LiteralPath $NativeOut)
}

$built = $false
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    $built = Build-PresentHostViaWsl -StudioRoot $StudioRoot -NativeOut $linuxOut
}
if (-not $built) {
    $built = Build-PresentHostViaGitBash -StudioRoot $StudioRoot -NativeOut $linuxOut
}
if (-not $built) {
    throw "Present host build failed (install SDL2 in WSL: sudo apt install libsdl2-dev)"
}

Write-Host "Built $linuxOut" -ForegroundColor Green
