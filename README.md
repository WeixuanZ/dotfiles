# .files

Dotfiles for macOS and Linux. The personal Homebrew tap is
[weixuanz/moonshine](https://github.com/WeixuanZ/homebrew-moonshine).

Tasks are [mise](https://mise.jdx.dev) tasks (`mise.toml`). `make` still
works; it just calls mise.

```sh
curl https://mise.run | sh          # once
mise run                            # symlink configs into $HOME
mise tasks                          # everything else
```

Existing files that are not already symlinks are renamed with a `.orig`
suffix.

On a fresh Linux machine the terminal stack is one task:

```sh
mise run linux
```

That links configs, installs zsh, tmux (resurrect + continuum), the Hack
font, herdr, and the pi coding agent. iTerm2 and Hammerspoon stay macOS-only
(`mise run iterm2`, `mise run hammerspoon`).

## Terminal

iTerm2 (macOS) and Alacritty (Linux) both use the monokai tasty colours from
`iterm2/com.googlecode.iterm2.plist`. Alacritty uses Hack at 14pt and opens
the herdr session named `main`. vim still uses
[monokai-tasty](https://github.com/patstockwell/vim-monokai-tasty).

tmux and herdr share the same prefix, `Ctrl-Space`, and the same vim keys:
`prefix v` / `prefix H` to split, `h j k l` to move, `prefix c` for a new
tab, `prefix R` to reload. Herdr's one deliberate difference: `prefix q`
detaches (and `prefix d` does too). Herdr has no tmux-style pane-number
overlay; `prefix g` is the goto chooser.

Copy works the same locally and over SSH. tmux writes OSC 52, and also uses
`pbcopy` (macOS), `wl-copy` (Wayland), or `xclip` (X11) when those are the
clipboard in front of you. Alacritty accepts OSC 52 copy and does not let
remote programs read the clipboard.

tmux-continuum saves the session every 5 minutes. The next time the tmux
server starts, including after a reboot, it restores that snapshot. Linux
starts the server from `~/.config/systemd/user/tmux.service`. macOS uses a
LaunchAgent. Herdr's own server is `herdr.service` / a LaunchAgent, and it
resumes agent panes that have an official integration.

## pi

`~/.pi/agent/settings.json` selects the Claude subscription (not an API key)
and two plugins:

| Package | What it does |
| --- | --- |
| `pi-claude-subscription` | Claude models through the Claude Code login (`claude-sdk/claude-sonnet-5-5`). Log in once with `claude`, then run `pi`. Do not export `ANTHROPIC_API_KEY` in that shell if you want plan billing. |
| `@tintinweb/pi-subagents` | Subagents run in the background (`backgroundByDefault`) and in parallel, up to 8 at once. |
| `@ogulcancelik/pi-herdr` | Inside herdr, pi gets a `herdr` tool for panes, tabs, and workspaces. `mise run herdr` also installs herdr's own pi integration. |

`mise run pi` installs pi and downloads those packages.

## Layout

Approach borrowed from [webpro/dotfiles](https://github.com/webpro/dotfiles)
and [jessfraz/dotfiles](https://github.com/jessfraz/dotfiles). Other credits
are in the files they came from.
