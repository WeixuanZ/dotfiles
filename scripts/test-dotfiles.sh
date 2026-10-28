#!/usr/bin/env bash
# Linux checks for the dotfiles. No network except the optional TPM clone
# performed by `mise run tmux` when you pass --with-tpm.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="${DOTFILES_TEST_PATH:-$PATH}"
fail=0

check() {
  local name="$1"
  shift
  if "$@"; then
    printf 'ok   %s\n' "$name"
  else
    printf 'FAIL %s\n' "$name" >&2
    fail=1
  fi
}

bash -n "$ROOT/scripts/lib.sh"
bash -n "$ROOT/scripts/tasks.sh"
bash -n "$ROOT/scripts/test-dotfiles.sh"
bash -n "$ROOT/misc/.local/bin/tmux-clipboard"
bash -n "$ROOT/misc/.local/bin/tmux-ensure"
bash -n "$ROOT/misc/.local/bin/herdr-main"
bash -n "$ROOT/misc/.local/bin/herdr-server"
bash -n "$ROOT/misc/.local/bin/wt-sync-deps"
printf 'ok   shell syntax\n'

python3 - <<PY
import json, plistlib
from pathlib import Path
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib
root = Path("$ROOT")

def load_toml(path):
    with path.open("rb") as f:
        return tomllib.load(f)

mise = load_toml(root / "mise.toml")
tasks = mise["tasks"]
for name in ("link", "tmux", "alacritty", "herdr", "pi", "linux", "test", "init", "tools", "ssh"):
    assert name in tasks, name
assert tasks["init"].get("alias") == "install"
assert tasks["init"]["depends"] == ["tools", "brew-packages", "ssh"]
assert tasks["linux"]["depends"][-1] == "ssh"
assert "pip freeze" not in tasks["update-installfile"]["description"]

herdr = load_toml(root / "misc/.config/herdr/config.toml")
assert herdr["keys"]["prefix"] == "ctrl+space"
assert "prefix+v" == herdr["keys"]["split_vertical"]
assert "prefix+shift+h" in herdr["keys"]["split_horizontal"]
assert herdr["terminal"]["default_shell"] == "zsh"
assert herdr["theme"]["name"] == "terminal"
assert herdr["theme"]["custom"]["accent"] == "#ff9700"
assert herdr["ui"]["tab_bar_position"] == "bottom"
assert herdr["experimental"]["pane_history"] is True

alacritty = load_toml(root / "misc/.config/alacritty/alacritty.toml")
shell = alacritty["terminal"]["shell"]
assert shell["program"] == "/bin/sh"
assert "herdr-main" in shell["args"][-1]
assert alacritty["terminal"]["osc52"] == "OnlyCopy"
assert alacritty["font"]["normal"]["family"] == "Hack"
assert alacritty["font"]["size"] == 14.0
assert alacritty["colors"]["primary"]["background"] == "#262626"
assert alacritty["colors"]["primary"]["foreground"] == "#bcbcbc"
assert alacritty["colors"]["cursor"]["cursor"] == "#a4e400"
assert alacritty["colors"]["normal"]["yellow"] == "#ff9700"
assert alacritty["selection"]["save_to_clipboard"] is True

settings = json.loads((root / "misc/.pi/agent/settings.json").read_text())
assert settings["defaultProvider"] == "claude-sdk"
assert settings["defaultModel"] == "claude-sonnet-5-5"
assert "npm:pi-claude-subscription" in settings["packages"]
assert "npm:pi-provider-antigravity" in settings["packages"]
assert "npm:pi-xai-supergrok" in settings["packages"]
assert "npm:@tintinweb/pi-subagents" in settings["packages"]
assert "npm:@ogulcancelik/pi-herdr" in settings["packages"]
sub = json.loads((root / "misc/.pi/agent/subagents.json").read_text())
assert sub["backgroundByDefault"] is True
assert sub["maxConcurrent"] >= 2
sdk = json.loads((root / "misc/.pi/agent/claude-sdk.json").read_text())
assert "pathToClaudeCodeExecutable" not in sdk
mcp = json.loads((root / "misc/.pi/agent/mcp.json").read_text())
assert mcp["mcpServers"] == {}
shortcuts = (root / "misc/.pi/agent/extensions/model-shortcuts.ts").read_text()
assert 'registerCommand("gemini"' in shortcuts
assert 'registerCommand("opus"' in shortcuts
assert "gemini-4-argon" in shortcuts
assert "claude-opus-5-5" in shortcuts
assert "antigravity" in shortcuts
assert "claude-sdk" in shortcuts

wt = load_toml(root / "misc/.config/worktrunk/config.toml")
assert wt["worktree-path"] == ".worktrees/{{ branch | sanitize }}"
assert isinstance(wt["pre-start"], list) and wt["pre-start"]
assert "wt-sync-deps" in wt["pre-start"][0]["deps"]
deps = (root / "misc/.local/bin/wt-sync-deps").read_text()
assert "wt step copy-ignored" in deps
assert "uv sync --frozen" in deps
assert "pnpm install --frozen-lockfile" in deps
assert "npm ci" in deps
ssh_client = (root / "misc/.ssh/config").read_text()
assert "PubkeyAuthentication yes" in ssh_client
assert "PasswordAuthentication no" in ssh_client
assert "IgnoreUnknown UseKeychain" in ssh_client
assert "*.ts.net" in ssh_client
sshd = (root / "install/ssh/99-dotfiles-pubkey.conf").read_text()
assert "AuthenticationMethods publickey" in sshd
assert "PasswordAuthentication no" in sshd
assert "tailscale set --ssh\n" not in sshd

for plist in (root / "install/macos").glob("*.plist"):
    with plist.open("rb") as f:
        plistlib.load(f)
print("ok   toml/json/plist")
PY

# Linker against a throwaway HOME, including paths the old regex skipped
# (misc/.tmux.conf has no extra slash, so `make link` never installed it).
LINK_HOME="$(mktemp -d)"
HOME="$LINK_HOME" bash "$ROOT/scripts/tasks.sh" link >/tmp/link.out
for path in \
  .gitconfig \
  .zshrc \
  .vimrc \
  .tmux.conf \
  .config/herdr/config.toml \
  .config/alacritty/alacritty.toml \
  .config/systemd/user/tmux.service \
  .config/systemd/user/herdr.service \
  .local/bin/tmux-clipboard \
  .local/bin/tmux-ensure \
  .local/bin/herdr-main \
  .local/bin/herdr-server \
  .pi/agent/settings.json \
  .pi/agent/subagents.json \
  .pi/agent/claude-sdk.json \
  .pi/agent/mcp.json \
  .pi/agent/extensions/model-shortcuts.ts \
  .config/worktrunk/config.toml \
  .ssh/config \
  .local/bin/wt-sync-deps \
  .hammerspoon/init.lua \
  .config/nvim/init.vim
do
  if [[ -L "$LINK_HOME/$path" ]]; then
    printf 'ok   link %s\n' "$path"
  else
    printf 'FAIL link %s\n' "$path" >&2
    fail=1
  fi
done
# Executable bits survive the symlink.
[[ -x "$LINK_HOME/.local/bin/tmux-clipboard" ]] && printf 'ok   clipboard is executable\n' \
  || { printf 'FAIL clipboard not executable\n' >&2; fail=1; }
[[ -x "$LINK_HOME/.local/bin/wt-sync-deps" ]] && printf 'ok   wt-sync-deps is executable\n' \
  || { printf 'FAIL wt-sync-deps not executable\n' >&2; fail=1; }

# Clipboard: SSH must produce OSC 52 and must not call a local tool.
FAKE_BIN="$(mktemp -d)"
cat > "$FAKE_BIN/pbcopy" <<'EOF'
#!/bin/sh
echo pbcopy >> /tmp/clip-called
cat > /tmp/clip-local
EOF
cat > "$FAKE_BIN/wl-copy" <<'EOF'
#!/bin/sh
echo wl-copy >> /tmp/clip-called
cat > /tmp/clip-local
EOF
cat > "$FAKE_BIN/xclip" <<'EOF'
#!/bin/sh
echo xclip >> /tmp/clip-called
cat > /tmp/clip-local
EOF
chmod +x "$FAKE_BIN/"*
rm -f /tmp/clip-called /tmp/clip-local
out="$(printf 'hello-ssh' | SSH_CONNECTION=1 SSH_TTY=/dev/pts/1 PATH="$FAKE_BIN:$PATH" \
  "$ROOT/misc/.local/bin/tmux-clipboard" | od -An -tx1 | tr -d ' \n')"
# ESC ] 5 2 ; c ;
if [[ "$out" == *"1b5d35323b63"* ]]; then
  printf 'ok   ssh osc52\n'
else
  printf 'FAIL ssh osc52 (%s)\n' "$out" >&2
  fail=1
fi
if [[ -f /tmp/clip-called ]]; then
  printf 'FAIL ssh invoked a local clipboard tool\n' >&2
  fail=1
else
  printf 'ok   ssh skips local clipboard\n'
fi

rm -f /tmp/clip-called /tmp/clip-local
printf 'hello-wayland' | WAYLAND_DISPLAY=wayland-0 PATH="$FAKE_BIN:$PATH" \
  "$ROOT/misc/.local/bin/tmux-clipboard" >/dev/null
if grep -qx wl-copy /tmp/clip-called && [[ "$(cat /tmp/clip-local)" == "hello-wayland" ]]; then
  printf 'ok   wayland wl-copy\n'
else
  printf 'FAIL wayland clipboard\n' >&2
  fail=1
fi

rm -f /tmp/clip-called /tmp/clip-local
printf 'hello-x' | DISPLAY=:1 PATH="$FAKE_BIN:$PATH" \
  env -u WAYLAND_DISPLAY "$ROOT/misc/.local/bin/tmux-clipboard" >/dev/null
if grep -qx xclip /tmp/clip-called && [[ "$(cat /tmp/clip-local)" == "hello-x" ]]; then
  printf 'ok   x11 xclip\n'
else
  printf 'FAIL x11 clipboard\n' >&2
  fail=1
fi

# No display and not SSH: OSC 52 fallback (Alacritty / raw tty).
rm -f /tmp/clip-called
out="$(printf 'hello-osc' | env -u WAYLAND_DISPLAY -u DISPLAY -u SSH_CONNECTION -u SSH_TTY \
  PATH="$FAKE_BIN:$PATH" "$ROOT/misc/.local/bin/tmux-clipboard" | od -An -tx1 | tr -d ' \n')"
[[ "$out" == *"1b5d35323b63"* ]] && printf 'ok   osc52 fallback\n' \
  || { printf 'FAIL osc52 fallback\n' >&2; fail=1; }
[[ -f /tmp/clip-called ]] && { printf 'FAIL fallback called a tool\n' >&2; fail=1; } \
  || printf 'ok   osc52 fallback is quiet\n'

# tmux accepts the config, plugins or not, and the options we care about stick.
if command -v tmux >/dev/null 2>&1; then
  TMUX_HOME="$(mktemp -d)"
  mkdir -p "$TMUX_HOME"
  HOME="$TMUX_HOME" bash "$ROOT/scripts/tasks.sh" link >/dev/null
  socket="dotfiles-test-$$"
  tmux_bin="$(command -v tmux)"
  if HOME="$TMUX_HOME" "$tmux_bin" -L "$socket" -f "$TMUX_HOME/.tmux.conf" start-server; then
    printf 'ok   tmux starts\n'
  else
    printf 'FAIL tmux starts\n' >&2
    fail=1
  fi
  show="$(HOME="$TMUX_HOME" "$tmux_bin" -L "$socket" show-options -g)"
  show="$show
$(HOME="$TMUX_HOME" "$tmux_bin" -L "$socket" show-options -s || true)"
  show="$show
$(HOME="$TMUX_HOME" "$tmux_bin" -L "$socket" show-options -g -s set-clipboard || true)"
  show="$show
$(HOME="$TMUX_HOME" "$tmux_bin" -L "$socket" show-options -g allow-passthrough || true)"
  showw="$(HOME="$TMUX_HOME" "$tmux_bin" -L "$socket" show-options -g -w || true)"
  for needle in \
    "prefix C-Space" \
    "status-style bg=black,fg=white" \
    "set-clipboard on" \
    "@continuum-restore on" \
    "@continuum-save-interval 5" \
    "@continuum-boot off" \
    "@resurrect-capture-pane-contents on"
  do
    if grep -F -q "$needle" <<<"$show$showw"; then
      printf 'ok   tmux %s\n' "$needle"
    else
      printf 'FAIL tmux missing %s\n' "$needle" >&2
      fail=1
    fi
  done
  # Copy binding points at the cross-platform script, not pbcopy.
  binds="$(HOME="$TMUX_HOME" "$tmux_bin" -L "$socket" list-keys -T copy-mode-vi)"
  if grep -F -q 'tmux-clipboard' <<<"$binds" && ! grep -F -q 'pbcopy' <<<"$binds"; then
    printf 'ok   tmux copy binding\n'
  else
    printf 'FAIL tmux copy binding\n' >&2
    printf '%s\n' "$binds" >&2
    fail=1
  fi
  HOME="$TMUX_HOME" "$tmux_bin" -L "$socket" kill-server || true
else
  printf 'FAIL tmux binary missing\n' >&2
  fail=1
fi

# herdr server accepts the config (no unknown-key warnings in the log).
if command -v herdr >/dev/null 2>&1; then
  HERDR_HOME="$(mktemp -d)"
  HOME="$HERDR_HOME" bash "$ROOT/scripts/tasks.sh" link >/dev/null
  HOME="$HERDR_HOME" herdr server >"$HERDR_HOME/out" 2>"$HERDR_HOME/err" &
  herdr_pid=$!
  sleep 1
  log="$HERDR_HOME/.config/herdr/herdr-server.log"
  if [[ -f "$log" ]] && grep -q "herdr server started" "$log" \
      && ! grep -Ei 'unknown key|invalid (config|value|key)|error parsing' "$log" "$HERDR_HOME/err"; then
    printf 'ok   herdr config\n'
  else
    printf 'FAIL herdr config\n' >&2
    cat "$HERDR_HOME/err" >&2 || true
    cat "$log" >&2 || true
    fail=1
  fi
  kill "$herdr_pid" >/dev/null 2>&1 || true
  wait "$herdr_pid" >/dev/null 2>&1 || true
else
  printf 'FAIL herdr binary missing\n' >&2
  fail=1
fi

# zshrc no longer sources files that do not exist on Linux.
if grep -n 'google-cloud-sdk/completion.zsh.inc' "$ROOT/zsh/.zshrc" | grep -q '\[\[ -r'; then
  printf 'ok   zshrc guards gcloud\n'
else
  # The guard is the line above the source. Accept either form.
  if grep -q '_gcloud_completion' "$ROOT/zsh/.zshrc"; then
    printf 'ok   zshrc guards gcloud\n'
  else
    printf 'FAIL zshrc gcloud source is unconditional\n' >&2
    fail=1
  fi
fi
if grep -q 'command -v thefuck' "$ROOT/zsh/.zshrc" && grep -q 'pay-respects zsh --alias fuck' "$ROOT/zsh/.zshrc"; then
  printf 'ok   zshrc guards thefuck\n'
else
  printf 'FAIL zshrc thefuck\n' >&2
  fail=1
fi
if grep -q 'command eza' "$ROOT/zsh/.zshrc" && grep -q 'command exa' "$ROOT/zsh/.zshrc"; then
  printf 'ok   zshrc eza fallback\n'
else
  printf 'FAIL zshrc eza fallback\n' >&2
  fail=1
fi
if grep -q 'darwin' "$ROOT/zsh/.zshrc" && grep -q 'plugins+=(macos sublime)' "$ROOT/zsh/.zshrc"; then
  printf 'ok   zshrc macos plugins are conditional\n'
else
  printf 'FAIL zshrc macos plugins\n' >&2
  fail=1
fi
if grep -q -- '--wt-new' "$ROOT/zsh/.zshrc" && grep -q 'wt switch --create' "$ROOT/zsh/.zshrc" \
    && grep -q 'command pi' "$ROOT/zsh/.zshrc" && grep -q 'wt config shell init zsh' "$ROOT/zsh/.zshrc"; then
  printf 'ok   zshrc pi worktrunk wrapper\n'
else
  printf 'FAIL zshrc pi worktrunk wrapper\n' >&2
  fail=1
fi

# Old make bug: appending the zsh path to /etc/shell (missing the s).
if grep -n '/etc/shell' "$ROOT/scripts/tasks.sh" | grep -v '/etc/shells' | grep -q .; then
  printf 'FAIL tasks still mention /etc/shell\n' >&2
  fail=1
else
  printf 'ok   /etc/shells spelling\n'
fi

# Dev-tool install no longer uses a global pip freeze or npm -g of Nodefile.
if grep -q 'pip3 install' "$ROOT/scripts/tasks.sh" || grep -q 'https://get.haskellstack.org' "$ROOT/scripts/tasks.sh"; then
  printf 'FAIL tasks still use pip3 or the stack installer\n' >&2
  fail=1
else
  printf 'ok   no pip3 or stack curl installer\n'
fi
if grep -q 'npm install -g $(cat' "$ROOT/scripts/tasks.sh" || grep -q 'create-react-app' "$ROOT/scripts/tasks.sh"; then
  printf 'FAIL tasks still npm-install Nodefile\n' >&2
  fail=1
else
  printf 'ok   node CLIs are not a global npm dump\n'
fi
if grep -q 'mise use -g' "$ROOT/scripts/tasks.sh" && grep -q 'uv tool install' "$ROOT/scripts/tasks.sh"; then
  printf 'ok   init uses mise and uv\n'
else
  printf 'FAIL init install path\n' >&2
  fail=1
fi
if grep -q 'gh@latest' "$ROOT/scripts/tasks.sh" && grep -q 'worktrunk@latest' "$ROOT/scripts/tasks.sh" \
    && grep -q 'aqua:tailscale/tailscale@latest' "$ROOT/scripts/tasks.sh"; then
  printf 'ok   init installs gh, worktrunk, and tailscale\n'
else
  printf 'FAIL init missing gh, worktrunk, or tailscale\n' >&2
  fail=1
fi
if grep -q -- '--ssh=false' "$ROOT/scripts/tasks.sh" && ! grep -Eq 'tailscale set --ssh($|[^.=-])' "$ROOT/scripts/tasks.sh"; then
  printf 'ok   tailscale ssh stays off\n'
else
  printf 'FAIL tailscale ssh flag\n' >&2
  fail=1
fi

sample="$(mktemp)"
filtered="$(mktemp)"
cat >"$sample" <<'EOF'
tap "homebrew/core"
tap "homebrew/cask"
tap "homebrew/bundle"
tap "homebrew/services"
tap "heroku/brew"
brew "node"
brew "node@16"
brew "python@3.9"
brew "python@3.10"
brew "exa"
brew "youtube-dl"
brew "thefuck"
brew "yarn"
brew "openjdk@8"
brew "go"
brew "pyenv"
brew "pypy3"
brew "ripgrep"
brew "heroku/brew/heroku"
cask "iterm2"
mas "Xcode", id: 497799835
EOF
(
  # shellcheck disable=SC1091
  source "$ROOT/scripts/lib.sh"
  modernize_brewfile "$sample" "$filtered"
)
for gone in 'homebrew/core' 'homebrew/cask' 'node@16' 'python@3.9' 'python@3.10' \
  '"exa"' '"youtube-dl"' '"thefuck"' '"yarn"' 'openjdk@8' '"go"' '"pyenv"' '"pypy3"' '"node"'; do
  if grep -q "$gone" "$filtered"; then
    printf 'FAIL brewfile still has %s\n' "$gone" >&2
    fail=1
  fi
done
for kept in 'tap "heroku/brew"' 'brew "ripgrep"' 'brew "heroku/brew/heroku"' 'cask "iterm2"' 'mas "Xcode", id: 497799835'; do
  if grep -qxF "$kept" "$filtered"; then
    printf 'ok   brewfile keeps %s\n' "$kept"
  else
    printf 'FAIL brewfile dropped %s\n' "$kept" >&2
    fail=1
  fi
done
if grep -q 'ruff' "$ROOT/install/uv-tools.txt" && ! grep -q '==' "$ROOT/install/uv-tools.txt"; then
  printf 'ok   uv tools manifest\n'
else
  printf 'FAIL uv tools manifest\n' >&2
  fail=1
fi

# uv-tools.txt lines become `uv tool install` arguments, comments skipped.
uv_log="$(mktemp)"
uv_home="$(mktemp -d)"
mkdir -p "$uv_home/bin" "$uv_home/install"
cat >"$uv_home/bin/uv" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$uv_log"
EOF
chmod +x "$uv_home/bin/uv"
cat >"$uv_home/install/uv-tools.txt" <<'EOF'
# comment
ruff
jupyterlab --with numpy

EOF
# shellcheck disable=SC2016
PATH="$uv_home/bin:$PATH" DOTFILES_DIR="$uv_home" bash --noprofile --norc -c '
  source "$1"
  install_uv_tools
' bash "$ROOT/scripts/tasks.sh" >"$uv_home/out" 2>"$uv_home/err" || {
  printf 'FAIL uv tool install function\n' >&2
  cat "$uv_home/err" >&2
  fail=1
}
if [[ "$(cat "$uv_log")" == $'tool install ruff\ntool install jupyterlab --with numpy' ]]; then
  printf 'ok   uv tool lines\n'
else
  printf 'FAIL uv tool lines (%s)\n' "$(cat "$uv_log" 2>/dev/null)" >&2
  fail=1
fi
rm -rf "$uv_home" "$uv_log"

# worktrunk deps: copy is best-effort, then the lockfile that is actually present.
sync_home="$(mktemp -d)"
sync_log="$sync_home/log"
mkdir -p "$sync_home/bin" "$sync_home/repo"
cat >"$sync_home/bin/wt" <<EOF
#!/bin/sh
printf '%s\n' "wt \$*" >> "$sync_log"
exit 0
EOF
cat >"$sync_home/bin/uv" <<EOF
#!/bin/sh
printf '%s\n' "uv \$*" >> "$sync_log"
case "\$*" in
  *--frozen*) exit 1 ;;
esac
exit 0
EOF
cat >"$sync_home/bin/pnpm" <<EOF
#!/bin/sh
printf '%s\n' "pnpm \$*" >> "$sync_log"
EOF
cat >"$sync_home/bin/npm" <<EOF
#!/bin/sh
printf '%s\n' "npm \$*" >> "$sync_log"
EOF
cat >"$sync_home/bin/yarn" <<EOF
#!/bin/sh
printf '%s\n' "yarn \$*" >> "$sync_log"
EOF
chmod +x "$sync_home/bin/"*
git -C "$sync_home/repo" init -q
: >"$sync_log"
(cd "$sync_home/repo" && PATH="$sync_home/bin:$PATH" bash "$ROOT/misc/.local/bin/wt-sync-deps")
if [[ "$(cat "$sync_log")" == "wt step copy-ignored" ]]; then
  printf 'ok   wt-sync-deps empty repo\n'
else
  printf 'FAIL wt-sync-deps empty repo (%s)\n' "$(cat "$sync_log")" >&2
  fail=1
fi
: >"$sync_log"
echo '{}' >"$sync_home/repo/package.json"
printf 'name: app\n' >"$sync_home/repo/pnpm-lock.yaml"
(cd "$sync_home/repo" && PATH="$sync_home/bin:$PATH" bash "$ROOT/misc/.local/bin/wt-sync-deps")
if [[ "$(cat "$sync_log")" == $'wt step copy-ignored\npnpm install --frozen-lockfile' ]]; then
  printf 'ok   wt-sync-deps pnpm\n'
else
  printf 'FAIL wt-sync-deps pnpm (%s)\n' "$(cat "$sync_log")" >&2
  fail=1
fi
rm -f "$sync_home/repo/pnpm-lock.yaml"
printf '{}\n' >"$sync_home/repo/package-lock.json"
: >"$sync_log"
(cd "$sync_home/repo" && PATH="$sync_home/bin:$PATH" bash "$ROOT/misc/.local/bin/wt-sync-deps")
if [[ "$(cat "$sync_log")" == $'wt step copy-ignored\nnpm ci' ]]; then
  printf 'ok   wt-sync-deps npm ci\n'
else
  printf 'FAIL wt-sync-deps npm ci (%s)\n' "$(cat "$sync_log")" >&2
  fail=1
fi
rm -f "$sync_home/repo/package-lock.json"
printf 'lock\n' >"$sync_home/repo/yarn.lock"
: >"$sync_log"
(cd "$sync_home/repo" && PATH="$sync_home/bin:$PATH" bash "$ROOT/misc/.local/bin/wt-sync-deps")
if [[ "$(cat "$sync_log")" == $'wt step copy-ignored\nyarn install --frozen-lockfile' ]]; then
  printf 'ok   wt-sync-deps yarn classic\n'
else
  printf 'FAIL wt-sync-deps yarn classic (%s)\n' "$(cat "$sync_log")" >&2
  fail=1
fi
printf 'nodeLinker: node-modules\n' >"$sync_home/repo/.yarnrc.yml"
: >"$sync_log"
(cd "$sync_home/repo" && PATH="$sync_home/bin:$PATH" bash "$ROOT/misc/.local/bin/wt-sync-deps")
if [[ "$(cat "$sync_log")" == $'wt step copy-ignored\nyarn install --immutable' ]]; then
  printf 'ok   wt-sync-deps yarn berry\n'
else
  printf 'FAIL wt-sync-deps yarn berry (%s)\n' "$(cat "$sync_log")" >&2
  fail=1
fi
rm -f "$sync_home/repo/yarn.lock" "$sync_home/repo/.yarnrc.yml" "$sync_home/repo/pnpm-lock.yaml" \
  "$sync_home/repo/package-lock.json"
: >"$sync_log"
(cd "$sync_home/repo" && PATH="$sync_home/bin:$PATH" bash "$ROOT/misc/.local/bin/wt-sync-deps")
if [[ "$(cat "$sync_log")" == $'wt step copy-ignored\nnpm install' ]]; then
  printf 'ok   wt-sync-deps npm install\n'
else
  printf 'FAIL wt-sync-deps npm install (%s)\n' "$(cat "$sync_log")" >&2
  fail=1
fi
mkdir -p "$sync_home/repo/node_modules"
: >"$sync_log"
(cd "$sync_home/repo" && PATH="$sync_home/bin:$PATH" bash "$ROOT/misc/.local/bin/wt-sync-deps")
if [[ "$(cat "$sync_log")" == "wt step copy-ignored" ]]; then
  printf 'ok   wt-sync-deps keeps copied node_modules\n'
else
  printf 'FAIL wt-sync-deps keeps copied node_modules (%s)\n' "$(cat "$sync_log")" >&2
  fail=1
fi
printf 'uv\n' >"$sync_home/repo/uv.lock"
mkdir -p "$sync_home/repo/.venv/bin"
printf '#!/bin/sh\n' >"$sync_home/repo/.venv/bin/python"
chmod +x "$sync_home/repo/.venv/bin/python"
: >"$sync_log"
(cd "$sync_home/repo" && PATH="$sync_home/bin:$PATH" bash "$ROOT/misc/.local/bin/wt-sync-deps")
if [[ "$(cat "$sync_log")" == "wt step copy-ignored" ]]; then
  printf 'ok   wt-sync-deps keeps copied venv\n'
else
  printf 'FAIL wt-sync-deps keeps copied venv (%s)\n' "$(cat "$sync_log")" >&2
  fail=1
fi
rm -rf "$sync_home/repo/.venv"
: >"$sync_log"
(cd "$sync_home/repo" && PATH="$sync_home/bin:$PATH" bash "$ROOT/misc/.local/bin/wt-sync-deps")
if [[ "$(cat "$sync_log")" == $'wt step copy-ignored\nuv sync --frozen\nuv sync' ]]; then
  printf 'ok   wt-sync-deps uv sync falls back\n'
else
  printf 'FAIL wt-sync-deps uv (%s)\n' "$(cat "$sync_log")" >&2
  fail=1
fi
rm -rf "$sync_home"
rm -f "$sample" "$filtered"

rm -rf "$LINK_HOME"
exit "$fail"
