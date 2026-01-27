#!/bin/bash
# =============================================================================
#  UC-02: Full PQC Chain of Trust
#
#  Build a complete quantum-resistant PKI hierarchy
#  Root CA → Issuing CA → TLS Server
#
#  Key Message: Build a complete quantum-resistant PKI from root to end-entity.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

setup_demo "Full PQC Chain of Trust"

PROFILES="$SCRIPT_DIR/profiles"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"I need a complete PKI hierarchy with post-quantum cryptography."
echo "   How do I set up Root CA, Issuing CA, and end-entity certificates?\""
echo ""

echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Create a Root CA (ML-DSA-87 - highest security)"
echo "  2. Create an Issuing CA signed by the Root (ML-DSA-65)"
echo "  3. Generate a server key and CSR"
echo "  4. Issue a TLS server certificate"
echo "  5. Examine the complete chain"
echo ""

echo -e "${DIM}Root CA uses Level 5, Issuing CA uses Level 3 for performance.${NC}"
echo ""

pause "Press Enter to start..."

# =============================================================================
# Step 1: Create Root CA (ML-DSA-87)
# =============================================================================

print_step "Step 1: Create Root CA (ML-DSA-87)"

echo "  The Root CA is the trust anchor of your PKI."
echo "  It uses ML-DSA-87 (NIST Level 5) for maximum security."
echo ""

run_cmd "$PKI_BIN ca init --profile $PROFILES/pqc-root-ca.yaml --var cn=\"PQC Root CA\" --ca-dir $DEMO_TMP/pqc-root-ca"

echo ""

pause

# =============================================================================
# Step 2: Create Issuing CA (ML-DSA-65)
# =============================================================================

print_step "Step 2: Create Issuing CA (ML-DSA-65)"

echo "  The Issuing CA issues end-entity certificates."
echo "  It uses ML-DSA-65 (NIST Level 3) - good balance of security/performance."
echo ""

run_cmd "$PKI_BIN ca init --profile $PROFILES/pqc-issuing-ca.yaml --var cn=\"PQC Issuing CA\" --parent $DEMO_TMP/pqc-root-ca --ca-dir $DEMO_TMP/pqc-issuing-ca"

echo ""
echo -e "  ${BOLD}Chain visualization:${NC}"
echo ""
echo "    Root CA (ML-DSA-87)"
echo "        │"
echo "        └── signs"
echo "              │"
echo "              ▼"
echo "    Issuing CA (ML-DSA-65)"
echo ""

pause

# =============================================================================
# Step 3: Generate Server Key and CSR
# =============================================================================

print_step "Step 3: Generate Server Key and CSR"

echo "  Generate an ML-DSA-65 key pair and Certificate Signing Request."
echo ""

run_cmd "$PKI_BIN csr gen --algorithm ml-dsa-65 --keyout $DEMO_TMP/server.key --cn server.example.com --out $DEMO_TMP/server.csr"

echo ""

pause

# =============================================================================
# Step 4: Issue TLS Server Certificate
# =============================================================================

print_step "Step 4: Issue TLS Server Certificate"

echo "  The TLS server certificate uses ML-DSA-65 for authentication."
echo ""

run_cmd "$PKI_BIN cert issue --ca-dir $DEMO_TMP/pqc-issuing-ca --profile $PROFILES/pqc-tls-server.yaml --csr $DEMO_TMP/server.csr --out $DEMO_TMP/server.crt"

echo ""

pause

# =============================================================================
# Step 5: Examine the Chain
# =============================================================================

print_step "Step 5: Examine the Complete Chain"

echo "  Your complete PQC PKI hierarchy:"
echo ""
echo "  ┌─────────────────────────────────────────┐"
echo "  │           PQC Root CA                   │"
echo "  │           ML-DSA-87                     │"
echo "  │       (NIST Level 5 - maximum)          │"
echo "  └─────────────────┬───────────────────────┘"
echo "                    │ signs"
echo "                    ▼"
echo "  ┌─────────────────────────────────────────┐"
echo "  │         PQC Issuing CA                  │"
echo "  │           ML-DSA-65                     │"
echo "  │          (NIST Level 3)                 │"
echo "  └─────────────────┬───────────────────────┘"
echo "                    │ signs"
echo "                    ▼"
echo "  ┌─────────────────────────────────────────┐"
echo "  │       TLS Server Certificate            │"
echo "  │           ML-DSA-65                     │"
echo "  │          (NIST Level 3)                 │"
echo "  └─────────────────────────────────────────┘"
echo ""

# Certificate sizes
if [[ -f "$DEMO_TMP/pqc-root-ca/ca.crt" ]]; then
    root_size=$(wc -c < "$DEMO_TMP/pqc-root-ca/ca.crt" | tr -d ' ')
    issuing_size=$(wc -c < "$DEMO_TMP/pqc-issuing-ca/ca.crt" | tr -d ' ')
    server_size=$(wc -c < "$DEMO_TMP/server.crt" | tr -d ' ')
    chain_total=$((root_size + issuing_size + server_size))

    echo -e "  ${BOLD}Certificate sizes:${NC}"
    echo ""
    printf "    %-25s %8s\n" "Root CA (ML-DSA-87)" "$root_size B"
    printf "    %-25s %8s\n" "Issuing CA (ML-DSA-65)" "$issuing_size B"
    printf "    %-25s %8s\n" "TLS Server" "$server_size B"
    echo "    ─────────────────────────────────"
    printf "    %-25s %8s\n" "FULL CHAIN" "$chain_total B"
    echo ""
    echo -e "  ${DIM}~6x larger than classical ECDSA. The price of quantum resistance.${NC}"
fi

# =============================================================================
# Conclusion
# =============================================================================

print_key_message "Build a complete quantum-resistant PKI from root to end-entity."

show_lesson "Same PKI workflow, different algorithms. Root uses highest security level.
See README.md for algorithm selection guide."

show_footer
