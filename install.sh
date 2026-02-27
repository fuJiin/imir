#!/bin/bash
set -euo pipefail

REPO="fuJiin/imir"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"

# Determine install directory
if [[ -n "${PREFIX:-}" ]]; then
    BIN_DIR="$PREFIX/bin"
elif [[ -w /usr/local/bin ]]; then
    BIN_DIR="/usr/local/bin"
else
    BIN_DIR="$HOME/.local/bin"
fi

echo "Installing imir to $BIN_DIR..."
mkdir -p "$BIN_DIR"

# Get latest commit hash for version stamping
COMMIT=$(curl -fsSL "https://api.github.com/repos/$REPO/commits/$BRANCH" \
    | grep '"sha"' | head -1 | cut -d'"' -f4 | cut -c1-7) || true

# Download scripts
curl -fsSL "$BASE_URL/bin/imir" -o "$BIN_DIR/imir"
curl -fsSL "$BASE_URL/bin/imir-bootstrap" -o "$BIN_DIR/imir-bootstrap"
curl -fsSL "$BASE_URL/bin/imir-bootstrap-bake" -o "$BIN_DIR/imir-bootstrap-bake"

# Stamp version
if [[ -n "${COMMIT:-}" ]]; then
    sed -i.bak "s/^IMIR_VERSION=\"dev\"/IMIR_VERSION=\"$COMMIT\"/" "$BIN_DIR/imir"
    rm -f "$BIN_DIR/imir.bak"
fi

chmod +x "$BIN_DIR/imir" "$BIN_DIR/imir-bootstrap" "$BIN_DIR/imir-bootstrap-bake"

# Install fish completions if fish is installed
if command -v fish &>/dev/null; then
    FISH_COMP_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fish/completions"
    mkdir -p "$FISH_COMP_DIR"
    curl -fsSL "$BASE_URL/completions/imir.fish" -o "$FISH_COMP_DIR/imir.fish"
    echo "Installed fish completions."
fi

# Check PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
    echo ""
    echo "Warning: $BIN_DIR is not in your PATH."
    echo "Add it with:  fish_add_path $BIN_DIR"
fi

# Run init if no config exists
IMIR_CONFIG="${IMIR_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/imir}/config.env"
if [[ ! -f "$IMIR_CONFIG" ]]; then
    echo ""
    "$BIN_DIR/imir" init
fi

echo ""
echo "Done! Run 'imir help' to get started."
