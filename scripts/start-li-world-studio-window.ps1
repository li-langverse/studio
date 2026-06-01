# Open a real Li World Studio native SDL window (Li raster → --rgb-ppm blit, not HTML mock).
# wsg-w5-windows-native: prefers Windows .exe (no WSL); falls back to WSL ELF when needed.
param(
    [ValidateSet("game", "sim_rl", "sim_scientific", "sim_robotics", "sim_automotive", "sim_additive", "sim_drug_design")]
    [string]$Profile = "game",
    [int]$Width = 1280,
    [int]$Height = 720,
    [switch]$Build,
    [switch]$ScreenshotOnly,
    [switch]$SkipLiDemo,
    [switch]$WindowsNative
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_studio-paths.ps1"

$StudioRoot = Get-StudioRoot
$paths = Get-PresentHostPaths $StudioRoot
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
    $preferWin = $WindowsNative.IsPresent -or ($env:OS -eq "Windows_NT")
    $bin = Resolve-PresentHostBin -StudioRoot $StudioRoot -PreferWindowsNative:$preferWin
    if ($bin) { return $bin }
    if ($WindowsNative) {
        & "$PSScriptRoot\build-studio-shell-present-host.ps1" -WindowsNative
    } else {
        & "$PSScriptRoot\build-studio-shell-present-host.ps1"
    }
    $bin = Resolve-PresentHostBin -StudioRoot $StudioRoot -PreferWindowsNative:$preferWin
    if (-not $bin) { throw "Present host missing after build" }
    return $bin
}

if ($Build) {
    & "$PSScriptRoot\start-li-world-studio.ps1" -Build -Profile $Profile
}

$hostBin = Ensure-PresentHost
$useWindowsNative = Test-PeBinary $hostBin
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$env:STUDIO_DEMO_PROFILE = $Profile

$hostArgs = @("--width", $Width, "--height", $Height)
if ($ScreenshotOnly) {
    $hostArgs += @("--screenshot", $ppmPath)
} else {
    $hostArgs += "--persist"
}

$hostEnv = @{
    STUDIO_DEMO_PROFILE = $Profile
}
if (-not $ScreenshotOnly) {
    $hostEnv.STUDIO_SHELL_PERSIST = "1"
}

if ($ScreenshotOnly) {
    $rc = Invoke-PresentHost -HostBin $hostBin -HostArgs $hostArgs -Env $hostEnv
    if ($rc -ne 0) { throw "Screenshot capture failed (exit $rc)" }
    if (-not (Test-Path -LiteralPath $ppmPath)) { throw "Screenshot PPM missing: $ppmPath" }
    python "$StudioRoot\scripts\studio-ppm-to-png.py" $outDir $outDir 2>$null
    if (Test-Path -LiteralPath (Join-Path $outDir "frame-000.png")) {
        Copy-Item -Force (Join-Path $outDir "frame-000.png") $pngPath
    }
    Write-Host "Screenshot: $pngPath" -ForegroundColor Green
    Write-Host "  backend: $(if ($useWindowsNative) { 'windows_native_sdl' } else { 'wsl_sdl' })" -ForegroundColor DarkGray
    exit 0
}

if (-not $SkipLiDemo) {
    $demo = Resolve-Demo
    if ($demo) {
        Write-Host "Running Li present loop (li-studio-demo)..." -ForegroundColor Cyan
        $env:LIG_HOST_PRESENT = "1"
        $env:STUDIO_DEMO_FRAMES = "3"
        if ($useWindowsNative) {
            $env:STUDIO_SHELL_PRESENT_HOST_BIN = $hostBin
        } else {
            $env:STUDIO_SHELL_PRESENT_HOST_BIN = Convert-ToWslPath $hostBin
        }
        $rc = Invoke-LiStudioDemo -DemoPath $demo -StudioRoot $StudioRoot
        if ($rc -ne 0) {
            Write-Host "li-studio-demo returned $rc (continuing to open window)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "li-studio-demo not built; opening window only (use -Build or -SkipLiDemo)" -ForegroundColor Yellow
    }
}

Write-Host "Opening Li World Studio window profile=$Profile (Escape to close)" -ForegroundColor Cyan
Write-Host "  host: $hostBin" -ForegroundColor DarkGray
Write-Host "  platform: $(if ($useWindowsNative) { 'Windows native (no WSL)' } else { 'WSL SDL' })" -ForegroundColor DarkGray

exit (Invoke-PresentHost -HostBin $hostBin -HostArgs $hostArgs -Env $hostEnv)
