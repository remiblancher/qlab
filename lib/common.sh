#!/bin/bash
# =============================================================================
# Common Functions for Post-Quantum PKI Lab
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/banner.sh"

# Get the lab root directory
LAB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# PKI binary location
PKI_BIN="${PKI_BIN:-pki}"

# Temporary directory for demo artifacts
DEMO_TMP="${DEMO_TMP:-/tmp/pqc-lab-demo-$$}"

# =============================================================================
# Setup and Cleanup
# =============================================================================

setup_demo() {
    local demo_name="$1"

    # Create temp directory
    mkdir -p "$DEMO_TMP"

    # Show banner
    show_banner "$demo_name"

    # Check PKI binary
    if ! command -v "$PKI_BIN" &> /dev/null; then
        print_error "PKI binary not found: $PKI_BIN"
        print_info "Run: ./tooling/install.sh"
        exit 1
    fi

    print_info "Demo artifacts: $DEMO_TMP"
    echo ""
}

cleanup_demo() {
    if [[ -d "$DEMO_TMP" ]]; then
        rm -rf "$DEMO_TMP"
    fi
}

trap cleanup_demo EXIT

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
    local start=$(date +%s%N)
    "$@" > /dev/null 2>&1
    local end=$(date +%s%N)
    echo $(( (end - start) / 1000000 ))
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
# Interactive Helpers
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
