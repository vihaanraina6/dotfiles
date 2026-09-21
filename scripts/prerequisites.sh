#!/bin/bash
set -uo pipefail

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$SCRIPT_DIR/utils.sh"

install_xcode() {
    info "Installing Apple's CLI tools (prerequisites for Git and Homebrew)..."
    if xcode-select -p >/dev/null 2>&1; then
        warning "xcode is already installed"
    else
        xcode-select --install
        info "Waiting for the Xcode Command Line Tools installer to finish (complete the GUI prompt if one appears)..."
        until xcode-select -p >/dev/null 2>&1; do
            sleep 5
        done
        success "Xcode Command Line Tools installed."
    fi

    # `xcodebuild -license accept` only works when the *full* Xcode.app is
    # installed - it errors ("requires Xcode, but active developer directory
    # ... is a command line tools instance") when only the standalone Command
    # Line Tools package is present, which is all --install above gives you.
    if [ -d "/Applications/Xcode.app" ]; then
        sudo xcodebuild -license accept
    fi
}

install_homebrew() {
    info "Installing Homebrew..."
    export HOMEBREW_CASK_OPTS="--appdir=/Applications"
    if hash brew &>/dev/null; then
        warning "Homebrew already installed"
    else
        sudo --validate
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    fi

    # A fresh install doesn't put brew on PATH for *this* running script -
    # only new login shells pick it up via .zprofile/.zshrc. Load it now so
    # run_brew_bundle (called right after this) can actually find brew.
    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    install_xcode
    install_homebrew
fi
