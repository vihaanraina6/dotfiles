[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$HOME/.lmstudio/bin"

# Vite+ bin (https://viteplus.dev)
[ -f "$HOME/.config/vite-plus/env" ] && . "$HOME/.config/vite-plus/env"

# Several of the lines above prepend to PATH; keep each entry only once.
typeset -U path PATH
