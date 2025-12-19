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
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "UC-04: PKI operations don't change"

PQC_CA="$DEMO_TMP/pqc-ca"
CLASSIC_CA="$DEMO_TMP/classic-ca"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"A private key was compromised. How do we revoke the certificate?\""
echo ""
echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Create a PQC CA and issue a certificate"
echo "  2. Simulate a key compromise incident"
echo "  3. Revoke the certificate and generate CRL"
echo "  4. Compare CRL sizes (classical vs PQC)"
echo ""

pause_for_explanation "Press Enter to start the demo..."

# =============================================================================
# Step 1: Setup - Create CA and Issue Certificate
# =============================================================================

print_step "Step 1: Create PQC CA and Issue Certificate"

echo -e "Command:"
echo -e "  ${CYAN}pki init-ca --name \"PQC Root CA\" --algorithm ml-dsa-65 --dir $PQC_CA${NC}"
echo ""

"$PKI_BIN" init-ca \
    --name "PQC Root CA" \
    --org "Demo Organization" \
    --algorithm ml-dsa-65 \
    --dir "$PQC_CA" > /dev/null 2>&1

echo -e "  ${CYAN}pki issue --ca-dir $PQC_CA --profile ml-dsa-kem/tls-server --cn server.example.com${NC}"
echo ""

"$PKI_BIN" issue \
    --ca-dir "$PQC_CA" \
    --profile ml-dsa-kem/tls-server \
    --cn "server.example.com" \
    --dns "server.example.com" \
    --out "$DEMO_TMP/server.crt" \
    --key-out "$DEMO_TMP/server.key" > /dev/null 2>&1

# Get serial number from certificate
SERIAL=$(openssl x509 -in "$DEMO_TMP/server.crt" -noout -serial 2>/dev/null | cut -d= -f2)

print_success "Certificate issued with serial: ${YELLOW}$SERIAL${NC}"

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

# =============================================================================
# Step 4: Compare CRL Sizes
# =============================================================================

print_step "Step 4: Compare CRL Sizes (Classical vs PQC)"

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
CLASSIC_CRL_SIZE=$(wc -c < "$CLASSIC_CA/ca.crl" | tr -d ' ')
PQC_CRL_SIZE=$(wc -c < "$PQC_CA/ca.crl" | tr -d ' ')

print_comparison_header
echo -e "${BOLD}CRL (1 revoked certificate)${NC}"
print_comparison_row "  CRL size" "$CLASSIC_CRL_SIZE" "$PQC_CRL_SIZE" " B"

echo ""
echo -e "${CYAN}The PQC CRL is larger due to the ML-DSA signature (~3,293 bytes).${NC}"
echo "  But the workflow is identical!"
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
echo ""

# =============================================================================
# Lesson Learned
# =============================================================================

show_lesson "PKI operations are algorithm-agnostic.
Your incident response runbooks still apply.
No retraining needed for operations teams."

show_footer
