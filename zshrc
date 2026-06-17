# ~/.zshrc

# --- ENV ---
export EDITOR="nvim"
export VISUAL="nvim"
export TERMINAL="kitty"
export CHROME_EXECUTABLE="/bin/brave"
export GTK_THEME="adw-gtk3-dark"
export QT_QPA_PLATFORMTHEME="qt5ct"

# --- PATH ---
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk"
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

typeset -U path PATH
path=(
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
    "/var/lib/snapd/snap/bin"
    "$HOME/flutter/bin"
    "$JAVA_HOME/bin"
    "$ANDROID_HOME/emulator"
    "$ANDROID_HOME/platform-tools"
    "$ANDROID_HOME/tools"
    "$ANDROID_HOME/tools/bin"
    $path
)
export PATH

# --- ZINIT ---
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#7dcfff,italic"

zinit light zsh-users/zsh-syntax-highlighting
zinit light Aloxaf/fzf-tab

zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::git
zinit snippet OMZP::command-not-found

# --- COMPLETION & HISTORY ---
autoload -Uz compinit && compinit -C
zinit cdreplay -q

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:messages' format '%F{cyan}%d%f'
zstyle ':completion:*:warnings' format '%F{red}No matches found%f'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:*' fzf-flags --color=fg:#c0caf5,bg:#1a1b26,hl:#7aa2f7 --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff --color=info:#7aa2f7,prompt:#7dcfff,pointer:#ff007c

HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"

setopt append_history
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify
setopt inc_append_history
setopt share_history

# --- KEYBINDINGS ---
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# --- ALIASES ---
# Core
alias ls='eza -al --color=always --group-directories-first --icons'
alias lt='eza -aT --color=always --group-directories-first --icons'
alias cat='bat'
alias grep='ugrep --color=auto'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias md='mkdir -p'
alias src='source ~/.zshrc'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit -v'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'

# System
alias update='sudo pacman -Syu && yay -Syu'
alias pacin='sudo pacman -S'
alias pacrm='sudo pacman -Rns'
alias fetch='fastfetch'

# --- FUNCTIONS ---
enva() {
    local env_name="${1:-venv}"
    if [ ! -d "$env_name" ]; then
        python -m venv "$env_name"
    fi
    source "$env_name/bin/activate"
}

bhej() {
    local title="${1:-update}"
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -z "$branch" ]; then
        echo "Error: Not a git repository"
        return 1
    fi
    git add -A
    git commit -m "$title"
    git push origin "$branch"
}

# --- INTEGRATIONS ---
eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(fzf --zsh)"
