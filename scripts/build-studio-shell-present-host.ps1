# Build SDL present host for Li World Studio (WSL or MSYS2).
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

if ($WindowsNative) {
    $gcc = Get-Command x86_64-w64-mingw32-gcc -ErrorAction SilentlyContinue
    if (-not $gcc) { throw "x86_64-w64-mingw32-gcc not found (MSYS2 mingw-w64)" }
    & $gcc.Source -std=c11 -Wall -Wextra -O2 $src -o $winOut $(sdl2-config --cflags --libs 2>$null)
    Write-Host "Built $winOut"
    exit 0
}

$bash = "C:\Program Files\Git\bin\bash.exe"
if (-not (Test-Path $bash)) { throw "Git Bash required for WSL/Linux present host build" }

$wslStudio = ($StudioRoot -replace '\\', '/') -replace '^([A-Za-z]):', { "/mnt/$($_.Groups[1].Value.ToLower())" }
# simpler conversion
if ($StudioRoot -match '^([A-Za-z]):\\(.*)$') {
    $wslStudio = "/mnt/$($Matches[1].ToLower())/$($Matches[2] -replace '\\','/')"
}

& $bash -lc @"
set -euo pipefail
cd '$wslStudio/deploy/studio-demo/native'
chmod +x ../../scripts/native-sdl-build.sh 2>/dev/null || true
if [[ -x ./native-sdl-build.sh ]]; then
  ./native-sdl-build.sh studio_shell_present_host.c studio_shell_present_host
else
  bash '$wslStudio/deploy/studio-demo/native/native-sdl-build.sh' studio_shell_present_host.c studio_shell_present_host
fi
"@

Write-Host "Built $linuxOut" -ForegroundColor Green
