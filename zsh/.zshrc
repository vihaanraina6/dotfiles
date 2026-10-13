# Homebrew (macOS ARM)
eval "$(/opt/homebrew/bin/brew shellenv)"
autoload -Uz compinit && compinit

# Local environment variables
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# Load Modular Configurations
source "$HOME/.config/zsh/aliases.zsh"
source "$HOME/.config/zsh/custom.zsh"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
