#!/bin/bash
set -euo pipefail

# Named ROOT_DIR (not SCRIPT_DIR) deliberately: each script below sets its own
# SCRIPT_DIR when sourced, which would silently clobber a variable of the same
# name here. This one is only used before any sourcing happens.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$ROOT_DIR/scripts/utils.sh"
. "$ROOT_DIR/scripts/prerequisites.sh"
. "$ROOT_DIR/scripts/brew-install.sh"
. "$ROOT_DIR/scripts/osx-defaults.sh"
. "$ROOT_DIR/scripts/symlinks.sh"

info "Dotfiles installation initialized..."
read -p "Install apps? [y/n] " install_apps
read -p "Overwrite existing dotfiles? [y/n] " overwrite_dotfiles

if [[ "$install_apps" == "y" ]]; then
    printf "\n"
    info "===================="
    info "Prerequisites"
    info "===================="

    install_xcode
    install_homebrew

    printf "\n"
    info "===================="
    info "Apps"
    info "===================="

    run_brew_bundle
fi

printf "\n"
info "===================="
info "OSX System Defaults"
info "===================="

apply_osx_system_defaults

printf "\n"
info "===================="
info "Terminal"
info "===================="

info "Adding .hushlogin file to suppress 'last login' message in terminal..."
touch ~/.hushlogin

printf "\n"
info "===================="
info "Symbolic Links"
info "===================="

if [[ "$overwrite_dotfiles" == "y" ]]; then
    warning "Deleting existing dotfiles..."
    include_files=true
    delete_symlinks
fi
create_symlinks

success "Dotfiles set up successfully."
