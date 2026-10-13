# Homebrew (macOS ARM)
eval "$(/opt/homebrew/bin/brew shellenv)"
autoload -Uz compinit
# Rebuild the completion dump at most once a day; otherwise trust the cache (-C).
() {
  setopt local_options extended_glob
  if [[ -n $HOME/.zcompdump(#qN.mh+24) ]]; then
    compinit
  else
    compinit -C
  fi
}

# Local environment variables
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# Load Modular Configurations
source "$HOME/.config/zsh/aliases.zsh"
source "$HOME/.config/zsh/custom.zsh"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$PATH:$BUN_INSTALL/bin"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PATH:$PNPM_HOME/bin" ;;
esac
# pnpm end
