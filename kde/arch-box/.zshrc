# ==============================
# Powerlevel10k instant prompt
# ==============================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================
# PATH
# ==============================
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ==============================
# Modular configs
# ==============================
if [[ -d ~/.zshrc.d ]]; then
  for rc in ~/.zshrc.d/*; do
    [[ -f "$rc" ]] && source "$rc"
  done
fi

# ==============================
# Powerlevel10k theme
# ==============================
for p in \
  ~/.local/share/powerlevel10k/powerlevel10k.zsh-theme \
  /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
do
  [[ -f "$p" ]] && source "$p" && break
done

# ==============================
# Plugins
# ==============================
# zsh-autosuggestions
[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh


# zsh-syntax-highlighting
[[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# fzf
[[ -f /usr/share/fzf/shell/key-bindings.zsh ]] && \
    source /usr/share/fzf/shell/key-bindings.zsh

[[ -f /usr/share/fzf/completion.zsh ]] && \
    source /usr/share/fzf/completion.zsh

[[ -f /usr/share/fzf/key-bindings.zsh ]] && \
    source /usr/share/fzf/key-bindings.zsh

# ==============================
# Delayed fun: fortune + cowsay + lolcat
# ==============================
autoload -Uz add-zsh-hook

_fun_prompt() {
  local colors=(
    "122;162;247" # blue
    "187;154;247" # purple
    "125;207;255" # cyan
    "158;206;106" # green
    "224;175;104" # yellow
    "247;118;142" # red
  )

local c=${colors[RANDOM % ${#colors[@]} + 1]}

fortune | cowsay -f tux | sed "s/.*/\x1b[38;2;${c}m&\x1b[0m/"

add-zsh-hook -d precmd _fun_prompt 
}

add-zsh-hook precmd _fun_prompt

# ==============================
# Aliases
# ==============================
alias ls='eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions --group-directories-first'
alias ll='eza -lh --icons --git --group-directories-first'
alias la='eza -lAh --icons --git --group-directories-first'
alias ff='fastfetch'
alias cat='bat'
alias cd='z'
alias dl='aria2c -c -d ~/Downloads -x 8 -s 8 -k 1M --min-split-size=1M --file-allocation=trunc --max-tries=0 --retry-wait=5 --summary-interval=0 --console-log-level=warn'
alias upall='sudo dnf upgrade --refresh && flatpak upgrade'

# ==============================
# Yazi integration
# ==============================
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# ==============================
# Default programs
# ==============================
export EDITOR="nvim"
export TERMINAL="konsole"
export BROWSER="brave"

# ==============================
# fzf configuration
# ==============================
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

# ==============================
# zoxide
# ==============================
eval "$(zoxide init zsh)"

# ==============================
# History
# ==============================
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS

# ==============================
# Behavior options
# ==============================
setopt autocd
setopt auto_param_slash

# ==============================
# Keybindings
# ==============================
bindkey -e

bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward
bindkey '^[[C' forward-char

if [[ -n "$PS1" ]]; then
  cd ~
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
