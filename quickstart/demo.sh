#!/bin/bash
# =============================================================================
#  QUICK START: My First PKI (10 minutes)
#
#  Create your first CA and issue a TLS certificate.
#  Algorithm: ECDSA P-384 (classical)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$LAB_ROOT/lib/colors.sh"
source "$LAB_ROOT/lib/interactive.sh"
source "$LAB_ROOT/lib/workspace.sh"

PKI_BIN="$LAB_ROOT/bin/pki"

# =============================================================================
# Check prerequisites
# =============================================================================

check_pki_installed() {
    if [[ ! -x "$PKI_BIN" ]]; then
        echo ""
        echo -e "${RED}[ERROR]${NC} PKI tool not installed"
        echo ""
        echo "  Run: ${CYAN}./tooling/install.sh${NC}"
        echo ""
        exit 1
    fi
}

# =============================================================================
# Welcome
# =============================================================================

show_welcome() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}"
    echo "  =============================================="
    echo "   QUICK START: My First PKI"
    echo "  =============================================="
    echo -e "${NC}"
    echo ""
    echo "  You will:"
    echo "    1. Create a Certificate Authority (CA)"
    echo "    2. Issue a TLS certificate"
    echo "    3. Verify the certificate"
    echo "    4. Compare with Post-Quantum"
    echo ""
    echo -e "  ${DIM}Duration: ~10 minutes${NC}"
    echo ""
}

# =============================================================================
# Step 1: Create CA
# =============================================================================

step_1_create_ca() {
    step 1 "Create your Certificate Authority (CA)"

    echo "  A CA is the root of trust. It signs all certificates."
    echo ""
    echo "  A CA has:"
    echo "    - ca.key: private key (keep secret!)"
    echo "    - ca.crt: self-signed certificate (distribute)"
    echo ""

    local ca_dir="$LEVEL_WORKSPACE/classic-ca"

    if [[ -f "$ca_dir/ca.crt" ]]; then
        info "CA already exists, reusing it."
        validate_files "$ca_dir" "ca.crt" "ca.key"
        return 0
    fi

    run_cmd "$PKI_BIN init-ca --name 'My First CA' --algorithm ecdsa-p384 --dir $ca_dir" \
            "Creating CA with ECDSA P-384..."

    validate_files "$ca_dir" "ca.crt" "ca.key" "index.txt" "serial"
}

# =============================================================================
# Step 2: Issue TLS certificate
# =============================================================================

step_2_issue_cert() {
    step 2 "Issue a TLS certificate"

    echo "  A TLS certificate proves server identity."
    echo ""
    echo "  We need:"
    echo "    - Common Name (CN): server name"
    echo "    - DNS SAN: domain names"
    echo "    - Profile: ec/tls-server"
    echo ""

    local ca_dir="$LEVEL_WORKSPACE/classic-ca"
    local cert_out="$LEVEL_WORKSPACE/server.crt"
    local key_out="$LEVEL_WORKSPACE/server.key"

    if [[ -f "$cert_out" ]]; then
        info "Certificate already exists."
        validate_file "$cert_out" "Server certificate"
        validate_file "$key_out" "Server private key"
        return 0
    fi

    run_cmd "$PKI_BIN issue --ca-dir $ca_dir --profile ec/tls-server --cn 'my-server.local' --dns 'my-server.local' --out $cert_out --key-out $key_out" \
            "Issuing TLS certificate..."

    validate_file "$cert_out" "Server certificate"
    validate_file "$key_out" "Server private key"

    echo ""
    echo -e "${BOLD}Certificate details:${NC}"
    "$PKI_BIN" info "$cert_out" 2>/dev/null | head -10 | sed 's/^/  /'
}

# =============================================================================
# Step 3: Verify certificate
# =============================================================================

step_3_verify() {
    step 3 "Verify the certificate"

    echo "  Verification checks:"
    echo "    - CA signature is valid"
    echo "    - Certificate not expired"
    echo "    - Chain of trust is complete"
    echo ""

    local ca_dir="$LEVEL_WORKSPACE/classic-ca"
    local cert_file="$LEVEL_WORKSPACE/server.crt"

    run_cmd "$PKI_BIN verify --ca $ca_dir/ca.crt --cert $cert_file" \
            "Verifying certificate chain..."
}

# =============================================================================
# Step 4: Compare with Post-Quantum
# =============================================================================

step_4_compare_pqc() {
    step 4 "Compare with Post-Quantum"

    echo "  Post-Quantum algorithms resist quantum computer attacks."
    echo ""
    echo "  ML-DSA (FIPS 204): lattice-based signatures"
    echo "  ML-KEM (FIPS 203): lattice-based key exchange"
    echo ""

    local pqc_ca="$LEVEL_WORKSPACE/pqc-ca-demo"

    run_cmd "$PKI_BIN init-ca --name 'PQC Demo CA' --algorithm ml-dsa-65 --dir $pqc_ca" \
            "Creating PQC CA with ML-DSA-65..."

    run_cmd "$PKI_BIN issue --ca-dir $pqc_ca --profile ml-dsa/tls-server --cn 'pqc-server.local' --dns 'pqc-server.local' --out $LEVEL_WORKSPACE/pqc-server.crt --key-out $LEVEL_WORKSPACE/pqc-server.key" \
            "Issuing PQC certificate..."

    # Size comparison
    local classic_cert=$(wc -c < "$LEVEL_WORKSPACE/server.crt" | tr -d ' ')
    local classic_key=$(wc -c < "$LEVEL_WORKSPACE/server.key" | tr -d ' ')
    local pqc_cert=$(wc -c < "$LEVEL_WORKSPACE/pqc-server.crt" | tr -d ' ')
    local pqc_key=$(wc -c < "$LEVEL_WORKSPACE/pqc-server.key" | tr -d ' ')

    echo ""
    echo -e "${BOLD}Size comparison:${NC}"
    echo ""
    printf "  %-20s %10s %10s %10s\n" "" "ECDSA" "ML-DSA" "Ratio"
    printf "  %-20s %10s %10s %10s\n" "----" "-----" "------" "-----"

    local cert_ratio=$(echo "scale=1; $pqc_cert / $classic_cert" | bc)
    printf "  %-20s %8s B %8s B %8sx\n" "Certificate" "$classic_cert" "$pqc_cert" "$cert_ratio"

    local key_ratio=$(echo "scale=1; $pqc_key / $classic_key" | bc)
    printf "  %-20s %8s B %8s B %8sx\n" "Private Key" "$classic_key" "$pqc_key" "$key_ratio"

    echo ""
    warn "PQC certificates are larger (~${cert_ratio}x) but quantum-resistant."
}

# =============================================================================
# Summary
# =============================================================================

show_final() {
    echo ""
    echo -e "${BOLD}${GREEN}=== QUICK START COMPLETE ===${NC}"

    show_summary "What you accomplished:" \
        "Created a CA (ECDSA P-384)" \
        "Issued a TLS certificate" \
        "Verified the chain of trust" \
        "Compared classical vs post-quantum sizes"

    echo -e "  ${BOLD}Your files:${NC} ${CYAN}$LEVEL_WORKSPACE/${NC}"
    echo ""

    show_takeaway "The PKI model is the same. Only the algorithm changes.
Migrating to PQC is an engineering problem, not magic."

    show_next "./journey/00-revelation/demo.sh" "The Revelation: Why PQC matters"
}

# =============================================================================
# Main
# =============================================================================

main() {
    check_pki_installed
    init_workspace "quickstart"

    show_welcome
    wait_enter

    step_1_create_ca
    wait_enter

    step_2_issue_cert
    wait_enter

    step_3_verify
    wait_enter

    step_4_compare_pqc

    show_final
}

main "$@"
