#!/usr/bin/env bash

# install_aliases.sh
# Adds aliases for linux-convenient-scripts to the user's ~/.bashrc or ~/.zshrc

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ALIASES="
# === Linux Convenient Scripts Aliases ===
alias cc='claude code'
alias wns='watch -t nvidia-smi'
alias ccb='${SCRIPT_DIR}/agents/claude-bg.sh'
alias codexb='${SCRIPT_DIR}/agents/codex-bg.sh'
# ========================================
"

install_to_rc() {
    local rc_file="$1"
    
    if [ ! -f "$rc_file" ]; then
        return
    fi
    
    # Check if aliases are already installed
    if grep -q "# === Linux Convenient Scripts Aliases ===" "$rc_file"; then
        echo "Aliases already exist in $rc_file. Updating..."
        # Remove old block and append new one
        sed -i '/# === Linux Convenient Scripts Aliases ===/,/# ========================================/d' "$rc_file"
    fi
    
    echo "$ALIASES" >> "$rc_file"
    echo "Successfully added aliases to $rc_file"
}

# Install to common rc files
install_to_rc "$HOME/.bashrc"
install_to_rc "$HOME/.zshrc"

echo "Installation complete. Please run 'source ~/.bashrc' or restart your terminal to apply."
