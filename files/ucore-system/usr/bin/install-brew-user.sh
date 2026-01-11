#!/bin/bash
# Install Homebrew for the current user
# This script is designed to run on first boot or manually by any user
# It installs brew to /home/linuxbrew/.linuxbrew owned by the running user

set -euo pipefail

# Check if running as root
if [[ "$(id -u)" == "0" ]]; then
    echo "ERROR: This script should not be run as root"
    echo "Please run as a regular user"
    exit 1
fi

# Check if brew is already installed and working
if command -v brew &> /dev/null; then
    echo "Homebrew is already installed and in PATH"
    exit 0
fi

# Check if brew directory exists
if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
    echo "Homebrew directory exists at /home/linuxbrew/.linuxbrew"
    echo "Adding to PATH..."
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo "Homebrew is ready to use"
    exit 0
fi

echo "Installing Homebrew for user: $USER"
echo "This may take a few minutes..."

# Run the official Homebrew installer
# NONINTERACTIVE=1 prevents prompts
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Verify installation
if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
    echo "Homebrew installed successfully!"
    
    # Add brew to current session
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    
    # Add to shell profiles if not already present
    BREW_SHELLENV='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    
    # Bash
    if [[ -f "$HOME/.bashrc" ]] && ! grep -q "linuxbrew" "$HOME/.bashrc"; then
        echo "" >> "$HOME/.bashrc"
        echo "# Homebrew" >> "$HOME/.bashrc"
        echo "$BREW_SHELLENV" >> "$HOME/.bashrc"
        echo "Added Homebrew to ~/.bashrc"
    fi
    
    # Fish
    if [[ -d "$HOME/.config/fish" ]]; then
        mkdir -p "$HOME/.config/fish/conf.d"
        if [[ ! -f "$HOME/.config/fish/conf.d/homebrew.fish" ]]; then
            echo "# Homebrew" > "$HOME/.config/fish/conf.d/homebrew.fish"
            echo 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> "$HOME/.config/fish/conf.d/homebrew.fish"
            echo "Added Homebrew to fish config"
        fi
    fi
    
    # Disable analytics
    brew analytics off
    
    echo ""
    echo "Homebrew installation complete!"
    echo "You may need to restart your shell or run:"
    echo '  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
else
    echo "ERROR: Homebrew installation failed"
    exit 1
fi
