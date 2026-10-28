#!/usr/bin/env bash
# Shared helpers for mise tasks. Mirrors the colour and symlink behaviour
# the Makefile used to provide.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$DOTFILES_DIR/bin:$PATH"

COM_COLOR=$'\033[0;34m'
OBJ_COLOR=$'\033[0;36m'
OK_COLOR=$'\033[0;32m'
ERROR_COLOR=$'\033[0;31m'
WARN_COLOR=$'\033[0;33m'
RESET=$'\033[m'

colorize() { printf '%s%s%s' "$1" "$2" "$RESET"; }
info() { printf '%s\n' "$(colorize "$COM_COLOR" "$*")"; }
ok() { printf '%s\n' "$(colorize "$OK_COLOR" "$*")"; }
warn() { printf '%s\n' "$(colorize "$WARN_COLOR" "$*")" >&2; }
die() { printf '%s\n' "$(colorize "$ERROR_COLOR" "$*")" >&2; exit 1; }

create_symlink() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    warn "$dest already exists: renaming it to $dest.orig"
    mv "$dest" "$dest.orig"
  fi
  ln -vsf "$src" "$dest"
}

enable_user_unit() {
  local unit="$1"
  if is-macos; then
    return 0
  fi
  if ! command -v systemctl >/dev/null 2>&1; then
    warn "systemctl not found; enable $unit by hand after installing systemd"
    return 0
  fi
  systemctl --user daemon-reload || warn "systemctl --user daemon-reload failed"
  systemctl --user enable --now "$unit" || warn "could not enable $unit (no user session?)"
  loginctl enable-linger "${USER:-}" 2>/dev/null || true
}

install_launch_agent() {
  local src="$1" label="$2"
  local dest="$HOME/Library/LaunchAgents/${label}.plist"
  mkdir -p "$HOME/Library/LaunchAgents"
  cp "$src" "$dest"
  if command -v launchctl >/dev/null 2>&1; then
    local domain="gui/$(id -u)"
    launchctl bootout "$domain" "$dest" >/dev/null 2>&1 || true
    launchctl bootstrap "$domain" "$dest" || warn "launchctl bootstrap failed for $label"
  fi
}
