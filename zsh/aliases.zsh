# --- Navigation Shortcuts ---
alias ..="cd .."
alias ...="cd ../.."

# --- zshrc Shortcuts ---
alias zrc="zed $HOME/.zshrc"
alias src="source $HOME/.zshrc"

# --- Git Shortcuts ---
alias gs="git status"
alias ga="git add"
alias gaa="git add ."
alias gcm="git commit -m"
alias grs="git restore --staged"

# --- Theme Toggle Shortcuts ---
alias th="theme"
alias tt="theme toggle"

# --- Miscellaneous
alias c="clear"
alias q="exit"
alias tree="eza --tree --all --icons=always --color=always --color-scale=all --color-scale-mode=gradient --ignore-glob='.git|.zed|node_modules|dist|package-lock.json|.venv'"
alias refresh='echo "Starting Refresh..." && brew update && brew upgrade && brew cleanup && brew autoremove'
