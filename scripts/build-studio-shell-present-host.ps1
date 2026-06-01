# Build SDL present host for Li World Studio.
# Windows: prefer native .exe (MinGW + SDL2) — no WSL required (wsg-w5-windows-native).
# Linux/macOS dev on Windows: WSL ELF fallback when MinGW/SDL unavailable.
param(
    [switch]$WindowsNative,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_studio-paths.ps1"

$StudioRoot = Get-StudioRoot
$native = Join-Path $StudioRoot "deploy\studio-demo\native"
$src = Join-Path $native "studio_shell_present_host.c"
$linuxOut = Join-Path $native "studio_shell_present_host"
$winOut = Join-Path $native "studio_shell_present_host.exe"

if (-not (Test-Path -LiteralPath $src)) { throw "Missing $src" }

New-Item -ItemType Directory -Force -Path $native | Out-Null

function Get-MingwGcc {
    foreach ($name in @("x86_64-w64-mingw32-gcc", "gcc")) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

function Get-MingwPkgConfig {
    foreach ($name in @("x86_64-w64-mingw32-pkg-config", "pkg-config")) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    $msys = @(
        "C:\msys64\mingw64\bin\pkg-config.exe",
        "C:\tools\msys64\mingw64\bin\pkg-config.exe"
    )
    foreach ($p in $msys) {
        if (Test-Path -LiteralPath $p) { return $p }
    }
    return $null
}

function Get-MingwSdlFlags {
    $pkg = Get-MingwPkgConfig
    if ($pkg) {
        $flags = & $pkg --cflags --libs sdl2 2>$null
        if ($LASTEXITCODE -eq 0 -and $flags) { return $flags.Trim() }
    }
    foreach ($root in @("C:\msys64\mingw64", "C:\tools\msys64\mingw64")) {
        $inc = Join-Path $root "include\SDL2"
        $lib = Join-Path $root "lib"
        if ((Test-Path $inc) -and (Test-Path $lib)) {
            return "-I`"$inc`" -L`"$lib`" -lSDL2main -lSDL2"
        }
    }
    return $null
}

function Copy-Sdl2Dll([string]$NativeDir) {
    foreach ($dll in @(
        "C:\msys64\mingw64\bin\SDL2.dll",
        "C:\tools\msys64\mingw64\bin\SDL2.dll"
    )) {
        if (Test-Path -LiteralPath $dll) {
            Copy-Item -Force -LiteralPath $dll -Destination (Join-Path $NativeDir "SDL2.dll")
            return
        }
    }
}

function Build-PresentHostWindowsNative {
    param([string]$OutPath)
    if (-not $Force -and (Test-Path -LiteralPath $OutPath)) {
        $srcTime = (Get-Item $src).LastWriteTime
        $binTime = (Get-Item $OutPath).LastWriteTime
        if ($srcTime -le $binTime) {
            Write-Host "Present host up to date: $OutPath" -ForegroundColor DarkGray
            return $true
        }
    }
    $gcc = Get-MingwGcc
    if (-not $gcc) { return $false }
    $sdl = Get-MingwSdlFlags
    if (-not $sdl) {
        Write-Host "MinGW SDL2 not found (install MSYS2: pacman -S mingw-w64-x86_64-SDL2)" -ForegroundColor Yellow
        return $false
    }
    Write-Host "Building Windows native present host..." -ForegroundColor Cyan
    $args = @("-std=c11", "-Wall", "-Wextra", "-O2", $src, "-o", $OutPath)
    $args += $sdl -split '\s+'
    & $gcc @args
    if ($LASTEXITCODE -ne 0) { return $false }
    Copy-Sdl2Dll (Split-Path $OutPath -Parent)
    Write-Host "Built $OutPath" -ForegroundColor Green
    return $true
}

function Build-PresentHostViaWsl {
    param([string]$NativeOut)
    $wslNative = "$(Convert-ToWslPath $StudioRoot)/deploy/studio-demo/native"
    $cmd = 'set -euo pipefail; cd "' + $wslNative + '"; chmod +x ./native-sdl-build.sh 2>/dev/null || true; ./native-sdl-build.sh studio_shell_present_host.c studio_shell_present_host'
    wsl -e bash -lc $cmd
    if ($LASTEXITCODE -ne 0) { return $false }
    return (Test-Path -LiteralPath $NativeOut)
}

function Build-PresentHostViaGitBash {
    param([string]$NativeOut)
    $bash = "C:\Program Files\Git\bin\bash.exe"
    if (-not (Test-Path $bash)) { return $false }
    $bashNative = "$(Convert-ToBashPath $StudioRoot)/deploy/studio-demo/native"
    $cmd = 'set -euo pipefail; cd "' + $bashNative + '"; ./native-sdl-build.sh studio_shell_present_host.c studio_shell_present_host'
    & $bash -lc $cmd
    if ($LASTEXITCODE -ne 0) { return $false }
    return (Test-Path -LiteralPath $NativeOut)
}

$isWindows = ($env:OS -eq "Windows_NT") -or ($PSVersionTable.PSPlatform -eq "Win32NT")

if ($WindowsNative -or ($isWindows -and -not $WindowsNative.IsPresent)) {
    if (Build-PresentHostWindowsNative -OutPath $winOut) {
        exit 0
    }
    if ($WindowsNative) {
        throw "Windows native present host build failed (install MSYS2 MinGW + SDL2)"
    }
}

$built = $false
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    $built = Build-PresentHostViaWsl -NativeOut $linuxOut
}
if (-not $built) {
    $built = Build-PresentHostViaGitBash -NativeOut $linuxOut
}
if (-not $built) {
    if ($isWindows -and (Test-Path -LiteralPath $winOut)) {
        Write-Host "Using existing Windows native host: $winOut" -ForegroundColor Yellow
        exit 0
    }
    throw "Present host build failed (Windows: MSYS2 MinGW+SDL2; Linux dev: WSL libsdl2-dev)"
}
Write-Host "Built $linuxOut" -ForegroundColor Green
