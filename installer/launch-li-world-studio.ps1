# Launch li-studio-demo from installed layout (or dev tree).
param(
    [ValidateSet("game", "sim_rl", "sim_scientific", "sim_robotics", "sim_automotive", "sim_additive", "sim_drug_design")]
    [string]$Profile = "game",
    [int]$Frames = 3,
    [switch]$HostPresent
)

$ErrorActionPreference = "Stop"
$app = Split-Path -Parent $MyInvocation.MyCommand.Path
$demo = Join-Path $app "li-studio-demo.exe"
if (-not (Test-Path -LiteralPath $demo)) {
    $demo = Join-Path $app "li-studio-demo"
}
if (-not (Test-Path -LiteralPath $demo)) {
    Write-Error "li-studio-demo not found in $app"
}

$env:STUDIO_DEMO_PROFILE = $Profile
$env:STUDIO_DEMO_FRAMES = "$Frames"
if ($HostPresent) {
    $env:LIG_HOST_PRESENT = "1"
    $hostBin = Join-Path $app "studio_shell_present_host.exe"
    if (-not (Test-Path $hostBin)) { $hostBin = Join-Path $app "studio_shell_present_host" }
    if (Test-Path -LiteralPath $hostBin) {
        $env:STUDIO_SHELL_PRESENT_HOST_BIN = $hostBin
    }
} else {
    Remove-Item Env:LIG_HOST_PRESENT -ErrorAction SilentlyContinue
    Remove-Item Env:STUDIO_SHELL_PRESENT_HOST_BIN -ErrorAction SilentlyContinue
}

& $demo
exit $LASTEXITCODE
