# .files

Dotfiles for macOS and Linux. The personal Homebrew tap is
[weixuanz/moonshine](https://github.com/WeixuanZ/homebrew-moonshine).

Tasks are [mise](https://mise.jdx.dev) tasks (`mise.toml`). `make` still
works; it just calls mise.

```sh
curl https://mise.run | sh          # once
mise run                            # symlink configs into $HOME
mise run init                       # dev tools (alias: install)
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

## What gets installed

Three hand-written lists, top-level packages only:

| File | Installs | Task |
| --- | --- | --- |
| `misc/.config/mise/config.toml` | Dev toolchains and CLIs on macOS and Linux: Node, Python, Go, Java, uv, pnpm, yarn, gh, terraform, ruff, prettier, ... | `mise run tools` |
| `install/Brewfile` | Homebrew command-line packages | `mise run brew-packages` |
| `install/Appfile` | macOS casks and App Store apps | `mise run apps` |

`mise run init` (alias `install`) runs the first two and `mise run ssh`.
The mise file is linked to `~/.config/mise/config.toml`, so `mise use -g`
edits it in place. `mise run brew-check` lists what this machine has that the
Homebrew lists do not, and the reverse. `mise run haskell` is a separate
GHCup bootstrap for GHC, Cabal, Stack, and HLS.

The Tailscale CLI from mise does not start the tunnel. On macOS, `tools`
installs the Tailscale cask; on Linux, the distro `tailscaled`. Then
`sudo tailscale up`. Open a new shell after `init` so `mise activate` in
`.zshrc` picks up the tools.

Machine-specific settings stay out of the repo, in files the tracked configs
include: `~/.gitconfig.local` (name, email, signing key) and
`~/.ssh/config.local` (hosts).

## SSH and Tailscale

`mise run ssh` (also part of `mise run init` and `mise run linux`) links
`~/.ssh/config` and, with sudo, installs
`/etc/ssh/sshd_config.d/99-dotfiles-pubkey.conf`.

Both sides are public-key only: the client will not offer a password, and
sshd accepts `AuthenticationMethods publickey`. An existing `~/.ssh/config`
that is not already a symlink is renamed to `~/.ssh/config.orig`.

Tailscale is only the network. MagicDNS names (`host.tailnet.ts.net`) are
opened with the system `ssh`, not `tailscale ssh`. The task runs
`tailscale set --ssh=false` so Tailscale's own SSH server does not take port
22 on the tailnet address. Log in with `sudo tailscale up` if it has not
been turned off yet, then run `mise run ssh` again.

## worktrunk

`~/.config/worktrunk/config.toml` puts worktrees in
`.worktrees/<branch>`. Creating one runs `~/.local/bin/wt-sync-deps` before
`wt switch -x` returns:

1. `wt step copy-ignored` copies gitignored files (`node_modules`, `.venv`,
   `.env`) with copy-on-write where the filesystem supports it.
2. If that copy did not leave a usable tree, the script installs from the
   lockfile it finds: `uv sync` for Python, then pnpm, `npm ci`, Yarn, or
   `npm install`.

`.zshrc` loads `wt config shell init zsh` and wraps `pi`:

```sh
pi --wt feature-a              # existing branch, then pi in that worktree
pi --wt-new feature-a 'prompt' # create the branch and worktree, then pi
```

## Editor

`misc/.config/zed` is Zed in vim mode, with `vim/.vimrc`'s options and
leader (Space) bindings mapped to Zed actions. On macOS, `mise run editor`
installs Zed and [Syntax Highlight](https://github.com/sbarex/SourceCodeSyntaxHighlight),
makes Zed the app Finder opens code and text files with, and turns on
syntax-highlighted Quick Look previews (Space in Finder). No confirmation
dialogs: `scripts/default-editor.py` writes the LaunchServices handlers
directly, for both the file type and the extension.

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

## Claude Code

`mise run claude` installs Claude Code if it is missing and the
[claude-hud](https://github.com/jarrodwatts/claude-hud) plugin, then points
the status line at it: model, git branch, context used, and plan usage
limits under the prompt. It adds only `statusLine` to
`~/.claude/settings.json`. `/claude-hud:configure` turns on the tools,
agents, and todo lines.

## pi

`~/.pi/agent/settings.json` selects the Claude subscription (not an API key)
as the default, and installs the other subscription providers next to it.
Nothing in this repo stores an API key.

| Package | What it does |
| --- | --- |
| `pi-claude-subscription` | Claude models through the Claude Code login (`claude-sdk/claude-sonnet-5-5`). Log in once with `claude`, then run `pi`. |
| `pi-provider-antigravity` | Gemini on a Google AI Pro or Ultra plan. `/login antigravity`, then `/gemini` (Gemini 4, `gemini-4-argon`). |
| `pi-xai-supergrok` | SuperGrok or X Premium+. `/login supergrok`. Models are the live `grok-*` catalog. Do not export `XAI_API_KEY` if you want plan billing. |
| `@tintinweb/pi-subagents` | Subagents run in the background (`backgroundByDefault`) and in parallel, up to 8 at once. |
| `@ogulcancelik/pi-herdr` | Inside herdr, pi gets a `herdr` tool for panes, tabs, and workspaces. `mise run herdr` also installs herdr's own pi integration. |

Inside a session, `/opus` switches to `claude-opus-5-5` and `/gemini` switches
to Gemini 4. `/model` still lists everything those logins expose.

MCP is built in. `~/.pi/agent/mcp.json` starts empty so no server is spawned
until you add one. `pi mcp add <name> -- <command...>` writes that file;
project servers go in `.pi/mcp.json` after the project is trusted. `/mcp`
shows what is connected.

`mise run pi` installs pi and downloads the packages. Do not export
`ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, or `XAI_API_KEY` in that shell if you
want the subscriptions rather than API billing.

## Layout

Approach borrowed from [webpro/dotfiles](https://github.com/webpro/dotfiles)
and [jessfraz/dotfiles](https://github.com/jessfraz/dotfiles). Other credits
are in the files they came from.
