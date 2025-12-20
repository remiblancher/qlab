#!/bin/bash
# =============================================================================
#  UC-04: "PKI operations don't change"
#
#  Demonstrate certificate revocation with post-quantum certificates
#
#  Key Message: Revoking a PQC certificate works exactly like classical.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "PKI-05: Revocation"

PQC_CA="$DEMO_TMP/pqc-ca"
CLASSIC_CA="$DEMO_TMP/classic-ca"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"A private key was compromised. How do we revoke the certificate?\""
echo ""
echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Create a Hybrid CA (ECDSA + ML-DSA) and issue a certificate"
echo "  2. Simulate a key compromise incident"
echo "  3. Revoke the certificate and generate CRL"
echo "  4. Compare CRL sizes (classical vs hybrid)"
echo "  5. Compare OCSP response sizes"
echo ""

pause_for_explanation "Press Enter to start the demo..."

# =============================================================================
# Step 1: Setup - Create CA and Issue Certificate
# =============================================================================

print_step "Step 1: Create Hybrid CA and Issue Certificate"

echo -e "Command:"
echo -e "  ${CYAN}pki init-ca --name \"Hybrid Root CA\" --algorithm ecdsa-p384 --hybrid-algorithm ml-dsa-65 --dir $PQC_CA${NC}"
echo ""

"$PKI_BIN" init-ca \
    --name "Hybrid Root CA" \
    --org "Demo Organization" \
    --algorithm ecdsa-p384 \
    --hybrid-algorithm ml-dsa-65 \
    --dir "$PQC_CA" > /dev/null 2>&1

echo -e "  ${CYAN}pki issue --ca-dir $PQC_CA --profile hybrid/catalyst/tls-server --cn server.example.com${NC}"
echo ""

"$PKI_BIN" issue \
    --ca-dir "$PQC_CA" \
    --profile hybrid/catalyst/tls-server \
    --cn "server.example.com" \
    --dns "server.example.com" \
    --out "$DEMO_TMP/server.crt" \
    --key-out "$DEMO_TMP/server.key" > /dev/null 2>&1

# Get serial number from certificate
SERIAL=$(openssl x509 -in "$DEMO_TMP/server.crt" -noout -serial 2>/dev/null | cut -d= -f2)

print_success "Certificate issued with serial: ${YELLOW}$SERIAL${NC}"

echo ""
echo -e "  ${CYAN}Inspect certificate:${NC} pki info $DEMO_TMP/server.crt"

# =============================================================================
# Step 2: Incident - Key Compromise
# =============================================================================

print_step "Step 2: Incident - Private Key Compromised!"

echo -e "  ${RED}⚠ ALERT: Private key for server.example.com was exposed!${NC}"
echo ""
echo "  Incident response steps:"
echo "    1. ✓ Detected compromise"
echo "    2. ✓ Identified affected certificate (serial: $SERIAL)"
echo "    3. → Revoke the certificate"
echo "    4. → Generate new CRL"
echo "    5. → Issue replacement certificate"
echo ""

pause_for_explanation "Press Enter to revoke the certificate..."

# =============================================================================
# Step 3: Revoke Certificate
# =============================================================================

print_step "Step 3: Revoke Certificate"

echo -e "Command:"
echo -e "  ${CYAN}pki revoke $SERIAL --ca-dir $PQC_CA --reason keyCompromise --gen-crl${NC}"
echo ""

"$PKI_BIN" revoke "$SERIAL" \
    --ca-dir "$PQC_CA" \
    --reason keyCompromise \
    --gen-crl

echo ""
print_success "Certificate revoked and CRL generated"

echo ""
echo -e "  ${CYAN}Inspect CRL:${NC} pki info $PQC_CA/crl/ca.crl"

# =============================================================================
# Step 4: Compare CRL Sizes
# =============================================================================

print_step "Step 4: Compare CRL Sizes (Classical vs Hybrid)"

# Create classical CA and generate its CRL
"$PKI_BIN" init-ca \
    --name "Classic Root CA" \
    --org "Demo Organization" \
    --algorithm ecdsa-p384 \
    --dir "$CLASSIC_CA" > /dev/null 2>&1

"$PKI_BIN" issue \
    --ca-dir "$CLASSIC_CA" \
    --profile ec/tls-server \
    --cn "classic.example.com" \
    --out "$DEMO_TMP/classic.crt" \
    --key-out "$DEMO_TMP/classic.key" > /dev/null 2>&1

CLASSIC_SERIAL=$(openssl x509 -in "$DEMO_TMP/classic.crt" -noout -serial 2>/dev/null | cut -d= -f2)

"$PKI_BIN" revoke "$CLASSIC_SERIAL" \
    --ca-dir "$CLASSIC_CA" \
    --reason keyCompromise \
    --gen-crl > /dev/null 2>&1

# Compare CRL sizes
CLASSIC_CRL_SIZE=$(wc -c < "$CLASSIC_CA/crl/ca.crl" | tr -d ' ')
HYBRID_CRL_SIZE=$(wc -c < "$PQC_CA/crl/ca.crl" | tr -d ' ')

print_comparison_header
echo -e "${BOLD}CRL (1 revoked certificate)${NC}"
print_comparison_row "  CRL size" "$CLASSIC_CRL_SIZE" "$HYBRID_CRL_SIZE" " B"

echo ""
echo -e "${CYAN}The hybrid CRL has identical size to classical (ECDSA signature).${NC}"
echo -e "${CYAN}Pure PQC CRLs would be ~3,200 bytes larger due to ML-DSA signature.${NC}"
echo ""

# =============================================================================
# Step 5: Compare OCSP Response Sizes
# =============================================================================

print_step "Step 5: Compare OCSP Response Sizes"

echo -e "${CYAN}OCSP = Real-time revocation status${NC}"
echo "  Each query returns a signed response for one certificate."
echo ""

# Generate OCSP response for classical (ECDSA) - CA-signed mode
echo -e "${CYAN}Generating classical OCSP response (ECDSA P-384)...${NC}"
echo -e "Command:"
echo -e "  ${CYAN}pki ocsp sign --serial $CLASSIC_SERIAL --status revoked --ca ca.crt --key private/ca.key${NC}"
echo ""

"$PKI_BIN" ocsp sign \
    --serial "$CLASSIC_SERIAL" \
    --status revoked \
    --revocation-reason keyCompromise \
    --ca "$CLASSIC_CA/ca.crt" \
    --key "$CLASSIC_CA/private/ca.key" \
    -o "$DEMO_TMP/classic-response.ocsp" > /dev/null 2>&1

# Generate OCSP response for hybrid CA
echo -e "${CYAN}Generating hybrid OCSP response (ECDSA P-384 + ML-DSA extension)...${NC}"

"$PKI_BIN" ocsp sign \
    --serial "$SERIAL" \
    --status revoked \
    --revocation-reason keyCompromise \
    --ca "$PQC_CA/ca.crt" \
    --key "$PQC_CA/private/ca.key" \
    -o "$DEMO_TMP/hybrid-response.ocsp" > /dev/null 2>&1

CLASSIC_OCSP_SIZE=$(wc -c < "$DEMO_TMP/classic-response.ocsp" | tr -d ' ')
HYBRID_OCSP_SIZE=$(wc -c < "$DEMO_TMP/hybrid-response.ocsp" | tr -d ' ')

# Calculate what pure PQC OCSP would be (hybrid + ML-DSA signature overhead)
# ML-DSA-65 signature: ~3,293 bytes vs ECDSA P-384: ~96 bytes
PQC_SIG_OVERHEAD=3197
PQC_OCSP_SIZE=$((CLASSIC_OCSP_SIZE + PQC_SIG_OVERHEAD))

echo ""
echo -e "${BOLD}OCSP Response (1 certificate status)${NC}"
print_comparison_row "  Classical" "$CLASSIC_OCSP_SIZE" "" " B"
print_comparison_row "  Hybrid" "$HYBRID_OCSP_SIZE" "" " B"
print_comparison_row "  Pure PQC (est.)" "$PQC_OCSP_SIZE" "" " B"

echo ""
echo -e "${CYAN}Hybrid OCSP uses ECDSA signature (same size as classical).${NC}"
echo -e "${CYAN}Pure PQC would add ~3,200 bytes for ML-DSA signature.${NC}"
echo ""
echo -e "  ${CYAN}Inspect OCSP response:${NC} pki ocsp info $DEMO_TMP/hybrid-response.ocsp"
echo ""

# =============================================================================
# Key Message
# =============================================================================

print_key_message "Revoking a PQC certificate works exactly like revoking a classical one."

echo -e "${BOLD}What stayed the same:${NC}"
echo "  - Revocation workflow"
echo "  - CRL structure (X.509)"
echo "  - Revocation reasons"
echo "  - Distribution methods"
echo ""

echo -e "${BOLD}What changed:${NC}"
echo "  - CRL signature size (larger with PQC)"
echo "  - OCSP response size (larger with PQC)"
echo ""

# =============================================================================
# Lesson Learned
# =============================================================================

show_lesson "PKI operations are algorithm-agnostic.
Your incident response runbooks still apply.
No retraining needed for operations teams."

show_footer
