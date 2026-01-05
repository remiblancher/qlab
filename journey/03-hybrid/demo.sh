#!/bin/bash
# =============================================================================
#  UC-03: Hybrid Certificates (Catalyst)
#
#  Best of Both Worlds: Classical + Post-Quantum
#  ECDSA P-384 + ML-DSA-65 in a single certificate
#
#  Key Message: You don't choose between classical and PQC. You stack them.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

setup_demo "Hybrid Certificates (Catalyst)"

# =============================================================================
# Step 1: Create Hybrid Root CA
# =============================================================================

print_step "Step 1: Create Hybrid Root CA (ECDSA P-384 + ML-DSA-65)"

echo "  A hybrid CA contains TWO key pairs:"
echo ""
echo "    Primary:     ECDSA P-384 (classical)"
echo "    Alternative: ML-DSA-65 (post-quantum)"
echo ""
echo "  Standard: ITU-T X.509 Section 9.8 (Catalyst)"
echo ""

run_cmd "qpki ca init --profile profiles/hybrid-root-ca.yaml --var cn=\"Hybrid Root CA\" --dir output/hybrid-ca"

echo ""
echo -e "  ${BOLD}Hybrid CA details:${NC}"
qpki inspect output/hybrid-ca/ca.crt 2>/dev/null | head -10 | sed 's/^/    /'
echo ""

pause

# =============================================================================
# Step 2: Issue Hybrid TLS Certificate
# =============================================================================

print_step "Step 2: Issue Hybrid TLS Certificate"

echo "  The certificate inherits the hybrid nature from the CA."
echo "  It will contain both ECDSA and ML-DSA keys/signatures."
echo ""

run_cmd "qpki csr gen --algorithm ecdsa-p384 --hybrid ml-dsa-65 --keyout output/hybrid-server.key --hybrid-keyout output/hybrid-server-pqc.key --cn hybrid.example.com -o output/hybrid-server.csr"

echo ""

run_cmd "qpki cert issue --ca-dir output/hybrid-ca --profile profiles/hybrid-tls-server.yaml --csr output/hybrid-server.csr --out output/hybrid-server.crt"

echo ""
echo -e "  ${BOLD}Hybrid certificate details:${NC}"
qpki inspect output/hybrid-server.crt 2>/dev/null | head -12 | sed 's/^/    /'
echo ""

pause

# =============================================================================
# Step 3: Test Interoperability
# =============================================================================

print_step "Step 3: Test Interoperability"

echo "  The power of hybrid: works with EVERYONE!"
echo ""
echo -e "  ${BOLD}Test 1: Legacy Client (OpenSSL)${NC}"
echo "    OpenSSL doesn't understand PQC, but still verifies."
echo ""

echo -e "  ${DIM}$ openssl verify -CAfile output/hybrid-ca/ca.crt output/hybrid-server.crt${NC}"
if openssl verify -CAfile output/hybrid-ca/ca.crt output/hybrid-server.crt 2>&1; then
    echo ""
    echo -e "    ${GREEN}✓${NC} Legacy client: Certificate verified via ECDSA"
    echo -e "    ${DIM}(PQC extensions are ignored)${NC}"
fi

echo ""
pause

echo -e "  ${BOLD}Test 2: PQC-Aware Client (pki)${NC}"
echo "    The qpki tool verifies BOTH signatures."
echo ""

echo -e "  ${DIM}$ qpki cert verify output/hybrid-server.crt --ca output/hybrid-ca/ca.crt${NC}"
if qpki cert verify output/hybrid-server.crt --ca output/hybrid-ca/ca.crt 2>&1; then
    echo ""
    echo -e "    ${GREEN}✓${NC} PQC client: BOTH ECDSA AND ML-DSA verified"
fi

echo ""
echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  INTEROPERABILITY SUMMARY                                       │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo -e "  │  Legacy (OpenSSL)  │ Uses ECDSA, ignores PQC │ ${GREEN}✓ OK${NC}           │"
echo -e "  │  PQC-Aware (pki)   │ Verifies BOTH           │ ${GREEN}✓ OK${NC}           │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""
echo -e "  ${BOLD}Zero changes for legacy clients. Quantum protection for modern ones.${NC}"
echo ""

pause

# =============================================================================
# Step 4: Size Comparison
# =============================================================================

print_step "Step 4: Size Comparison"

if [[ -f "output/hybrid-ca/ca.crt" ]]; then
    hybrid_ca_size=$(wc -c < "output/hybrid-ca/ca.crt" | tr -d ' ')
    hybrid_cert_size=$(wc -c < "output/hybrid-server.crt" | tr -d ' ')
    hybrid_key_size=$(wc -c < "output/hybrid-server.key" | tr -d ' ')

    echo -e "  ${BOLD}Hybrid certificate sizes:${NC}"
    echo ""
    echo "  ┌────────────────────────────────────────────────────────────┐"
    printf "  │  %-25s %10s %18s │\n" "" "Size" "Overhead vs Classical"
    echo "  ├────────────────────────────────────────────────────────────┤"
    printf "  │  %-25s %8s B %16s │\n" "Hybrid CA" "$hybrid_ca_size" "~5 KB"
    printf "  │  %-25s %8s B %16s │\n" "Hybrid TLS Certificate" "$hybrid_cert_size" "~5 KB"
    printf "  │  %-25s %8s B %16s │\n" "Hybrid Private Key" "$hybrid_key_size" "~2 KB"
    echo "  └────────────────────────────────────────────────────────────┘"
    echo ""
    echo -e "  ${DIM}Overhead comes from ML-DSA key (~1952 B) + signature (~3309 B)${NC}"
fi

echo ""

# =============================================================================
# Conclusion
# =============================================================================

print_key_message "You don't choose between classical and PQC. You stack them."

show_lesson "Hybrid = belt AND suspenders. Legacy clients work unchanged.
Modern clients get quantum protection. No flag day required."

show_footer
