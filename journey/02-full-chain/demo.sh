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

# =============================================================================
# Step 1: Create Root CA (ML-DSA-87)
# =============================================================================

print_step "Step 1: Create Root CA (ML-DSA-87)"

echo "  The Root CA is the trust anchor of your PKI."
echo "  It uses ML-DSA-87 (NIST Level 5) for maximum security."
echo ""

run_cmd "qpki ca init --profile profiles/pqc-root-ca.yaml --name \"PQC Root CA\" --dir output/pqc-root-ca"

echo ""
echo -e "  ${BOLD}Root CA details:${NC}"
qpki inspect output/pqc-root-ca/ca.crt 2>/dev/null | head -8 | sed 's/^/    /'
echo ""

pause

# =============================================================================
# Step 2: Create Issuing CA (ML-DSA-65)
# =============================================================================

print_step "Step 2: Create Issuing CA (ML-DSA-65)"

echo "  The Issuing CA issues end-entity certificates."
echo "  It uses ML-DSA-65 (NIST Level 3) - good balance of security/performance."
echo ""

run_cmd "qpki ca init --profile profiles/pqc-issuing-ca.yaml --name \"PQC Issuing CA\" --parent output/pqc-root-ca --dir output/pqc-issuing-ca"

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
# Step 3: Issue TLS Server Certificate
# =============================================================================

print_step "Step 3: Issue TLS Server Certificate"

echo "  The TLS server certificate uses ML-DSA-65 for authentication."
echo ""

run_cmd "qpki csr gen --algorithm ml-dsa-65 --keyout output/server.key --cn server.example.com -o output/server.csr"

echo ""

run_cmd "qpki cert issue --ca-dir output/pqc-issuing-ca --profile profiles/pqc-tls-server.yaml --csr output/server.csr --out output/server.crt"

echo ""
echo -e "  ${BOLD}Certificate details:${NC}"
qpki inspect output/server.crt 2>/dev/null | head -10 | sed 's/^/    /'
echo ""

pause

# =============================================================================
# Step 4: Examine the Chain
# =============================================================================

print_step "Step 4: Examine the Complete Chain"

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
if [[ -f "output/pqc-root-ca/ca.crt" ]]; then
    root_size=$(wc -c < "output/pqc-root-ca/ca.crt" | tr -d ' ')
    issuing_size=$(wc -c < "output/pqc-issuing-ca/ca.crt" | tr -d ' ')
    server_size=$(wc -c < "output/server.crt" | tr -d ' ')
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
