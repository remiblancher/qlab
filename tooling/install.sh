#!/bin/bash
# =============================================================================
# QPKI Tool Installation Script
# Post-Quantum PKI Lab (QLAB)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "=============================================="
echo "  QLAB - Post-Quantum PKI Lab"
echo "  Installing QPKI (Post-Quantum PKI) toolkit"
echo "=============================================="
echo -e "${NC}"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        echo -e "${RED}Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}Detected:${NC} $OS / $ARCH"

# =============================================================================
# Check if binary already exists
# =============================================================================

if [[ -x "$LAB_ROOT/bin/qpki" ]]; then
    echo ""
    echo -e "${GREEN}QPKI tool already installed at: $LAB_ROOT/bin/qpki${NC}"
    echo ""
    "$LAB_ROOT/bin/qpki" version 2>/dev/null || echo -e "${YELLOW}(version check not available)${NC}"
    echo ""
    echo -e "To rebuild from source, remove the binary first:"
    echo -e "  ${CYAN}rm $LAB_ROOT/bin/qpki && ./tooling/install.sh${NC}"
    echo ""
    exit 0
fi

# =============================================================================
# Option 1: Build from source (if QPKI repo is available)
# =============================================================================

PKI_SOURCE_DIR="${PKI_SOURCE_DIR:-$LAB_ROOT/../pki}"

if [[ -d "$PKI_SOURCE_DIR" ]] && [[ -f "$PKI_SOURCE_DIR/go.mod" ]]; then
    echo ""
    echo -e "${CYAN}Found QPKI source at: $PKI_SOURCE_DIR${NC}"
    echo -e "Building from source..."
    echo ""

    cd "$PKI_SOURCE_DIR"

    # Check Go version
    if ! command -v go &> /dev/null; then
        echo -e "${RED}Go is not installed. Please install Go 1.21+${NC}"
        exit 1
    fi

    GO_VERSION=$(go version | grep -oE 'go[0-9]+\.[0-9]+' | sed 's/go//')
    echo -e "Go version: $GO_VERSION"

    # Build
    echo -e "${CYAN}Building QPKI binary...${NC}"
    go build -o "$LAB_ROOT/bin/qpki" ./cmd/pki

    if [[ -f "$LAB_ROOT/bin/qpki" ]]; then
        echo -e "${GREEN}Success!${NC} QPKI binary built at: $LAB_ROOT/bin/qpki"
        echo ""
        echo "Add to your PATH:"
        echo -e "  ${YELLOW}export PATH=\"$LAB_ROOT/bin:\$PATH\"${NC}"
        echo ""
        echo "Or use directly:"
        echo -e "  ${YELLOW}export PKI_BIN=\"$LAB_ROOT/bin/qpki\"${NC}"

        # Create symlink for convenience
        mkdir -p "$LAB_ROOT/bin"
        chmod +x "$LAB_ROOT/bin/qpki"

        exit 0
    else
        echo -e "${RED}Build failed${NC}"
        exit 1
    fi
fi

# =============================================================================
# Option 2: Download pre-built binary from GitHub releases
# =============================================================================

echo ""
echo -e "${YELLOW}QPKI source not found at $PKI_SOURCE_DIR${NC}"
echo -e "Attempting to download pre-built binary..."
echo ""

# GitHub release URL (update this when releases are available)
GITHUB_REPO="remiblancher/post-quantum-pki"
VERSION="${PKI_VERSION:-latest}"

if [[ "$VERSION" == "latest" ]]; then
    RELEASE_URL="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
else
    RELEASE_URL="https://api.github.com/repos/$GITHUB_REPO/releases/tags/$VERSION"
fi

echo -e "Checking releases at: $RELEASE_URL"

# For now, just provide instructions since releases may not exist yet
echo ""
echo -e "${YELLOW}=============================================="
echo "  Pre-built binaries not yet available"
echo "=============================================="
echo -e "${NC}"
echo ""
echo "To use QLAB, you need to build QPKI from source:"
echo ""
echo "  1. Clone the QPKI repository:"
echo -e "     ${CYAN}git clone https://github.com/$GITHUB_REPO.git $LAB_ROOT/../pki${NC}"
echo ""
echo "  2. Run this script again:"
echo -e "     ${CYAN}./tooling/install.sh${NC}"
echo ""
echo "Or set PKI_SOURCE_DIR to point to an existing QPKI checkout:"
echo -e "  ${CYAN}PKI_SOURCE_DIR=/path/to/pki ./tooling/install.sh${NC}"
echo ""

exit 1
