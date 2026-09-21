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
        source=$(eval echo "$source")
        target=$(eval echo "$target")

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

    while IFS=: read -r source target || [ -n "$target" ]; do

        # Skip empty or commented-out lines
        if [[ -z "$source" || -z "$target" || "$source" == \#* ]]; then
            continue
        fi

        # Evaluate variables
        target=$(eval echo "$target")

        # Check if the symbolic link, file, or directory exists. [-e], not
        # [-f]: a real directory an app created at $target (e.g. Zed making
        # ~/.config/zed on first launch) needs to be caught here too, or
        # create_symlinks' `ln -s` will nest the link inside it instead of
        # replacing it.
        if [ -L "$target" ] || { [ "${include_files:-false}" == true ] && [ -e "$target" ]; }; then
            # Remove the symbolic link or file
            if rm -rf "$target"; then
                success "Deleted: $target"
            else
                error "Failed to delete: $target"
            fi
        else
            warning "Not found: $target"
        fi
    done <"$CONFIG_FILE"
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
    "--help")
        # Display usage/help message
        echo "Usage: $0 [--create | --delete [--include-files] | --help]"
        ;;
    *)
        # Display an error message for unknown arguments
        error "Error: Unknown argument '${1:-}'"
        error "Usage: $0 [--create | --delete [--include-files] | --help]"
        exit 1
        ;;
    esac
fi
