#!/bin/bash
# =============================================================================
#  UC-06: "Signatures that outlive the threat"
#
#  Post-Quantum Code Signing Certificates
#
#  Key Message: Software signatures must remain valid for years.
#               PQC ensures they can't be forged by future quantum computers.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "UC-06: Signatures that outlive the threat"

CLASSIC_CA="$DEMO_TMP/classic-code-ca"
PQC_CA="$DEMO_TMP/pqc-code-ca"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"We sign our software releases."
echo "   How long do those signatures need to be valid?\""
echo ""
echo -e "${BOLD}THE PROBLEM:${NC}"
echo "  - A signed binary from 2024 might still be verified in 2034"
echo "  - If quantum computers can forge ECDSA signatures by then..."
echo "  - Attackers could create malicious software that appears legitimate"
echo ""
echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Create a classical code signing CA (ECDSA)"
echo "  2. Create a PQC code signing CA (ML-DSA-65)"
echo "  3. Issue code signing certificates"
echo "  4. Sign a binary with both (CMS format)"
echo "  5. Verify the signatures"
echo "  6. Compare signature sizes"
echo ""

pause_for_explanation "Press Enter to start the demo..."

# =============================================================================
# Step 1: Create Classical Code Signing CA
# =============================================================================

print_step "Step 1: Create Classical Code Signing CA (ECDSA P-384)"

echo -e "Command:"
echo -e "  ${CYAN}pki init-ca --name \"Classic Code Signing CA\" --algorithm ecdsa-p384 --dir $CLASSIC_CA${NC}"
echo ""

CLASSIC_CA_TIME=$(time_cmd "$PKI_BIN" init-ca \
    --name "Classic Code Signing CA" \
    --org "Demo Organization" \
    --algorithm ecdsa-p384 \
    --dir "$CLASSIC_CA")

print_success "Classical CA created in ${YELLOW}${CLASSIC_CA_TIME}ms${NC}"

# =============================================================================
# Step 2: Create PQC Code Signing CA
# =============================================================================

print_step "Step 2: Create PQC Code Signing CA (ML-DSA-65)"

echo -e "${CYAN}Why ML-DSA-65 for code signing?${NC}"
echo "  - Signatures remain valid for 10+ years"
echo "  - Quantum computers can't forge them"
echo "  - NIST Level 3 security (~192-bit equivalent)"
echo ""

echo -e "Command:"
echo -e "  ${CYAN}pki init-ca --name \"PQC Code Signing CA\" --algorithm ml-dsa-65 --dir $PQC_CA${NC}"
echo ""

PQC_CA_TIME=$(time_cmd "$PKI_BIN" init-ca \
    --name "PQC Code Signing CA" \
    --org "Demo Organization" \
    --algorithm ml-dsa-65 \
    --dir "$PQC_CA")

print_success "PQC CA created in ${YELLOW}${PQC_CA_TIME}ms${NC}"

# =============================================================================
# Step 3: Issue Code Signing Certificates
# =============================================================================

print_step "Step 3: Issue Code Signing Certificates"

echo -e "${CYAN}Issuing classical code signing certificate...${NC}"

CLASSIC_CERT_TIME=$(time_cmd "$PKI_BIN" issue \
    --ca-dir "$CLASSIC_CA" \
    --profile ec/code-signing \
    --cn "ACME Software (Classical)" \
    --out "$DEMO_TMP/classic-code.crt" \
    --key-out "$DEMO_TMP/classic-code.key")

print_success "Classical certificate issued in ${YELLOW}${CLASSIC_CERT_TIME}ms${NC}"

echo ""
echo -e "${CYAN}Issuing PQC code signing certificate...${NC}"

PQC_CERT_TIME=$(time_cmd "$PKI_BIN" issue \
    --ca-dir "$PQC_CA" \
    --profile ml-dsa-kem/code-signing \
    --cn "ACME Software (PQC)" \
    --out "$DEMO_TMP/pqc-code.crt" \
    --key-out "$DEMO_TMP/pqc-code.key")

print_success "PQC certificate issued in ${YELLOW}${PQC_CERT_TIME}ms${NC}"

echo ""
echo -e "  ${CYAN}Inspect certificates:${NC}"
echo -e "    pki info $DEMO_TMP/classic-code.crt"
echo -e "    pki info $DEMO_TMP/pqc-code.crt"

# =============================================================================
# Step 4: Sign a Binary
# =============================================================================

print_step "Step 4: Sign a Binary (CMS/PKCS#7)"

# Create test binary
cat > "$DEMO_TMP/myapp.sh" << 'EOF'
#!/bin/bash
echo "Hello World - ACME Software v1.0"
EOF
chmod +x "$DEMO_TMP/myapp.sh"
echo -e "${CYAN}Created test binary: $DEMO_TMP/myapp.sh${NC}"
echo ""

echo -e "${CYAN}Signing with classical certificate...${NC}"
echo -e "Command:"
echo -e "  ${CYAN}pki cms sign --data myapp.sh --cert classic-code.crt --key classic-code.key -o myapp-classic.p7s${NC}"
echo ""

CLASSIC_SIGN_TIME=$(time_cmd "$PKI_BIN" cms sign \
    --data "$DEMO_TMP/myapp.sh" \
    --cert "$DEMO_TMP/classic-code.crt" \
    --key "$DEMO_TMP/classic-code.key" \
    -o "$DEMO_TMP/myapp-classic.p7s")

print_success "Classical signature created in ${YELLOW}${CLASSIC_SIGN_TIME}ms${NC}"

echo ""
echo -e "${CYAN}Signing with PQC certificate...${NC}"
echo -e "Command:"
echo -e "  ${CYAN}pki cms sign --data myapp.sh --cert pqc-code.crt --key pqc-code.key -o myapp-pqc.p7s${NC}"
echo ""

PQC_SIGN_TIME=$(time_cmd "$PKI_BIN" cms sign \
    --data "$DEMO_TMP/myapp.sh" \
    --cert "$DEMO_TMP/pqc-code.crt" \
    --key "$DEMO_TMP/pqc-code.key" \
    -o "$DEMO_TMP/myapp-pqc.p7s")

print_success "PQC signature created in ${YELLOW}${PQC_SIGN_TIME}ms${NC}"

# =============================================================================
# Step 5: Verify Signatures
# =============================================================================

print_step "Step 5: Verify Signatures"

echo -e "${CYAN}Verifying classical signature...${NC}"
echo -e "Command:"
echo -e "  ${CYAN}pki cms verify --signature myapp-classic.p7s --data myapp.sh --ca ca.crt${NC}"
echo ""

"$PKI_BIN" cms verify \
    --signature "$DEMO_TMP/myapp-classic.p7s" \
    --data "$DEMO_TMP/myapp.sh" \
    --ca "$CLASSIC_CA/ca.crt"

print_success "Classical signature verified"

echo ""
echo -e "${CYAN}Verifying PQC signature...${NC}"

"$PKI_BIN" cms verify \
    --signature "$DEMO_TMP/myapp-pqc.p7s" \
    --data "$DEMO_TMP/myapp.sh" \
    --ca "$PQC_CA/ca.crt"

print_success "PQC signature verified"

# =============================================================================
# Step 6: Comparison
# =============================================================================

print_step "Step 6: Comparison - Classical vs PQC Code Signing"

CLASSIC_CERT_SIZE=$(cert_size "$DEMO_TMP/classic-code.crt")
CLASSIC_KEY_SIZE=$(key_size "$DEMO_TMP/classic-code.key")
PQC_CERT_SIZE=$(cert_size "$DEMO_TMP/pqc-code.crt")
PQC_KEY_SIZE=$(key_size "$DEMO_TMP/pqc-code.key")

CLASSIC_SIG_SIZE=$(stat -f%z "$DEMO_TMP/myapp-classic.p7s" 2>/dev/null || stat -c%s "$DEMO_TMP/myapp-classic.p7s" 2>/dev/null)
PQC_SIG_SIZE=$(stat -f%z "$DEMO_TMP/myapp-pqc.p7s" 2>/dev/null || stat -c%s "$DEMO_TMP/myapp-pqc.p7s" 2>/dev/null)

print_comparison_header

echo -e "${BOLD}Code Signing Certificate${NC}"
print_comparison_row "  Cert size" "$CLASSIC_CERT_SIZE" "$PQC_CERT_SIZE" " B"
print_comparison_row "  Key size" "$CLASSIC_KEY_SIZE" "$PQC_KEY_SIZE" " B"
print_comparison_row "  Issue time" "$CLASSIC_CERT_TIME" "$PQC_CERT_TIME" "ms"

echo ""
echo -e "${BOLD}CMS Signature${NC}"
print_comparison_row "  Sig size" "$CLASSIC_SIG_SIZE" "$PQC_SIG_SIZE" " B"
print_comparison_row "  Sign time" "$CLASSIC_SIGN_TIME" "$PQC_SIGN_TIME" "ms"

echo ""
echo -e "${BOLD}Negligible overhead for quantum resistance!${NC}"
echo ""

# =============================================================================
# Software Lifespan Context
# =============================================================================

print_step "Step 7: Why This Matters - Software Lifespan"

echo -e "${CYAN}How long does signed software stay in use?${NC}"
echo ""
echo "  IoT firmware:        10-20 years  → ${RED}Needs PQC now${NC}"
echo "  Industrial control:  15-30 years  → ${RED}Needs PQC now${NC}"
echo "  Medical devices:     10-15 years  → ${RED}Needs PQC now${NC}"
echo "  Desktop software:    5-10 years   → ${YELLOW}Plan for PQC${NC}"
echo "  Mobile apps:         2-5 years    → ${GREEN}Can wait${NC}"
echo ""

# =============================================================================
# Key Message
# =============================================================================

print_key_message "Software signatures must remain valid for years. PQC ensures they can't be forged."

echo -e "${BOLD}The threat:${NC}"
echo "  - Signed binaries from today may be verified in 2034+"
echo "  - Quantum computers could forge classical signatures"
echo "  - Attackers could create 'legitimately signed' malware"
echo ""

echo -e "${BOLD}The solution:${NC}"
echo "  - ML-DSA-65 signatures are quantum-resistant"
echo "  - Signature size is negligible for software binaries"
echo "  - Same workflow, same tools, different algorithm"
echo ""

# =============================================================================
# Lesson Learned
# =============================================================================

show_lesson "Code signing is a long-term commitment.
Signatures made today must resist attacks for 10+ years.
PQC ensures your software supply chain stays secure."

show_footer
