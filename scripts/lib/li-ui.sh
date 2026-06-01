# Li terminal UI — space-tech palette (respects NO_COLOR, plain when not a TTY).
# shellcheck shell=bash
# Usage: source "$ROOT/scripts/lib/li-ui.sh"

_li_ui_init() {
  if [[ -n "${LI_UI_INIT:-}" ]]; then
    return
  fi
  LI_UI_INIT=1
  LI_USE_COLOR=0
  if [[ -z "${NO_COLOR:-}" && -t 1 ]]; then
    LI_USE_COLOR=1
  fi
  if [[ "${CI:-}" == "true" && -z "${LI_FORCE_COLOR:-}" ]]; then
    LI_USE_COLOR=0
  fi

  LI_RESET=$'\033[0m'
  LI_DIM=$'\033[2m'
  LI_BOLD=$'\033[1m'
  LI_CYAN=$'\033[38;2;61;214;255m'
  LI_VIOLET=$'\033[38;2;124;92;255m'
  LI_MINT=$'\033[38;2;46;230;168m'
  LI_AMBER=$'\033[38;2;255;179;71m'
  LI_ROSE=$'\033[38;2;255;92;122m'
  LI_ICE=$'\033[38;2;232;238;247m'
  LI_MUTED=$'\033[38;2;139;156;179m'

  if [[ "$LI_USE_COLOR" -eq 0 ]]; then
    LI_RESET="" LI_DIM="" LI_BOLD="" LI_CYAN="" LI_VIOLET="" LI_MINT="" LI_AMBER=""
    LI_ROSE="" LI_ICE="" LI_MUTED=""
  fi
}
_li_ui_init

li_phase() {
  printf '\n%s▸ %s%s %s\n' "$LI_CYAN" "$LI_BOLD" "$1" "$LI_RESET"
}

li_ok() {
  printf '  %s◆ %s%s\n' "$LI_MINT" "$1" "$LI_RESET"
}

li_warn() {
  printf '  %s△ %s%s\n' "$LI_AMBER" "$1" "$LI_RESET"
}

li_fail() {
  printf '  %s✕ %s%s\n' "$LI_ROSE" "$1" "$LI_RESET" >&2
}

li_gate_ok() {
  printf '\n%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "$LI_DIM" "$LI_RESET"
  printf '%s  GATE CLEAR  %s %s\n' "$LI_MINT" "$1" "$LI_RESET"
  printf '%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n\n' "$LI_DIM" "$LI_RESET"
}

li_gate_fail() {
  printf '\n%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "$LI_DIM" "$LI_RESET"
  printf '%s  GATE HOLD  %s %s\n' "$LI_ROSE" "$1" "$LI_RESET" >&2
  printf '%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n\n' "$LI_DIM" "$LI_RESET" >&2
}
