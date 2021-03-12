# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="agnoster"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
 ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
 COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
 DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

################################################################

# zsh-apple-touchbar

plugins=(vi-mode z zsh-autosuggestions zsh-syntax-highlighting sublime osx git colored-man-pages autoswitch_virtualenv docker docker-compose)


################################################################

# # Homebew shell completion
# if type brew &>/dev/null; then
#   FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH

#   autoload -Uz compinit
#   compinit
# fi


# ZSH_DISABLE_COMPFIX="true"

source $ZSH/oh-my-zsh.sh

# User configuration

export TERM=xterm-256color-italic
export BAT_THEME="Solarized (dark)"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=236'
# ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion)

# ccat output colour style
ZSH_COLORIZE_STYLE="solarized-dark"

# for the autoswitch_virtualenv plugin, specifies where the virtualenvs are created by default
AUTOSWITCH_VIRTUAL_ENV_DIR="$HOME/.virtualenvs"


# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias zshconfig="sudo subl ~/.zshrc"
alias brewlistd="brew list -1 | while read cask; do echo -ne \$fg[blue] \$cask \$fg[white]; brew uses \$cask --installed | awk '{printf(\" %s \", \$0)}'; echo \"\"; done"
alias cat='bat --paging=never'
alias wordcount="find . -name '*.md' -type f -exec wc -w {} + | tail -n1"
alias gatekeeper="$HOME/.oh-my-zsh/custom/GateKeeper_Helper.command"
alias -g Z='| fzf'
# alias ohmyzsh="mate ~/.oh-my-zsh"

function matlab {
    /Applications/MATLAB_R2020b.app/bin/matlab -nodesktop -nosplash $*
}

function latexinit {
    cp ~/Code/wex/wex.cls .
    cp ~/Code/wex/.gitignore .
    echo "\\\\documentclass[]{wex}\n\\\\title{DefaultTitle}\n\n\n\\\\begin{document}\n\\\\wextitle\n\n\n\\\\end{document}" >> ${1:-report}.tex
    echo "*.tex" >> .tabnineignore
    subl -n -a . ${1:-report}.tex
}

# etc

# for subl to work
export PATH="/usr/local/sbin:$PATH"
# set sublime text as the degault editor
export EDITOR='subl -w'

# iTerm2 shell integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

[ -f "${GHCUP_INSTALL_BASE_PREFIX:=$HOME}/.ghcup/env" ] && source "${GHCUP_INSTALL_BASE_PREFIX:=$HOME}/.ghcup/env"

# heroku autocomplete setup
HEROKU_AC_ZSH_SETUP_PATH=$HOME/Library/Caches/heroku/autocomplete/zsh_setup && test -f $HEROKU_AC_ZSH_SETUP_PATH && source $HEROKU_AC_ZSH_SETUP_PATH;

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Tikzit
export PATH="$PATH:/Applications/TikZiT.app/Contents/MacOS"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# like normal z when used with arguments but displays an fzf prompt when used without.
unalias z 2> /dev/null
z() {
    [ $# -gt 0 ] && _z "$*" && return
    cd "$(_z -l 2>&1 | fzf --height 40% --nth 2.. --reverse --inline-info +s --tac --query "${*##-* }" | sed 's/^[0-9,.]* *//')"
}

