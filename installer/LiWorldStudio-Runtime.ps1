# Runtime launcher installed with Li World Studio (delegates to studio repo script).
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$launcher = Join-Path $here "launch-li-world-studio.ps1"
if (-not (Test-Path -LiteralPath $launcher)) {
    Write-Error "Missing $launcher"
}
& $launcher @Args
exit $LASTEXITCODE
