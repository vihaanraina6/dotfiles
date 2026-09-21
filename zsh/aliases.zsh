alias ..="cd .."
alias ...="cd ../.."
alias c="clear"
alias q="exit"
alias zrc="zed $HOME/.zshrc"
alias src="source $HOME/.zshrc"
alias tree="eza --tree --all --icons=always --color=always --color-scale=all --color-scale-mode=gradient --ignore-glob='.git|.zed|node_modules|dist|package-lock.json'"
alias refresh='echo "Starting Refresh..." && brew update && brew upgrade && brew cleanup && brew autoremove'
