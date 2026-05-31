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

function Convert-ToBashPath([string]$WinPath) {
    if (-not $WinPath) { return $WinPath }
    $p = $WinPath
    if (Test-Path -LiteralPath $p -ErrorAction SilentlyContinue) {
        $p = (Resolve-Path -LiteralPath $p).Path
    }
    $p = $p -replace '\\', '/'
    if ($p -match '^([A-Za-z]):(.*)$') {
        return "/$($Matches[1].ToLower())$($Matches[2])"
    }
    return $p
}

function Convert-ToWslPath([string]$WinPath) {
    $p = Convert-ToBashPath $WinPath
    if ($p -match '^/([a-z])(/.*)$') {
        return "/mnt/$($Matches[1])$($Matches[2])"
    }
    return $p
}


function Test-ElfBinary([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $b = [System.IO.File]::ReadAllBytes($Path)
    return $b.Length -ge 4 -and $b[0] -eq 0x7F -and $b[1] -eq 0x45 -and $b[2] -eq 0x4C -and $b[3] -eq 0x46
}

function Invoke-LiStudioDemo {
    param(
        [Parameter(Mandatory)][string]$DemoPath,
        [string]$StudioRoot = (Get-StudioRoot)
    )
    if (-not (Test-ElfBinary $DemoPath)) {
        & $DemoPath
        return $LASTEXITCODE
    }
    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        throw "li-studio-demo is a Linux (WSL) binary. Install WSL2: wsl --install"
    }
    $wslStudio = Convert-ToWslPath $StudioRoot
    $wslDemo = Convert-ToWslPath $DemoPath
    $parts = @("cd '$wslStudio'")
    foreach ($name in @('STUDIO_DEMO_PROFILE','STUDIO_DEMO_FRAMES','LIG_HOST_PRESENT','STUDIO_SHELL_PRESENT_HOST_BIN','STUDIO_DEMO_LOOP_TICK','LIG_WGPU_READBACK')) {
        $v = [Environment]::GetEnvironmentVariable($name)
        if ($v) {
            if ($name -eq 'STUDIO_SHELL_PRESENT_HOST_BIN') { $v = Convert-ToWslPath $v }
            $escaped = $v -replace "'", "'\''"
            $parts += "export $name='$escaped'"
        }
    }
    $parts += "'$wslDemo'"
    wsl -e bash -lc ($parts -join ' && ')
    return $LASTEXITCODE
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
            $bashLic = Convert-ToBashPath $licRoot
            $p = & $bash -lc "cd '$bashLic' && ./scripts/resolve-lic.sh" 2>$null
            if ($p -and (Test-Path -LiteralPath $p.Trim())) { return $p.Trim() }
        }
    }
    return $null
}
