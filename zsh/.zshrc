# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="spaceship"
SPACESHIP_PROMPT_FIRST_PREFIX_SHOW=true
SPACESHIP_DIR_PREFIX=' '
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_PROMPT_SEPARATE_LINE=false
SPACESHIP_VI_MODE_SHOW=false
SPACESHIP_EXEC_TIME_SHOW=false
SPACESHIP_DOCKER_SHOW=false
SPACESHIP_VENV_PREFIX="("
SPACESHIP_VENV_SUFFIX=") "

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

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


plugins=(fzf-tab zsh-vi-mode z zsh-autosuggestions sublime macos git colored-man-pages autoswitch_virtualenv docker docker-compose zsh-syntax-highlighting)


ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
# zsh-vi-mode will overwrite key bindings, so add them after the plugin init
function zvm_after_init() {
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    bindkey '^n' autosuggest-accept
}

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=6'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=true

# Specifies where the virtualenvs are created by default
AUTOSWITCH_VIRTUAL_ENV_DIR="$HOME/.virtualenvs"

# Fix slow pastes, could be removed after zsh 5.8
# https://github.com/zsh-users/zsh-autosuggestions/issues/238
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# fzf-tab
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
    fzf-preview 'echo ${(P)word}'
zstyle ':fzf-tab:complete:(\\|*/|)man:*' fzf-preview 'man $word'

# Remove autosuggestion after pasting
# https://github.com/zsh-users/zsh-autosuggestions/issues/351
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste)

source $ZSH/oh-my-zsh.sh


# -----------------------------------------------------------------------------


export EDITOR=vim
export TERM=xterm-256color-italic
alias ssh='TERM=xterm-256color ssh'
export BAT_THEME="Monokai Extended"

export FZF_DEFAULT_COMMAND="rg --files --hidden -g '!**/{.git,node_modules}/*'"
export FZF_CTRL_T_COMMAND="rg --files --hidden -g '!**/{.git,node_modules,Library,.Trash}/*'"

# export MANPATH="/usr/local/man:$MANPATH"

# psql
export PATH="/Library/PostgreSQL/12/bin:$PATH"

# subl
export PATH="/usr/local/sbin:$PATH"

# iTerm2 shell integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

[ -f "${GHCUP_INSTALL_BASE_PREFIX:=$HOME}/.ghcup/env" ] && source "${GHCUP_INSTALL_BASE_PREFIX:=$HOME}/.ghcup/env"

# Ruby
export PATH="/usr/local/opt/ruby/bin:$PATH"

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Tikzit
export PATH="$PATH:/Applications/TikZiT.app/Contents/MacOS"

eval $(thefuck --alias)

# Heroku autocomplete setup
HEROKU_AC_ZSH_SETUP_PATH=$HOME/Library/Caches/heroku/autocomplete/zsh_setup && test -f $HEROKU_AC_ZSH_SETUP_PATH && source $HEROKU_AC_ZSH_SETUP_PATH;

# Google Cloud SDK autocomplete
source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"


# -----------------------------------------------------------------------------


alias cat='bat --paging=never'
alias be='bundle exec'
alias wordcount="find . -name '*.md' -type f -exec wc -w {} + | tail -n1"
alias gatekeeper="$HOME/.oh-my-zsh/custom/GateKeeper_Helper.command"
alias -g Z='| fzf'

function matlab {
    /Applications/MATLAB_R*.app/bin/matlab -nodesktop -nosplash $*
}

function latexinit {
    cp ~/Code/wex/wex.cls .
    cp ~/Code/wex/.gitignore .
    echo "\\\\documentclass[]{wex}\n\\\\title{DefaultTitle}\n\n\n\\\\begin{document}\n\\\\wextitle\n\n\n\\\\end{document}" >> ${1:-report}.tex
    vim ${1:-report}.tex +VimtexCompile
}

# By Mark H. Nichols, https://zanshin.net/2014/02/03/how-to-list-brew-dependencies/
function brewlsd {
    brew list -1 | while read cask
    do
        echo -ne $fg[blue] $cask $fg[white]
        brew uses --installed $cask | awk '{printf(" %s ", $0)}'
        echo ""
    done
}

# By Tom Hale, https://askubuntu.com/a/821163
function lscolor {
    for i in {0..255} ; do
        printf "\x1b[48;5;%sm%3d\e[0m " "$i" "$i"
        if (( i == 15 )) || (( i > 15 )) && (( (i-15) % 6 == 0 )); then
            printf "\n";
        fi
    done
}

# By Vinicius De Antoni, https://betterprogramming.pub/boost-your-command-line-productivity-with-fuzzy-finder-985aa162ba5d
# like normal z when used with arguments but displays an fzf prompt when used without
unalias z 2> /dev/null
function z {
    [ $# -gt 0 ] && _z "$*" && return
    cd "$(_z -l 2>&1 | fzf --height 40% --nth 2.. --reverse --inline-info +s --tac --query "${*##-* }" | sed 's/^[0-9,.]* *//')"
}

