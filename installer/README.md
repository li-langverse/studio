Li World Studio installer assets
================================
Place optional branding files here before running iscc:
  app.ico          — 256x256 application icon
  wizard.bmp       — 164x314 sidebar (Inno standard)
  wizard-small.bmp — 55x55 top-right

Colors match docs/design/studio-design-tokens.toml (bg #0d1117, accent #3dd6ff).

Build from lic repo root:
  iscc /Qp installer\LiWorldStudio.iss

If `iscc` is not on PATH, install Inno Setup 6+ (https://jrsoftware.org/isinfo.php)
and add its folder (typically `C:\Program Files (x86)\Inno Setup 6`) to PATH, or invoke
with the full path. `scripts/world-studio-runnable-completion-gate.sh` skips the compile
step with a WARN when `iscc` is missing.

Output: installer\out\LiWorldStudio-Setup.exe

---

## Credits and license

- **Creator:** Julian
- **Copyright:** (c) Julian
- **License:** [GNU General Public License v3.0](LICENSE-GPL-3.0.txt) (`installer/LICENSE-GPL-3.0.txt`)

The Windows installer displays the GPL-3.0 text on the license page and requires acceptance before installation.
