#!/bin/bash
# =============================================================================
#  Lab-06: Code Signing - Signatures That Outlive the Threat
#
#  Post-quantum code signing with ML-DSA
#  Sign binaries and verify integrity
#
#  Key Message: Software signatures must remain valid for years.
#               PQC ensures they can't be forged by future quantum computers.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

setup_demo "PQC Code Signing"

PROFILES="$SCRIPT_DIR/profiles"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"I distribute firmware that must remain trusted for 10+ years."
echo "   How do I sign code with quantum-resistant signatures?\""
echo ""

echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1.  Create a Code Signing CA (ML-DSA-65)"
echo "  1b. Issue a code signing certificate"
echo "  2.  Sign a firmware binary (CMS/PKCS#7)"
echo "  2b. Verify the signature (VALID)"
echo "  3.  Tamper with the binary and verify again (INVALID)"
echo ""

echo -e "${DIM}CMS/PKCS#7 is the industry standard for code signing.${NC}"
echo ""

pause "Press Enter to start..."

# =============================================================================
# Step 1: Create Code Signing CA
# =============================================================================

print_step "Step 1: Create Code Signing CA"

echo "  A code signing CA issues certificates for software publishers."
echo "  We use ML-DSA-65 for quantum-resistant signatures."
echo ""

run_cmd "$PKI_BIN ca init --profile $PROFILES/pqc-ca.yaml --var cn=\"Code Signing CA\" --ca-dir $DEMO_TMP/code-ca"

# Export CA certificate for verification
$PKI_BIN ca export --ca-dir $DEMO_TMP/code-ca --out $DEMO_TMP/code-ca/ca.crt

echo ""

pause

# =============================================================================
# Step 2: Issue Code Signing Certificate
# =============================================================================

print_step "Step 1b: Issue Code Signing Certificate"

echo "  The code signing certificate has:"
echo "    - Extended Key Usage: codeSigning"
echo "    - Key Usage: digitalSignature"
echo ""

run_cmd "$PKI_BIN csr gen --algorithm ml-dsa-65 --keyout $DEMO_TMP/code-signing.key --cn \"ACME Software\" --out $DEMO_TMP/code-signing.csr"

echo ""

run_cmd "$PKI_BIN cert issue --ca-dir $DEMO_TMP/code-ca --profile $PROFILES/pqc-code-signing.yaml --csr $DEMO_TMP/code-signing.csr --out $DEMO_TMP/code-signing.crt"

echo ""

# Show certificate info
if [[ -f "$DEMO_TMP/code-signing.crt" ]]; then
    cert_size=$(wc -c < "$DEMO_TMP/code-signing.crt" | tr -d ' ')
    echo -e "  ${CYAN}Certificate size:${NC} $cert_size bytes"
fi

echo ""

pause

# =============================================================================
# Step 3: Sign a Binary
# =============================================================================

print_step "Step 2: Sign a Binary"

echo "  Creating a test firmware (100 KB)..."
echo ""

dd if=/dev/urandom of=$DEMO_TMP/firmware.bin bs=1024 count=100 2>/dev/null

firmware_size=$(wc -c < "$DEMO_TMP/firmware.bin" | tr -d ' ')
echo -e "  ${CYAN}Firmware size:${NC} $firmware_size bytes"
echo ""

echo "  Signing with CMS/PKCS#7 format (industry standard)..."
echo ""

run_cmd "$PKI_BIN cms sign --data $DEMO_TMP/firmware.bin --cert $DEMO_TMP/code-signing.crt --key $DEMO_TMP/code-signing.key --out $DEMO_TMP/firmware.p7s"

echo ""

if [[ -f "$DEMO_TMP/firmware.p7s" ]]; then
    sig_size=$(wc -c < "$DEMO_TMP/firmware.p7s" | tr -d ' ')
    echo -e "  ${CYAN}Signature size:${NC} $sig_size bytes"
    echo -e "  ${DIM}(ML-DSA-65 signature is ~3,309 bytes)${NC}"
fi

echo ""

pause

# =============================================================================
# Step 4: Verify the Signature
# =============================================================================

print_step "Step 2b: Verify the Signature"

echo "  Simulating client-side verification..."
echo ""

run_cmd "$PKI_BIN cms verify $DEMO_TMP/firmware.p7s --data $DEMO_TMP/firmware.bin --ca $DEMO_TMP/code-ca/ca.crt"

echo ""
echo -e "  ${GREEN}✓${NC} Signature valid!"
echo -e "  ${GREEN}✓${NC} Firmware has not been modified"
echo -e "  ${GREEN}✓${NC} Certificate chain verified against CA"
echo ""

pause

# =============================================================================
# Step 5: Tamper and Verify Again
# =============================================================================

print_step "Step 3: Tamper and Verify Again"

echo -e "  ${RED}Simulating malware injection...${NC}"
echo ""

echo "MALWARE_PAYLOAD" >> $DEMO_TMP/firmware.bin

echo -e "  ${DIM}$ echo \"MALWARE_PAYLOAD\" >> $DEMO_TMP/firmware.bin${NC}"
echo ""

echo "  Verifying the tampered firmware..."
echo ""

echo -e "  ${DIM}$ qpki cms verify $DEMO_TMP/firmware.p7s --data $DEMO_TMP/firmware.bin --ca $DEMO_TMP/code-ca/ca.crt${NC}"
echo ""

if $PKI_BIN cms verify $DEMO_TMP/firmware.p7s --data $DEMO_TMP/firmware.bin --ca $DEMO_TMP/code-ca/ca.crt > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Signature valid"
else
    echo -e "  ${RED}✗${NC} Signature verification FAILED!"
    echo -e "  ${RED}✗${NC} Firmware has been modified"
fi

echo ""
echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  SIGNATURE VERIFICATION COMPARISON                             │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo -e "  │  BEFORE tampering  →  ${GREEN}VALID${NC}   (integrity confirmed)          │"
echo -e "  │  AFTER tampering   →  ${RED}INVALID${NC} (modification detected)        │"
echo "  │                                                                 │"
echo "  │  The signature protects against supply chain attacks!          │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

# =============================================================================
# Conclusion
# =============================================================================

print_key_message "Software signatures must remain valid for years. PQC ensures they can't be forged by future quantum computers."

show_lesson "ML-DSA signatures remain unforgeable even by quantum computers.
Code signatures are long-lived (10+ years for IoT/firmware).
CMS/PKCS#7 format is the industry standard for code signing.
Size overhead is negligible for binaries (~3 KB signature)."

show_footer
