# Li World Studio (li-studio)

Product repo for **Li World Studio** — compose dock, timeline, inspector, vertical sim profiles, MCP tools, and platform installers.

Import: `import studio`

## Layout

| Path | Purpose |
|------|---------|
| `src/` | `lib.li` + `main.li` (demo binary source) |
| `li-tests/smoke/` | Studio smokes (run via `lic check`) |
| `installer/` | Windows Inno Setup, AppImage assets, GPL-3.0 |
| `deploy/studio-demo/` | Native SDL present host + demo capture |
| `scripts/` | Build, run, plan-loop, and installer scripts |
| `docs/game-dev/` | World Studio master plan and specs |
| `docs/GUI-LIBRARY-PLAN.md` | Li-native GUI roadmap (Qt/Svelte/Next.js lessons, phased plan) |

## Prerequisites

Clone **lic** as a sibling directory (compiler + shared packages):

```
li/
  lic/     # https://github.com/li-langverse/lic
  studio/  # this repo
```

Set `LIC_ROOT` if your layout differs.

## Build demo

From WSL or Linux (recommended):

```bash
cd studio
export LIC_ROOT=../lic
$LIC_ROOT/build-wsl/compiler/lic/lic build --allow-open-vc --no-lean-verify src/main.li -o build/li-studio-demo
```

Windows (PowerShell):

```powershell
cd studio
./scripts/start-li-world-studio.ps1 -Build
./scripts/start-li-world-studio.ps1 -Profile game -HostPresent
```

## Windows installer

Requires [Inno Setup 6+](https://jrsoftware.org/isinfo.php), Git Bash/WSL for `lic` build:

```powershell
./scripts/ensure-studio-installer-assets.ps1
./scripts/build-li-world-studio-installer.ps1
# Output: installer/out/LiWorldStudio-Setup.exe
```

## Linux AppImage

Build demo first, then package using `installer/out/LiWorldStudio.AppDir` layout (see `installer/README.md`).

## Dependencies

`li.toml` path-deps point at `../lic/packages/*` (li-gui, li-ui, li-sim-*, li-render, lig, …). Full build requires **lic** sibling + **lip** registry packages resolved by the compiler.

## Related repos

- **lic** — Li compiler and generic packages (not studio product)
- **li-studio-ai** — agent orchestration (`import studio.ai`), still in lic monorepo for now

## X demo (marketing reel)

`docs/demo/studio-x-demo-script.md`, `./scripts/record-studio-x-demo.sh`
