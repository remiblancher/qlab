#!/bin/bash
# =============================================================================
# Common Functions for Post-Quantum PKI Lab
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/banner.sh"

# Get the lab root directory
LAB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# PKI binary location (always in bin/)
PKI_BIN="$LAB_ROOT/bin/pki"

# Workspace directory for demo artifacts (persists after demo)
WORKSPACE="$LAB_ROOT/workspace"

# =============================================================================
# Setup and Cleanup
# =============================================================================

setup_demo() {
    local demo_name="$1"

    # Extract UC identifier (e.g., "PKI-01: Store Now..." → "pki-01")
    local uc_id=$(echo "$demo_name" | grep -oE '^[A-Z]+-[0-9]+' | tr '[:upper:]' '[:lower:]')

    # Set demo workspace
    DEMO_TMP="$WORKSPACE/${uc_id:-demo}"

    # Clean previous run if exists
    if [[ -d "$DEMO_TMP" ]]; then
        rm -rf "$DEMO_TMP"
    fi

    # Create workspace directory
    mkdir -p "$DEMO_TMP"

    # Show banner
    show_banner "$demo_name"

    # Check PKI binary
    if [[ ! -x "$PKI_BIN" ]]; then
        print_error "PKI tool not installed"
        print_info "Run: ./tooling/install.sh"
        exit 1
    fi

    print_info "Artifacts: $DEMO_TMP"
    echo ""
}

# =============================================================================
# Certificate Helpers
# =============================================================================

# Get certificate file size in bytes
cert_size() {
    local cert_file="$1"
    if [[ -f "$cert_file" ]]; then
        wc -c < "$cert_file" | tr -d ' '
    else
        echo "0"
    fi
}

# Get key file size in bytes
key_size() {
    local key_file="$1"
    if [[ -f "$key_file" ]]; then
        wc -c < "$key_file" | tr -d ' '
    else
        echo "0"
    fi
}

# Display certificate info (brief)
show_cert_brief() {
    local cert_file="$1"
    local label="${2:-Certificate}"

    if [[ -f "$cert_file" ]]; then
        local size=$(cert_size "$cert_file")
        local subject=$(openssl x509 -in "$cert_file" -noout -subject 2>/dev/null | sed 's/subject=//')
        local issuer=$(openssl x509 -in "$cert_file" -noout -issuer 2>/dev/null | sed 's/issuer=//')
        local algo=$(openssl x509 -in "$cert_file" -noout -text 2>/dev/null | grep "Signature Algorithm" | head -1 | awk '{print $3}')

        echo -e "  ${BOLD}$label${NC}"
        echo -e "    Subject:   $subject"
        echo -e "    Issuer:    $issuer"
        echo -e "    Algorithm: ${CYAN}$algo${NC}"
        echo -e "    Size:      ${YELLOW}$size bytes${NC}"
    else
        print_error "Certificate not found: $cert_file"
    fi
}

# =============================================================================
# Timing Helpers
# =============================================================================

# Measure command execution time in milliseconds
time_cmd() {
    # macOS doesn't support date +%s%N, use perl for cross-platform milliseconds
    local start=$(perl -MTime::HiRes=time -e 'printf "%.0f", time * 1000')
    "$@" > /dev/null 2>&1
    local end=$(perl -MTime::HiRes=time -e 'printf "%.0f", time * 1000')
    echo $(( end - start ))
}

# =============================================================================
# Comparison Table
# =============================================================================

print_comparison_header() {
    echo ""
    printf "${BOLD}%-20s %15s %15s %15s${NC}\n" "Metric" "Classical" "Post-Quantum" "Ratio"
    echo "─────────────────────────────────────────────────────────────────"
}

print_comparison_row() {
    local metric="$1"
    local classical="$2"
    local pq="$3"
    local unit="${4:-}"

    local ratio
    if [[ "$classical" -gt 0 ]]; then
        ratio=$(echo "scale=1; $pq / $classical" | bc)
    else
        ratio="N/A"
    fi

    printf "%-20s %14s%s %14s%s %14sx\n" "$metric" "$classical" "$unit" "$pq" "$unit" "$ratio"
}

# =============================================================================
# Step-by-Step Demo Helpers
# =============================================================================

STEP_CURRENT=0
STEP_TOTAL=0

# Initialize step counter
init_steps() {
    STEP_TOTAL="$1"
    STEP_CURRENT=0
}

# Show a step header with explanation
step() {
    STEP_CURRENT=$((STEP_CURRENT + 1))
    local title="$1"
    local description="$2"

    echo ""
    echo -e "${BOLD}${CYAN}[STEP $STEP_CURRENT/$STEP_TOTAL]${NC} ${BOLD}$title${NC}"
    if [[ -n "$description" ]]; then
        echo -e "${DIM}$description${NC}"
    fi
    echo ""
}

# Run a command with display
run_cmd() {
    local cmd="$1"
    echo -e "  ${YELLOW}\$ $cmd${NC}"
    echo ""
    eval "$cmd"
}

# Show generated files in a directory
show_files() {
    local dir="$1"
    local label="${2:-Generated files:}"

    echo ""
    echo -e "  ${GREEN}$label${NC}"
    if [[ -d "$dir" ]]; then
        for f in "$dir"/*; do
            if [[ -f "$f" ]]; then
                local name=$(basename "$f")
                local size=$(wc -c < "$f" | tr -d ' ')
                local size_kb=$(echo "scale=1; $size / 1024" | bc)
                printf "    %-20s %6s KB\n" "$name" "$size_kb"
            fi
        done
    fi
}

# Pause and wait for user
pause() {
    local message="${1:-Press Enter to continue...}"
    echo ""
    read -p "$(echo -e "  ${DIM}$message${NC}")" _
}

# =============================================================================
# Interactive Helpers (legacy)
# =============================================================================

pause_for_explanation() {
    local message="${1:-Press Enter to continue...}"
    echo ""
    read -p "$(echo -e ${CYAN}$message${NC})" _
}

confirm_continue() {
    local message="${1:-Continue?}"
    echo ""
    read -p "$(echo -e ${YELLOW}$message [Y/n]: ${NC})" response
    case "$response" in
        [nN][oO]|[nN])
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}
