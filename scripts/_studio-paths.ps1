# Studio repo path helpers — lic compiler lives in sibling ../lic (or $env:LIC_ROOT).
function Get-StudioRoot {
    if ($env:STUDIO_ROOT) { return $env:STUDIO_ROOT }
    return (Split-Path $PSScriptRoot -Parent)
}

function Get-LicRoot {
    if ($env:LIC_ROOT) { return $env:LIC_ROOT }
    $studio = Get-StudioRoot
    $lic = Join-Path (Split-Path $studio -Parent) "lic"
    if (-not (Test-Path -LiteralPath $lic)) {
        throw "lic sibling not found at $lic (set `$env:LIC_ROOT)"
    }
    return (Resolve-Path -LiteralPath $lic).Path
}

function Resolve-LicBinary {
    $licRoot = Get-LicRoot
    foreach ($rel in @(
        "build-wsl\compiler\lic\lic",
        "build-wsl\compiler\lic\lic.exe",
        "build\compiler\lic\lic",
        "build\compiler\lic\lic.exe"
    )) {
        $c = Join-Path $licRoot $rel
        if (Test-Path -LiteralPath $c) { return (Resolve-Path -LiteralPath $c).Path }
    }
    $resolve = Join-Path $licRoot "scripts\resolve-lic.sh"
    if (Test-Path -LiteralPath $resolve) {
        $bash = "C:\Program Files\Git\bin\bash.exe"
        if (Test-Path $bash) {
            $p = & $bash -lc "cd '$($licRoot -replace '\\','/')' && ./scripts/resolve-lic.sh" 2>$null
            if ($p -and (Test-Path -LiteralPath $p.Trim())) { return $p.Trim() }
        }
    }
    return $null
}
