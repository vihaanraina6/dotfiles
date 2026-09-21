# Zsh Syntax & Autosuggestions
if type brew &>/dev/null; then
  BREW_PREFIX="$(brew --prefix)"
  [ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  [ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# fzf
command -v fzf &>/dev/null && source <(fzf --zsh)

# Starship
if command -v starship &>/dev/null; then
  export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
  eval "$(starship init zsh)"
fi

# fnm
command -v fnm &>/dev/null && eval "$(fnm env --use-on-cd)"

# History Configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# Arrow Key History Search
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# Helper Functions
take() {
  mkdir -p "$1" && cd "$1"
}

irepo() {
  if [ -z "${1:-}" ]; then
    echo "Usage: irepo <output_file>"
    return 1
  fi
  npx -y repomix --ignore ".git,node_modules,dist,package-lock.json,database,.zed,LICENSE" --stdout > "$1"
}
