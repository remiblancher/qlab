#!/bin/bash
# =============================================================================
# Interactive Helpers for Post-Quantum PKI Lab
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

# =============================================================================
# Command Execution
# =============================================================================

# Run a command with explanation
# Usage: run_cmd "pki ca init ..." "Creating a new CA"
run_cmd() {
    local cmd="$1"
    local description="${2:-}"

    echo ""
    if [[ -n "$description" ]]; then
        echo -e "${CYAN}$description${NC}"
    fi
    echo -e "  ${DIM}\$ $cmd${NC}"
    echo ""
    eval "$cmd"
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}[OK]${NC}"
    else
        echo -e "${RED}[FAILED]${NC} Exit code: $exit_code"
    fi
    return $exit_code
}

# =============================================================================
# Validation
# =============================================================================

# Validate file exists
validate_file() {
    local file_path="$1"
    local label="${2:-File}"

    if [[ -f "$file_path" ]]; then
        local size=$(wc -c < "$file_path" | tr -d ' ')
        echo -e "${GREEN}[OK]${NC} $label created (${size} bytes)"
        return 0
    else
        echo -e "${RED}[X]${NC} $label not found: $file_path"
        return 1
    fi
}

# Validate multiple files
validate_files() {
    local dir="$1"
    shift

    echo ""
    echo -e "${BOLD}Generated files:${NC}"
    for file in "$@"; do
        if [[ -f "$dir/$file" ]]; then
            local size=$(wc -c < "$dir/$file" | tr -d ' ')
            printf "  ${GREEN}[OK]${NC} %-25s %7d bytes\n" "$file" "$size"
        else
            printf "  ${RED}[X]${NC} %-25s missing\n" "$file"
        fi
    done
    echo ""
}

# =============================================================================
# Progress Display
# =============================================================================

# Section header
section() {
    local title="$1"
    local description="${2:-}"

    echo ""
    echo -e "${BOLD}${CYAN}=== $title ===${NC}"
    if [[ -n "$description" ]]; then
        echo -e "${DIM}$description${NC}"
    fi
    echo ""
}

# Step header
step() {
    local num="$1"
    local title="$2"

    echo ""
    echo -e "${BOLD}Step $num: $title${NC}"
    echo ""
}

# Success message
success() {
    local message="$1"
    echo -e "${GREEN}[OK]${NC} $message"
}

# Info message
info() {
    local message="$1"
    echo -e "${CYAN}[INFO]${NC} $message"
}

# Warning message
warn() {
    local message="$1"
    echo -e "${YELLOW}[WARN]${NC} $message"
}

# =============================================================================
# Summary
# =============================================================================

# Show what was accomplished
show_summary() {
    local title="$1"
    shift

    echo ""
    echo -e "${BOLD}${title}${NC}"
    echo ""
    for item in "$@"; do
        echo -e "  ${GREEN}[OK]${NC} $item"
    done
    echo ""
}

# Show key takeaway
show_takeaway() {
    local message="$1"
    echo ""
    echo -e "${BG_BLUE}${BOLD_WHITE} KEY TAKEAWAY ${NC}"
    echo ""
    echo -e "  $message"
    echo ""
}

# Show next mission
show_next() {
    local path="$1"
    local title="$2"

    echo ""
    echo -e "${BOLD}Next:${NC} $title"
    echo -e "  ${CYAN}$path${NC}"
    echo ""
}

# =============================================================================
# Wait
# =============================================================================

wait_enter() {
    local message="${1:-Press Enter to continue...}"
    echo ""
    read -p "$(echo -e "  ${DIM}$message${NC}")" _
}
