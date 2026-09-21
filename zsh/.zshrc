# Homebrew (macOS ARM)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Local environment variables
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# Load Modular Configurations
source "$HOME/.config/zsh/aliases.zsh"
source "$HOME/.config/zsh/custom.zsh"
