#!/usr/bin/env bash
# mise task bodies. Invoked as `scripts/tasks.sh <task>`.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# The mise package is the CLI. The tunnel is a system daemon: the Mac app, or
# tailscaled from the distro package. Tailscale SSH stays off; system sshd
# owns port 22, including on the tailnet address (`mise run ssh`).
install_tailscale_daemon() {
  if is-macos; then
    if is-executable brew; then
      if ! brew list --cask tailscale >/dev/null 2>&1; then
        brew install --cask tailscale || warn "brew cask tailscale failed; install the Tailscale Mac app"
      fi
    else
      warn "Homebrew is not installed; install the Tailscale Mac app, then run: mise run ssh"
    fi
    return 0
  fi
  if grep -q tailscaled <<<"$(systemctl list-unit-files --no-legend tailscaled.service 2>/dev/null)"; then
    return 0
  fi
  if [[ -x /usr/sbin/tailscaled || -x /usr/bin/tailscaled ]]; then
    return 0
  fi
  info "Installing the Tailscale system daemon"
  curl -fsSL https://tailscale.com/install.sh | sh || warn "Tailscale install script failed. See https://tailscale.com/download/linux"
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

# Dev tools are declared in misc/.config/mise/config.toml (~/.config/mise).
task_tools() {
  mise install
  install_tailscale_daemon
}

task_brew_packages() {
  task_brew
  brew bundle --file "$DOTFILES_DIR/install/Brewfile"
}

task_apps() {
  is-macos || die "Not macOS"
  task_brew
  brew bundle --file "$DOTFILES_DIR/install/Appfile"
}

# The lists are curated by hand. This shows how this machine differs from them.
task_brew_check() {
  local all
  all="$(mktemp)"
  cat "$DOTFILES_DIR/install/Brewfile" >"$all"
  is-macos && cat "$DOTFILES_DIR/install/Appfile" >>"$all"
  info "Listed but not installed:"
  brew bundle check --verbose --no-upgrade --file "$all" || true
  info "Installed but not listed (add them, or remove with --force):"
  brew bundle cleanup --file "$all" || true
  rm -f "$all"
}

# Zed opens code files from Finder; Syntax Highlight previews them on Space.
# Zed's config is misc/.config/zed, linked by `mise run link`.
task_editor() {
  is-macos || die "Not macOS"
  task_brew
  is-installed Zed || brew install --cask zed
  is-installed "Syntax Highlight" || brew install --cask syntax-highlight
  local prefs=com.apple.LaunchServices/com.apple.launchservices.secure
  local tmp
  tmp="$(mktemp -d)"
  defaults export "$prefs" "$tmp/old.plist"
  python3 -I "$DOTFILES_DIR/scripts/default-editor.py" dev.zed.Zed <"$tmp/old.plist" >"$tmp/new.plist"
  defaults import "$prefs" "$tmp/new.plist"
  rm -rf "$tmp"
  killall lsd 2>/dev/null || true
  pluginkit -a "/Applications/Syntax Highlight.app/Contents/PlugIns/Syntax Highlight Quick Look Extension.appex"
  pluginkit -e use -i org.sbarex.SourceCodeSyntaxHighlight.QuickLookExtension
  qlmanage -r >/dev/null
  ok "Zed opens code files; Space previews them with syntax highlighting"
}

task_zsh() {
  task_brew
  is-brew-package zsh || brew install zsh
  [[ -d "$HOME/.oh-my-zsh" ]] || ZSH= sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
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
      die "tmux is not installed. Run: mise run link && mise install"
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
  if ! grep -qi hack <<<"$(fc-list 2>/dev/null)"; then
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

task_ssh() {
  create_symlink "$DOTFILES_DIR/misc/.ssh/config" "$HOME/.ssh/config"
  local drop_src="$DOTFILES_DIR/install/ssh/99-dotfiles-pubkey.conf"
  local drop_dest="/etc/ssh/sshd_config.d/99-dotfiles-pubkey.conf"
  local sshd_config="/etc/ssh/sshd_config"
  if ! is-executable sudo; then
    warn "no sudo; client config is linked. Install the server drop-in with: sudo cp $drop_src $drop_dest"
  elif ! sudo mkdir -p /etc/ssh/sshd_config.d || ! sudo cp "$drop_src" "$drop_dest"; then
    warn "could not install $drop_dest"
  else
    sudo chmod 644 "$drop_dest" || true
    if [[ -f "$sshd_config" ]] && ! grep -qE '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf' "$sshd_config"; then
      echo 'Include /etc/ssh/sshd_config.d/*.conf' | sudo tee -a "$sshd_config" >/dev/null \
        || warn "could not add the sshd Include line"
    fi
    if is-macos; then
      if is-executable systemsetup; then
        sudo systemsetup -setremotelogin on || warn "could not enable Remote Login (System Settings → General → Sharing)"
      fi
      sudo launchctl kickstart -k system/com.openssh.sshd || warn "could not restart sshd"
    elif systemctl cat ssh.service >/dev/null 2>&1; then
      sudo systemctl reload ssh || sudo systemctl try-reload-or-restart ssh || warn "could not reload ssh"
    elif systemctl cat sshd.service >/dev/null 2>&1; then
      sudo systemctl reload sshd || sudo systemctl try-reload-or-restart sshd || warn "could not reload sshd"
    else
      warn "sshd drop-in is installed; no ssh.service or sshd.service to reload"
    fi
  fi
  # `--ssh=false` is the whole point: Tailscale must not intercept port 22.
  if command -v tailscale >/dev/null 2>&1; then
    if ! tailscale set --ssh=false; then
      warn "Tailscale SSH was not turned off. Log in with 'sudo tailscale up', then re-run. Do not enable Tailscale SSH."
    fi
  fi
  ok "SSH is public-key only. Use system ssh, for example: ssh host.tailnet.ts.net"
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
  # shellcheck disable=SC2016
  ok 'pi ready. Log in with `claude` once, then `/login antigravity` and `/login supergrok` inside pi.'
}

# Claude Code with the claude-hud status line (context, usage, tools, agents).
# setup.mjs adds only `statusLine` to ~/.claude/settings.json, through a
# launcher that runs the newest installed claude-hud, so updates need no rerun.
task_claude() {
  if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash
    export PATH="$HOME/.local/bin:$PATH"
  fi
  grep -q claude-hud <<<"$(claude plugin marketplace list)" \
    || claude plugin marketplace add jarrodwatts/claude-hud
  grep -q claude-hud@claude-hud <<<"$(claude plugin list)" \
    || claude plugin install claude-hud@claude-hud
  local runtime root
  runtime="$(command -v bun || command -v node)" || die "claude-hud needs Node.js. Run: mise run tools"
  root="$(ls -td "$HOME"/.claude/plugins/cache/claude-hud/claude-hud/*/)"
  "$runtime" "${root%%$'\n'*}scripts/setup.mjs" install --shell posix
  ok "claude-hud is the Claude Code status line. Customize with /claude-hud:configure"
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
    brew-check) task_brew_check ;;
    tools) task_tools ;;
    brew-packages) task_brew_packages ;;
    apps) task_apps ;;
    editor) task_editor ;;
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
    claude) task_claude ;;
    ssh) task_ssh ;;
    ""|-h|--help|help) usage ;;
    *) die "unknown task: $cmd" ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
