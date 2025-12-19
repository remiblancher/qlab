#!/bin/bash
# =============================================================================
#  UC-02: "Hybrid = best of both worlds"
#
#  Demonstrate hybrid certificates (Catalyst) combining classical + PQC
#
#  Key Message: You don't choose between classical and PQC. You stack them.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "UC-02: Hybrid = best of both worlds"

HYBRID_CA="$DEMO_TMP/hybrid-ca"
CLASSIC_CA="$DEMO_TMP/classic-ca"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"I need to stay compatible with legacy clients,"
echo "   while being quantum-ready for modern ones.\""
echo ""
echo -e "${BOLD}THE SOLUTION:${NC}"
echo "  Hybrid certificates (Catalyst) contain TWO key pairs:"
echo "    - Classical (ECDSA) for legacy clients"
echo "    - Post-quantum (ML-DSA) for PQC-aware clients"
echo ""
echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Create a hybrid CA (ECDSA P-384 + ML-DSA-65)"
echo "  2. Issue a hybrid TLS server certificate"
echo "  3. Examine the certificate structure"
echo "  4. Compare sizes with classical-only certificate"
echo ""

pause_for_explanation "Press Enter to start the demo..."

# =============================================================================
# Step 1: Create Hybrid CA
# =============================================================================

print_step "Step 1: Create Hybrid CA (ECDSA P-384 + ML-DSA-65)"

echo -e "${CYAN}Hybrid (Catalyst) certificates follow ITU-T X.509 Section 9.8${NC}"
echo "  - Single certificate with dual keys"
echo "  - Classical signature for backwards compatibility"
echo "  - PQC signature in extension for future security"
echo ""

echo -e "Command:"
echo -e "  ${CYAN}pki init-ca --name \"Hybrid Root CA\" --algorithm ecdsa-p384 \\"
echo -e "      --hybrid-algorithm ml-dsa-65 --dir $HYBRID_CA${NC}"
echo ""

HYBRID_CA_TIME=$(time_cmd "$PKI_BIN" init-ca \
    --name "Hybrid Root CA" \
    --org "Demo Organization" \
    --algorithm ecdsa-p384 \
    --hybrid-algorithm ml-dsa-65 \
    --dir "$HYBRID_CA")

print_success "Hybrid CA created in ${YELLOW}${HYBRID_CA_TIME}ms${NC}"

# =============================================================================
# Step 2: Issue Hybrid TLS Certificate
# =============================================================================

print_step "Step 2: Issue Hybrid TLS Server Certificate"

echo -e "Command:"
echo -e "  ${CYAN}pki issue --ca-dir $HYBRID_CA \\"
echo -e "      --profile hybrid/catalyst/tls-server \\"
echo -e "      --cn hybrid.example.com${NC}"
echo ""

HYBRID_CERT_TIME=$(time_cmd "$PKI_BIN" issue \
    --ca-dir "$HYBRID_CA" \
    --profile hybrid/catalyst/tls-server \
    --cn "hybrid.example.com" \
    --dns "hybrid.example.com,www.hybrid.example.com" \
    --out "$DEMO_TMP/hybrid-server.crt" \
    --key-out "$DEMO_TMP/hybrid-server.key")

print_success "Hybrid certificate issued in ${YELLOW}${HYBRID_CERT_TIME}ms${NC}"

show_cert_brief "$DEMO_TMP/hybrid-server.crt" "Hybrid TLS Certificate"

echo ""
echo -e "  ${CYAN}Inspect certificate:${NC} pki info $DEMO_TMP/hybrid-server.crt"

# =============================================================================
# Step 3: Examine Certificate Structure
# =============================================================================

print_step "Step 3: Examine Hybrid Certificate Structure"

echo -e "${CYAN}The hybrid certificate contains:${NC}"
echo ""
echo "  +------------------------------------------+"
echo "  | X.509 Certificate                        |"
echo "  |------------------------------------------|"
echo "  | Subject: CN=hybrid.example.com           |"
echo "  | Public Key: ECDSA P-384 (classical)      |"
echo "  | Signature: ECDSA P-384 (classical)       |"
echo "  |------------------------------------------|"
echo "  | Extension: Alternative Public Key        |"
echo "  |   Algorithm: ML-DSA-65 (post-quantum)    |"
echo "  |   Key: [1952 bytes]                      |"
echo "  |------------------------------------------|"
echo "  | Extension: Alternative Signature         |"
echo "  |   Algorithm: ML-DSA-65 (post-quantum)    |"
echo "  |   Signature: [3293 bytes]                |"
echo "  +------------------------------------------+"
echo ""

echo -e "${BOLD}How it works:${NC}"
echo "  - Legacy clients: Use classical key + signature (ignore extensions)"
echo "  - PQC-aware clients: Verify BOTH signatures for full security"
echo ""

# =============================================================================
# Step 4: Create Classical CA for Comparison
# =============================================================================

print_step "Step 4: Compare with Classical-Only CA"

# Create classical CA
"$PKI_BIN" init-ca \
    --name "Classic Root CA" \
    --org "Demo Organization" \
    --algorithm ecdsa-p384 \
    --dir "$CLASSIC_CA" > /dev/null 2>&1

# Get CA certificate sizes (CA certs contain the full hybrid structure)
CLASSIC_CA_CERT_SIZE=$(cert_size "$CLASSIC_CA/ca.crt")
HYBRID_CA_CERT_SIZE=$(cert_size "$HYBRID_CA/ca.crt")

print_comparison_header

echo -e "${BOLD}CA Certificate (Root)${NC}"
print_comparison_row "  Cert size" "$CLASSIC_CA_CERT_SIZE" "$HYBRID_CA_CERT_SIZE" " B"

echo ""
echo -e "${CYAN}The hybrid CA certificate is ~7x larger because it contains:${NC}"
echo "  - Original ECDSA public key + signature"
echo "  - Alternative ML-DSA public key (~1952 bytes)"
echo "  - Alternative ML-DSA signature (~3293 bytes)"
echo ""
echo -e "${YELLOW}Note:${NC} The hybrid extensions are in the CA certificate."
echo "      End-entity certs inherit quantum protection from the CA chain."
echo ""

# =============================================================================
# Key Message
# =============================================================================

print_key_message "You don't choose between classical and PQC. You stack them."

echo -e "${BOLD}Why hybrid certificates?${NC}"
echo "  - ${GREEN}Backwards compatible${NC}: Legacy clients work unchanged"
echo "  - ${GREEN}Future-proof${NC}: PQC protection against quantum attacks"
echo "  - ${GREEN}Belt and suspenders${NC}: If one algorithm breaks, the other still protects"
echo "  - ${GREEN}Smooth migration${NC}: No flag day required"
echo ""

echo -e "${BOLD}When to use hybrid:${NC}"
echo "  - During PQC transition period (now!)"
echo "  - When you can't control all clients"
echo "  - When regulatory compliance requires classical algorithms"
echo "  - For critical infrastructure requiring defense in depth"
echo ""

# =============================================================================
# Lesson Learned
# =============================================================================

show_lesson "Hybrid certificates give you the best of both worlds.
Classical security today, quantum security tomorrow.
No need to choose - stack them for defense in depth."

show_footer
