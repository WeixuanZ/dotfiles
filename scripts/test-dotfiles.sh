#!/usr/bin/env bash
# Checks for the dotfiles, on macOS or Linux. No network. tmux and herdr are
# checked when installed.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail=0

pass() { printf 'ok   %s\n' "$1"; }
flunk() { printf 'FAIL %s\n' "$1" >&2; fail=1; }
check() { local name="$1"; shift; if "$@"; then pass "$name"; else flunk "$name"; fi; }
expect() { if [[ "$3" == "$2" ]]; then pass "$1"; else flunk "$1: got '$3', want '$2'"; fi; }

# --- syntax, configs, and mise tasks ---------------------------------------
for f in "$ROOT"/scripts/*.sh "$ROOT"/misc/.local/bin/*; do
  bash -n "$f" || flunk "syntax ${f#"$ROOT"/}"
done

python3 -I - "$ROOT" <<'PY' || fail=1
import json, plistlib, re, subprocess, sys
from pathlib import Path
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib

root = Path(sys.argv[1])
files = subprocess.run(["git", "-C", root, "ls-files"], capture_output=True,
                       text=True, check=True).stdout.split()

def jsonc(text):  # Zed's JSON has // comments
    return json.loads(re.sub(r'("(?:\\.|[^"\\])*")|//[^\n]*',
                             lambda m: m.group(1) or "", text))

for f in files:
    path = root / f
    if f.endswith(".toml"):
        tomllib.loads(path.read_text())
    elif f.endswith(".json"):
        jsonc(path.read_text())
    elif f.endswith(".plist"):
        plistlib.loads(path.read_bytes())

tasks = tomllib.loads((root / "mise.toml").read_text())["tasks"]
main = (root / "scripts/tasks.sh").read_text().split("\nmain() {")[1]
handlers = {h for label in re.findall(r"^ +([a-z0-9|-]+)\)", main, re.M)
            for h in label.split("|")}
for name, task in tasks.items():
    for dep in task.get("depends", []):
        assert dep in tasks, f"{name} depends on missing task {dep}"
    run = re.fullmatch(r"bash scripts/tasks.sh (\S+)", task.get("run", ""))
    assert not run or run[1] in handlers, f"tasks.sh has no handler for {run[1]}"
print("ok   configs parse and mise tasks resolve")
PY

# --- linker ----------------------------------------------------------------
LINK_HOME="$TMP/home"
HOME="$LINK_HOME" bash "$ROOT/scripts/tasks.sh" link >/dev/null
for path in .gitconfig .zshrc .vimrc .tmux.conf .ssh/config \
  .config/herdr/config.toml .config/alacritty/alacritty.toml \
  .config/systemd/user/tmux.service .config/zed/settings.json \
  .config/zed/keymap.json .config/worktrunk/config.toml \
  .local/bin/tmux-clipboard .local/bin/wt-sync-deps .pi/agent/settings.json; do
  check "link $path" test -L "$LINK_HOME/$path"
done
check "linked scripts stay executable" test -x "$LINK_HOME/.local/bin/tmux-clipboard"

# --- clipboard -------------------------------------------------------------
fake="$TMP/fake-bin"
mkdir -p "$fake"
for tool in pbcopy wl-copy xclip; do
  printf '#!/bin/sh\necho %s >>"%s/called"\ncat >"%s/copied"\n' "$tool" "$TMP" "$TMP" >"$fake/$tool"
done
chmod +x "$fake"/*
osc='1b5d35323b63' # ESC ] 5 2 ; c
# clip TEXT [VAR=value...]: hex of what tmux-clipboard printed
clip() {
  local text="$1"
  shift
  rm -f "$TMP/called" "$TMP/copied"
  printf '%s' "$text" \
    | env -u TMUX -u SSH_CONNECTION -u SSH_TTY -u DISPLAY -u WAYLAND_DISPLAY \
      PATH="$fake:$PATH" "$@" "$ROOT/misc/.local/bin/tmux-clipboard" \
    | od -An -tx1 | tr -d ' \n'
}
used() { cat "$TMP/called" "$TMP/copied" 2>/dev/null | tr '\n' ' '; }

out="$(clip hi SSH_CONNECTION=1)"
check "ssh: OSC 52" test "${out#*"$osc"}" != "$out"
expect "ssh: no local tool" "" "$(used)"
if [[ "$(uname -s)" == Darwin ]]; then
  clip hi >/dev/null
  expect "macOS: pbcopy" "pbcopy hi" "$(used)"
else
  clip hi WAYLAND_DISPLAY=wayland-0 >/dev/null
  expect "wayland: wl-copy" "wl-copy hi" "$(used)"
  clip hi DISPLAY=:1 >/dev/null
  expect "x11: xclip" "xclip hi" "$(used)"
  out="$(clip hi)"
  check "no display: OSC 52" test "${out#*"$osc"}" != "$out"
  expect "no display: no local tool" "" "$(used)"
fi

# --- Brewfile filter -------------------------------------------------------
printf '%s\n' 'tap "homebrew/core"' 'tap "heroku/brew"' 'brew "node@16"' \
  'brew "python@3.10"' 'brew "exa"' 'brew "ripgrep"' 'cask "iterm2"' >"$TMP/Brewfile"
(source "$ROOT/scripts/lib.sh" && modernize_brewfile "$TMP/Brewfile" "$TMP/Brewfile.out")
expect "brewfile filter" $'tap "heroku/brew"\nbrew "ripgrep"\ncask "iterm2"' "$(cat "$TMP/Brewfile.out")"

# --- uv tools --------------------------------------------------------------
mkdir -p "$TMP/uv/bin" "$TMP/uv/install"
printf '#!/bin/sh\necho "$*" >>"%s/uv.log"\n' "$TMP" >"$TMP/uv/bin/uv"
chmod +x "$TMP/uv/bin/uv"
printf '# comment\nruff\njupyterlab --with numpy  # trailing\n\n' >"$TMP/uv/install/uv-tools.txt"
PATH="$TMP/uv/bin:$PATH" DOTFILES_DIR="$TMP/uv" bash -c 'source "$1"; install_uv_tools' _ \
  "$ROOT/scripts/tasks.sh" >/dev/null
expect "uv tool lines" $'tool install ruff\ntool install jupyterlab --with numpy' "$(cat "$TMP/uv.log")"

# --- wt-sync-deps ----------------------------------------------------------
sbin="$TMP/sync-bin"
mkdir -p "$sbin"
for tool in wt uv pnpm npm yarn; do
  # `uv sync --frozen` fails, to exercise the fallback.
  printf '#!/bin/sh\necho "%s $*" >>"%s/sync.log"\n[ "$*" != "sync --frozen" ]\n' "$tool" "$TMP" >"$sbin/$tool"
done
chmod +x "$sbin"/*
# sync_case NAME EXPECTED_LOG [FILE...]
sync_case() {
  local name="$1" want="$2" repo="$TMP/repo-$1" f
  shift 2
  git init -q "$repo"
  for f in "$@"; do
    mkdir -p "$repo/$(dirname "$f")"
    : >"$repo/$f"
    chmod +x "$repo/$f"
  done
  : >"$TMP/sync.log"
  (cd "$repo" && PATH="$sbin:$PATH" bash "$ROOT/misc/.local/bin/wt-sync-deps")
  expect "wt-sync-deps $name" "$want" "$(cat "$TMP/sync.log")"
}
copy='wt step copy-ignored'
sync_case empty "$copy"
sync_case pnpm "$copy"$'\npnpm install --frozen-lockfile' package.json pnpm-lock.yaml
sync_case npm-ci "$copy"$'\nnpm ci' package.json package-lock.json
sync_case yarn "$copy"$'\nyarn install --frozen-lockfile' package.json yarn.lock
sync_case yarn-berry "$copy"$'\nyarn install --immutable' package.json yarn.lock .yarnrc.yml
sync_case npm "$copy"$'\nnpm install' package.json
sync_case copied-node "$copy" package.json node_modules/.keep
sync_case copied-venv "$copy" uv.lock .venv/bin/python
sync_case uv-fallback "$copy"$'\nuv sync --frozen\nuv sync' uv.lock

# --- claude-hud ------------------------------------------------------------
ch="$TMP/claude"
mkdir -p "$ch/bin" "$ch/home/.claude/plugins/cache/claude-hud/claude-hud/1.0.0/scripts"
# Fake claude: logs its arguments; `list` prints $ch/listed.
printf '#!/bin/sh\necho "claude $*" >>"%s/log"\ncase "$*" in *list) cat "%s/listed" 2>/dev/null ;; esac\n' \
  "$ch" "$ch" >"$ch/bin/claude"
printf '#!/bin/sh\necho "bun $*" >>"%s/log"\n' "$ch" >"$ch/bin/bun"
chmod +x "$ch/bin"/*
hud() {
  : >"$ch/log"
  HOME="$ch/home" PATH="$ch/bin:$PATH" bash "$ROOT/scripts/tasks.sh" claude >/dev/null
  sed "s|$ch/home/.claude/plugins/cache/claude-hud/claude-hud/1.0.0/|HUD/|" "$ch/log"
}
setup='bun HUD/scripts/setup.mjs install --shell posix'
expect "claude-hud installs" "claude plugin marketplace list
claude plugin marketplace add jarrodwatts/claude-hud
claude plugin list
claude plugin install claude-hud@claude-hud
$setup" "$(hud)"
printf 'claude-hud\nclaude-hud@claude-hud\n' >"$ch/listed"
expect "claude-hud rerun only runs setup" $'claude plugin marketplace list\nclaude plugin list\n'"$setup" "$(hud)"

# --- default editor --------------------------------------------------------
python3 -I - "$ROOT/scripts" <<'PY' || fail=1
import importlib, sys
sys.path.insert(0, sys.argv[1])
editor = importlib.import_module("default-editor")
ext = {"LSHandlerContentTagClass": "public.filename-extension"}
browser = {"LSHandlerURLScheme": "https", "LSHandlerRoleAll": "browser"}
prefs = {"LSHandlers": [
    browser,
    {"LSHandlerContentType": "public.python-script", "LSHandlerRoleAll": "old"},
    {**ext, "LSHandlerContentTag": "GO", "LSHandlerRoleAll": "old"},
]}
out = editor.set_default(prefs, "new", ["public.python-script"], ["go"])["LSHandlers"]
assert out[0] == browser and len(out) == 3, out
assert {h["LSHandlerRoleAll"] for h in out[1:]} == {"new"}, out
if sys.platform == "darwin":
    assert "public.python-script" in editor.resolve_types(["py", "toml"])
print("ok   default-editor replaces only its own handlers")
PY

# --- tmux and herdr, when installed ----------------------------------------
if command -v tmux >/dev/null 2>&1; then
  socket="dotfiles-test-$$"
  t() { HOME="$LINK_HOME" tmux -L "$socket" "$@"; }
  check "tmux starts" t -f "$LINK_HOME/.tmux.conf" start-server
  opts="$(t show-options -g; t show-options -s)"
  for want in "prefix C-Space" "set-clipboard on" "@continuum-restore on" "@continuum-save-interval 5"; do
    check "tmux $want" grep -qF "$want" <<<"$opts"
  done
  check "tmux copies via tmux-clipboard" grep -qF tmux-clipboard <<<"$(t list-keys -T copy-mode-vi)"
  t kill-server || true
else
  printf 'skip tmux (not installed)\n'
fi

if command -v herdr >/dev/null 2>&1; then
  HOME="$LINK_HOME" herdr server >/dev/null 2>"$TMP/herdr.err" &
  pid=$!
  sleep 1
  log="$LINK_HOME/.config/herdr/herdr-server.log"
  check "herdr accepts its config" bash -c \
    'grep -q "herdr server started" "$1" && ! grep -Eiq "unknown key|invalid|error parsing" "$1" "$2"' \
    _ "$log" "$TMP/herdr.err"
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
else
  printf 'skip herdr (not installed)\n'
fi

exit "$fail"
