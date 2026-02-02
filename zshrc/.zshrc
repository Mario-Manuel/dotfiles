# ------------------------------
# Powerlevel10k instant prompt
# ------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Carrega Powerlevel10k (instalado via git ou AUR)
source ~/.local/share/powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ------------------------------
# Plugins instalados via pacman
# ------------------------------
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh

# ------------------------------
# Delayed fun: fortune + cowsay + lolcat
# ------------------------------
autoload -Uz add-zsh-hook
add-zsh-hook -Uz precmd _fun_prompt

_fun_prompt() {
  fortune | cowsay -f tux | lolcat -f
  add-zsh-hook -d precmd _fun_prompt
}

# ------------------------------
# Aliases
# ------------------------------
alias ls='eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions --group-directories-first'
alias ll='eza -lh --icons --git --group-directories-first'
alias la='eza -lAh --icons --git --group-directories-first'
alias ff='fastfetch'
alias cat='bat'
alias cd='z'

# ------------------------------
# PATH
# ------------------------------
export PATH="$PATH:$HOME/.local/bin"

# ------------------------------
# Yazi cwd integration
# ------------------------------
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# ------------------------------
# default programs
# ------------------------------
export EDITOR="/usr/bin/nvim"
export TERM="foot"
export TERMINAL="foot"
export BROWSER="brave"

# ------------------------------
# fzf theme e configurações
# ------------------------------
fg="#CBE0F0"
purple="#B388FF"
blue="#06BCE4"
cyan="#2CF9ED"

export FZF_DEFAULT_OPTS="--color=fg:${fg},hl:${purple},fg+:${fg},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

_fzf_compgen_path() { fd --hidden --exclude .git . "$1" }
_fzf_compgen_dir() { fd --type=d --hidden --exclude .git . "$1" }

# bat theme
export BAT_THEME=tokyonight_night

show_file_or_dir_preview='if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

_fzf_comprun() {
  local command=$1; shift
  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo ${}'" "$@" ;;
    ssh)          fzf --preview 'dig {}' "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

# ------------------------------
# zoxide
# ------------------------------
eval "$(zoxide init zsh)"

# ------------------------------------
# número máximo de linhas guardadas
# ------------------------------------
HISTSIZE=100000
SAVEHIST=100000
HISTCONTROL=ignoreboth
HISTFILE=~/.zsh_history

# ----------------------------
# append, não sobrescrever
# ----------------------------
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE

# ----------------
# main opts
# ----------------
setopt autocd
setopt auto_param_slash 

# -----------------
# emacs-like
# -----------------
bindkey -e

# -------------------------------------------------
# Ativa o uso das setas para navegar pelo histórico
# -------------------------------------------------
bindkey "^[[A" history-search-backward   # seta cima
bindkey "^[[B" history-search-forward    # seta baixo
bindkey '^[[C' forward-char            # seta direita (aceita sugestão)
