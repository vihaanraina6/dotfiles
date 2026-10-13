#!/bin/bash
set -uo pipefail

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$SCRIPT_DIR/utils.sh"

apply_osx_system_defaults() {
    info "Applying MacOS system defaults..."

    # --- Trackpad ---
    # Disable three finger drag
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false

    # --- Finder & Desktop ---
    # Show external hard drives on desktop
    defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false

    # Show hard drives on desktop
    defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true

    # Show removable media hard drives on desktop
    defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

    # Show path bar
    defaults write com.apple.finder ShowPathbar -bool true

    # Show hidden files inside the finder
    defaults write com.apple.finder "AppleShowAllFiles" -bool true

    # Show Status Bar
    defaults write com.apple.finder "ShowStatusBar" -bool true

    # --- Accessibility ---
    # Reduce Motion disabled
    defaults write com.apple.Accessibility ReduceMotionEnabled -bool false

    # --- Dock ---
    # Set Dock autohide
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock tilesize -int 51

    # Finder/Dock only pick up most of these on restart
    killall Finder 2>/dev/null || true
    killall Dock 2>/dev/null || true

    # --- Untouched/Default Settings ---

    # defaults write -g ApplePressAndHoldEnabled -bool false
    # defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
    # defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
    # defaults write com.apple.finder CreateDesktop -bool false
    # defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    # defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    # defaults write com.apple.screencapture type -string "png"
    # defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 7
    # defaults write com.apple.spaces "spans-displays" -bool false
    # defaults write com.apple.dock "mru-spaces" -bool false
    # defaults write com.apple.universalaccess reduceMotion -bool true
    # defaults write com.apple.dock largesize -float 128
    # defaults write com.apple.dock "minimize-to-application" -bool true
}

if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    apply_osx_system_defaults
fi
