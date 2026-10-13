#!/bin/bash
set -uo pipefail

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Absolute path to the repo root. Exported so symlinks.conf can reference
# $REPO_DIR instead of $(pwd), which broke if this was ever invoked from
# outside the repo directory.
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export REPO_DIR

CONFIG_FILE="$SCRIPT_DIR/../symlinks.conf"

. "$SCRIPT_DIR/utils.sh"

# Expand the handful of variables symlinks.conf is allowed to use, WITHOUT eval.
# `eval echo` would run any $(...) or backtick in the file; this only substitutes
# $REPO_DIR, $HOME (also in ${...} form) and a leading ~/.
expand_path() {
    local p="$1"
    p="${p//\$\{REPO_DIR\}/$REPO_DIR}"
    p="${p//\$REPO_DIR/$REPO_DIR}"
    p="${p//\$\{HOME\}/$HOME}"
    p="${p//\$HOME/$HOME}"
    case "$p" in
    "~/"*) p="$HOME/${p#\~/}" ;;
    esac
    printf '%s' "$p"
}

# Check if configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

create_symlinks() {
    info "Creating symbolic links..."

    # Read dotfile links from the config file
    while IFS=: read -r source target || [ -n "$source" ]; do

        # Skip empty or invalid lines in the config file
        if [[ -z "$source" || -z "$target" || "$source" == \#* ]]; then
            continue
        fi

        # Evaluate variables
        source="$(expand_path "$source")"
        target="$(expand_path "$target")"

        # Check if the source file exists
        if [ ! -e "$source" ]; then
            error "Error: Source file '$source' not found. Skipping link creation for '$target'."
            continue
        fi

        # Check if the symbolic link already exists
        if [ -L "$target" ]; then
            warning "Symbolic link already exists: $target"
        elif [ -e "$target" ]; then
            warning "Target (file or directory) already exists: $target"
        else
            # Extract the directory portion of the target path
            target_dir=$(dirname "$target")

            # Check if the target directory exists, and if not, create it
            if [ ! -d "$target_dir" ]; then
                mkdir -p "$target_dir"
                info "Created directory: $target_dir"
            fi

            # Create the symbolic link
            if ln -s "$source" "$target"; then
                success "Created symbolic link: $target"
            else
                error "Failed to create symbolic link: $target"
            fi
        fi
    done <"$CONFIG_FILE"
}

delete_symlinks() {
    info "Deleting symbolic links..."

    # Real files/dirs are never deleted: with --include-files they are moved here instead,
    # keeping their path relative to $HOME, so nothing is lost if you overwrote something by mistake.
    local backup_root="${BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"

    while IFS=: read -r source target || [ -n "$target" ]; do

        # Skip empty or commented-out lines
        if [[ -z "$source" || -z "$target" || "$source" == \#* ]]; then
            continue
        fi

        # Evaluate variables
        target="$(expand_path "$target")"

        if [ -L "$target" ]; then
            # A symlink: unlink it. Plain `rm` (no -r, no -f) cannot remove a real directory,
            # so this can never touch the data behind the link.
            if rm "$target"; then
                success "Removed link: $target"
            else
                error "Failed to remove link: $target"
            fi
        elif [ "${include_files:-false}" == true ] && [ -e "$target" ]; then
            # [-e], not [-f]: a real directory an app created at $target (e.g. Zed making
            # ~/.config/zed on first launch) must be moved out of the way too, or
            # create_symlinks' `ln -s` would nest the link inside it.
            local dest="$backup_root/${target#"$HOME"/}"
            if mkdir -p "$(dirname "$dest")" && mv "$target" "$dest"; then
                success "Moved to backup: $target -> $dest"
            else
                error "Failed to back up: $target"
            fi
        else
            warning "Not found: $target"
        fi
    done <"$CONFIG_FILE"
}

check_symlinks() {
    info "Checking symbolic links..."
    local bad=0

    while IFS=: read -r source target || [ -n "$source" ]; do
        if [[ -z "$source" || -z "$target" || "$source" == \#* ]]; then
            continue
        fi
        source="$(expand_path "$source")"
        target="$(expand_path "$target")"

        if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
            success "OK: $target"
        elif [ -L "$target" ]; then
            warning "Points elsewhere: $target -> $(readlink "$target")"
            bad=1
        elif [ -e "$target" ]; then
            # Typical cause: an installer rewrote the file and replaced the link.
            warning "Replaced by a real file/dir: $target   (compare: diff -r \"$target\" \"$source\")"
            bad=1
        else
            warning "Missing: $target"
            bad=1
        fi
    done <"$CONFIG_FILE"

    if [ "$bad" = 0 ]; then
        success "All links intact."
    else
        warning "Merge anything you want to keep into the repo, quit the apps involved, then run:"
        warning "  $0 --delete --include-files && $0 --create"
        return 1
    fi
}

# Parse arguments
if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    case "${1:-}" in
    "--create")
        create_symlinks
        ;;
    "--delete")
        if [ "${2:-}" == "--include-files" ]; then
            include_files=true
        fi
        delete_symlinks
        ;;
    "--check")
        check_symlinks
        ;;
    "--help")
        # Display usage/help message
        echo "Usage: $0 [--create | --check | --delete [--include-files] | --help]"
        ;;
    *)
        # Display an error message for unknown arguments
        error "Error: Unknown argument '${1:-}'"
        error "Usage: $0 [--create | --check | --delete [--include-files] | --help]"
        exit 1
        ;;
    esac
fi
