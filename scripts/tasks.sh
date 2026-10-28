#!/usr/bin/env bash
# mise task bodies. Invoked as `scripts/tasks.sh <task>`.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

install_uv_tools() {
  local file="$DOTFILES_DIR/install/uv-tools.txt"
  local line
  [[ -f "$file" ]] || die "missing $file"
  command -v uv >/dev/null 2>&1 || die "uv is not on PATH. Run: mise run init"
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    info "uv tool install $line"
    # The line is a package name plus optional `uv tool install` arguments.
    # shellcheck disable=SC2086
    uv tool install $line
  done <"$file"
}

# Language runtimes and the CLIs that replaced brew's abandoned formulae.
# Installed into the global mise config so a new shell can see them, not only
# this task. Python CLIs are uv tools (isolated). JS CLIs are mise npm tools,
# not `npm install -g`.
DEV_TOOLS=(
  node@lts
  python@3.14
  go@1
  java@lts
  uv@latest
  eza@latest
  yt-dlp@latest
  aqua:iffse/pay-respects@latest
  npm:typescript@latest
  npm:prettier@latest
  npm:eslint@latest
)

task_tools() {
  info "Installing dev tools into ~/.config/mise/config.toml"
  MISE_YES=1 mise use -g "${DEV_TOOLS[@]}"
  hash -r || true
  # This process started before those shims existed.
  eval "$(mise activate bash)"
  if command -v corepack >/dev/null 2>&1; then
    corepack enable || warn "corepack enable failed"
    corepack prepare pnpm@latest --activate || warn "could not activate pnpm via corepack"
    corepack prepare yarn@stable --activate || warn "could not activate yarn via corepack"
  else
    warn "corepack is not on this node; pnpm and yarn were not activated"
  fi
  install_uv_tools
  ok "dev tools ready: node $(node --version), python $(python --version)"
}

task_link() {
  local file rel top dest
  git -C "$DOTFILES_DIR" ls-files | while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    dest=""
    if [[ "$file" == misc/* ]]; then
      rel="${file#misc/}"
      top="${rel%%/*}"
      # misc/.tmux.conf, misc/.config/..., misc/.local/bin/..., misc/.pi/...
      [[ "$top" == .* ]] || continue
      dest="$HOME/$rel"
    elif [[ "$file" == .* || "$file" == */.* ]]; then
      # .gitconfig -> ~/.gitconfig, zsh/.zshrc -> ~/.zshrc
      dest="$HOME/.${file#*.}"
    else
      continue
    fi
    create_symlink "$DOTFILES_DIR/$file" "$dest"
  done
  ok "linked dotfiles into $HOME"
}

task_brew() {
  if ! is-executable brew; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if ! is-macos; then
      # Single quotes so the shell that later reads .profile expands this,
      # not the shell running this task. (The old Makefile expanded it early.)
      # shellcheck disable=SC2016
      echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.profile"
    fi
  fi
}

task_update_brewfile() {
  task_brew
  local dump raw_brew raw_app
  dump="$(mktemp)"
  raw_brew="$(mktemp)"
  raw_app="$(mktemp)"
  (cd "$DOTFILES_DIR" && brew bundle dump --force --file "$dump")
  grep -E '^(tap|brew)[[:space:]]' "$dump" >"$raw_brew" || true
  grep -E '^(tap|cask|mas)[[:space:]]' "$dump" >"$raw_app" || true
  modernize_brewfile "$raw_brew" "$DOTFILES_DIR/install/Brewfile"
  modernize_brewfile "$raw_app" "$DOTFILES_DIR/install/Appfile"
  echo '# vim: syntax=brewfile' >>"$DOTFILES_DIR/install/Appfile"
  rm -f "$dump" "$raw_brew" "$raw_app"
}

task_update_installfile() {
  command -v uv >/dev/null 2>&1 || die "uv is not on PATH. Run: mise run init"
  info "Installed uv tools (edit install/uv-tools.txt by hand; a dump would drop --with flags):"
  uv tool list
}

task_brew_packages() {
  task_brew
  local filtered
  filtered="$(mktemp)"
  modernize_brewfile "$DOTFILES_DIR/install/Brewfile" "$filtered"
  brew bundle --file "$filtered"
  rm -f "$filtered"
}

task_python_packages() {
  # Kept as a name. The global pip freeze in install/Pythonfile is not installed.
  task_tools
}

task_node_packages() {
  # Kept as a name. install/Nodefile is not passed to npm install -g.
  task_tools
}

task_packages() {
  task_tools
  task_brew_packages
}

task_apps() {
  is-macos || die "Not macOS"
  task_brew
  local quicklook="$HOME/Library/QuickLook"
  is-brew-package mas || brew install mas
  local filtered
  filtered="$(mktemp)"
  modernize_brewfile "$DOTFILES_DIR/install/Appfile" "$filtered"
  brew bundle --file "$filtered"
  rm -f "$filtered"
  if [[ -d "$quicklook" ]]; then
    xattr -d -r com.apple.quarantine "$quicklook" || true
  fi
}

task_zsh() {
  task_brew
  is-brew-package zsh || brew install zsh
  ZSH= sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  local plugin theme
  local plugins=(
    jeffreytse/zsh-vi-mode
    MichaelAquilina/zsh-autoswitch-virtualenv
    zsh-users/zsh-autosuggestions
    zsh-users/zsh-syntax-highlighting
    Aloxaf/fzf-tab
  )
  mkdir -p "$custom/plugins" "$custom/themes"
  for plugin in "${plugins[@]}"; do
    local name="${plugin##*/}"
    if [[ ! -d "$custom/plugins/$name" ]]; then
      info "Cloning $plugin"
      git clone --depth=1 --quiet "https://github.com/$plugin" "$custom/plugins/$name"
    fi
  done
  if [[ -d "$custom/plugins/zsh-autoswitch-virtualenv" && ! -e "$custom/plugins/autoswitch_virtualenv" ]]; then
    mv "$custom/plugins/zsh-autoswitch-virtualenv" "$custom/plugins/autoswitch_virtualenv"
  fi
  theme="denysdovhan/spaceship-prompt"
  if [[ ! -d "$custom/themes/spaceship-prompt" ]]; then
    info "Cloning $theme"
    git clone --depth=1 --quiet "https://github.com/$theme" "$custom/themes/spaceship-prompt"
  fi
  ln -sfn "$custom/themes/spaceship-prompt/spaceship.zsh-theme" "$custom/themes/spaceship.zsh-theme"
  tic "$DOTFILES_DIR/zsh/terminfo"
  create_symlink "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  if ! is-macos; then
    local zsh_path
    zsh_path="$(command -v zsh)"
    if [[ -n "$zsh_path" ]] && ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
  fi
}

task_vim() {
  task_brew
  is-brew-package vim || brew install vim
  create_symlink "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"
  mkdir -vp "$HOME/.vim/undo"
  curl -fLso "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  vim +PlugInstall +qall
  local file filename
  git -C "$DOTFILES_DIR" ls-files | { grep -E '^vim/[^.][^/]*/.+' || true; } | while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    filename="${file#vim/}"
    mkdir -p "$HOME/.vim/${filename%/*}"
    create_symlink "$DOTFILES_DIR/$file" "$HOME/.vim/$filename"
  done
}

task_vim_ycm() {
  task_vim
  task_brew_packages
  local dir="$HOME/.vim/plugged/youcompleteme"
  (cd "$dir" && git submodule update --init --recursive)
  python3 "$dir/install.py" --all
}

task_iterm2() {
  is-macos || die "Not macOS"
  task_brew
  is-installed iTerm || brew install iterm2
  local tmp
  tmp="$(mktemp -d)"
  curl -fLso "$tmp/font.zip" https://download.jetbrains.com/fonts/JetBrainsMono-2.225.zip
  unzip -o "$tmp/font.zip" -d "$tmp/out"
  mkdir -p "$HOME/Library/Fonts"
  mv "$tmp"/out/fonts/ttf/* "$HOME/Library/Fonts/"
  rm -rf "$tmp"
  defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$DOTFILES_DIR/iterm2/"
  defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
  open -a "iTerm"
}

task_hammerspoon() {
  is-macos || die "Not macOS"
  task_brew
  task_link
  is-installed hammerspoon || brew install hammerspoon
  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/installer" https://raw.githubusercontent.com/dbalatero/VimMode.spoon/master/bin/installer
  bash "$tmp/installer"
  rm -rf "$tmp"
}

task_haskell() {
  # One GHCup bootstrap. Stack's old standalone installer is not used; Stack
  # and HLS come from GHCup.
  if ! is-executable ghcup && [[ ! -x "$HOME/.ghcup/bin/ghcup" ]]; then
    curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org \
      | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
        BOOTSTRAP_HASKELL_GHC_VERSION=recommended \
        BOOTSTRAP_HASKELL_CABAL_VERSION=recommended \
        BOOTSTRAP_HASKELL_INSTALL_STACK=1 \
        BOOTSTRAP_HASKELL_INSTALL_HLS=1 \
        BOOTSTRAP_HASKELL_ADJUST_BASHRC=1 \
        sh
  fi
  if [[ -f "$HOME/.ghcup/env" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.ghcup/env"
  fi
  is-executable ghcup || die "ghcup is not on PATH after bootstrap"
  ghcup install ghc recommended
  ghcup set ghc recommended
  ghcup install cabal recommended
  ghcup set cabal recommended
  ghcup install stack recommended
  ghcup set stack recommended
  ghcup install hls recommended
  ghcup set hls recommended
  ok "GHC, Cabal, Stack, and HLS installed with GHCup"
}

task_tmux() {
  if ! command -v tmux >/dev/null 2>&1; then
    if is-executable brew; then
      brew install tmux
    else
      die "tmux is not installed. On Linux: mise use -g tmux@3.7c, or your distro package."
    fi
  fi
  local tpm="$HOME/.tmux/plugins/tpm"
  if [[ ! -x "$tpm/tpm" ]]; then
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm"
  fi
  # TPM reads @plugin lines from the config and clones them.
  if [[ ! -f "$HOME/.tmux.conf" ]]; then
    die "~/.tmux.conf is missing. Run: mise run link"
  fi
  "$tpm/bin/install_plugins"
  if is-macos; then
    install_launch_agent "$DOTFILES_DIR/install/macos/com.weixuanz.tmux-ensure.plist" \
      com.weixuanz.tmux-ensure
  else
    enable_user_unit tmux.service
  fi
  ok "tmux plugins installed; continuum saves every 5 minutes and restores on server start"
}

task_alacritty() {
  local font_dir="$HOME/.local/share/fonts/Hack"
  if ! fc-list 2>/dev/null | grep -qi 'hack'; then
    local tmp
    tmp="$(mktemp -d)"
    info "Installing the Hack font into $font_dir"
    curl -fLso "$tmp/hack.zip" \
      https://github.com/source-foundry/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip
    unzip -q -o "$tmp/hack.zip" -d "$tmp/hack"
    mkdir -p "$font_dir"
    find "$tmp/hack" -name '*.ttf' -exec cp {} "$font_dir/" \;
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -f "$HOME/.local/share/fonts" || true
    fi
    rm -rf "$tmp"
  fi
  if ! command -v alacritty >/dev/null 2>&1; then
    if is-executable brew; then
      brew install alacritty || warn "brew install alacritty failed"
    else
      warn "alacritty is not installed. The config is linked; install the package from your distro or Homebrew."
    fi
  fi
  ok "Alacritty config is ~/.config/alacritty/alacritty.toml (Hack, monokai tasty, herdr main)"
}

task_herdr() {
  if ! command -v herdr >/dev/null 2>&1; then
    curl -fsSL https://herdr.dev/install.sh | sh
  fi
  # The integration writes ~/.pi/agent/extensions/herdr-agent-state.ts.
  # That directory exists once `mise run link` has symlinked the pi config.
  if [[ -d "$HOME/.pi/agent" ]]; then
    herdr integration install pi || warn "herdr integration install pi failed"
  else
    warn "~/.pi/agent is missing. Run: mise run link && mise run herdr"
  fi
  if is-macos; then
    install_launch_agent "$DOTFILES_DIR/install/macos/com.weixuanz.herdr-server.plist" \
      com.weixuanz.herdr-server
  else
    enable_user_unit herdr.service
  fi
  ok "herdr installed; session 'main' is what Alacritty attaches"
}

task_pi() {
  if ! command -v pi >/dev/null 2>&1; then
    if command -v npm >/dev/null 2>&1; then
      npm install -g @earendil-works/pi-coding-agent
    else
      die "pi is not installed and npm is not on PATH. Run: mise run init"
    fi
  fi
  # settings.json already declares the packages. This downloads them.
  pi update --extensions
  if command -v herdr >/dev/null 2>&1; then
    herdr integration install pi || warn "herdr integration install pi failed"
  fi
  cat <<'EOF'
pi is configured for the Claude subscription via pi-claude-subscription.

  1. claude          # /login once with your Claude Pro/Max account
  2. pi              # starts on claude-sdk / claude-sonnet-5-5

Do not export ANTHROPIC_API_KEY in the same shell if you want plan billing.
The package strips that variable from the Claude Code subprocess, but an API
key set for other tools is still an API key.

Subagents (@tintinweb/pi-subagents) run in the background by default, up to
8 at once. Inside herdr, @ogulcancelik/pi-herdr adds the herdr tool.
EOF
}

usage() {
  cat <<'EOF'
usage: scripts/tasks.sh <task>

Tasks are normally started with mise (`mise tasks`, `mise run link`).
EOF
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    link) task_link ;;
    brew) task_brew ;;
    update-brewfile) task_update_brewfile ;;
    update-installfile) task_update_installfile ;;
    brew-packages) task_brew_packages ;;
    python-packages) task_python_packages ;;
    node-packages) task_node_packages ;;
    packages|init|install) task_packages ;;
    apps) task_apps ;;
    zsh) task_zsh ;;
    vim) task_vim ;;
    vim-ycm) task_vim_ycm ;;
    iterm2) task_iterm2 ;;
    hammerspoon) task_hammerspoon ;;
    haskell) task_haskell ;;
    tmux) task_tmux ;;
    alacritty) task_alacritty ;;
    herdr) task_herdr ;;
    pi) task_pi ;;
    ""|-h|--help|help) usage ;;
    *) die "unknown task: $cmd" ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
