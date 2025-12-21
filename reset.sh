#!/bin/bash
# =============================================================================
#  Reset workspaces
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$SCRIPT_DIR/workspace"

show_usage() {
    echo ""
    echo "Usage: ./reset.sh [level]"
    echo ""
    echo "Levels:"
    echo "  quickstart    Reset Quick Start workspace"
    echo "  level-1       Reset Level 1 workspace"
    echo "  level-2       Reset Level 2 workspace"
    echo "  level-3       Reset Level 3 workspace"
    echo "  level-4       Reset Level 4 workspace"
    echo "  all           Reset ALL workspaces"
    echo ""
    echo "Example:"
    echo "  ./reset.sh quickstart"
    echo "  ./reset.sh all"
    echo ""
}

reset_workspace() {
    local name="$1"
    local dir="$WORKSPACE_DIR/$name"

    if [[ -d "$dir" ]]; then
        rm -rf "$dir"
        echo "[OK] Reset: $name"
    else
        echo "[SKIP] Not found: $name"
    fi
}

case "${1:-}" in
    quickstart|level-1|level-2|level-3|level-4)
        reset_workspace "$1"
        ;;
    all)
        echo "Resetting all workspaces..."
        reset_workspace "quickstart"
        reset_workspace "level-1"
        reset_workspace "level-2"
        reset_workspace "level-3"
        reset_workspace "level-4"
        echo ""
        echo "Done."
        ;;
    *)
        show_usage
        ;;
esac
