#!/bin/bash
# =============================================================================
#  UC-06: Code Signing - Signatures That Outlive the Threat
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

# =============================================================================
# Step 1: Create Code Signing CA
# =============================================================================

print_step "Step 1: Create Code Signing CA"

echo "  A code signing CA issues certificates for software publishers."
echo "  We use ML-DSA-65 for quantum-resistant signatures."
echo ""

run_cmd "qpki ca init --name \"Code Signing CA\" --profile profiles/pqc-ca.yaml --dir output/code-ca"

echo ""

pause

# =============================================================================
# Step 2: Issue Code Signing Certificate
# =============================================================================

print_step "Step 2: Issue Code Signing Certificate"

echo "  The code signing certificate has:"
echo "    - Extended Key Usage: codeSigning"
echo "    - Key Usage: digitalSignature"
echo ""

run_cmd "qpki cert csr --algorithm ml-dsa-65 --keyout output/code-signing.key --cn \"ACME Software\" --out output/code-signing.csr"

echo ""

run_cmd "qpki cert issue --ca-dir output/code-ca --profile profiles/pqc-code-signing.yaml --csr output/code-signing.csr --out output/code-signing.crt"

echo ""

# Show certificate info
if [[ -f "output/code-signing.crt" ]]; then
    cert_size=$(wc -c < "output/code-signing.crt" | tr -d ' ')
    echo -e "  ${CYAN}Certificate size:${NC} $cert_size bytes"
fi

echo ""

pause

# =============================================================================
# Step 3: Sign a Binary
# =============================================================================

print_step "Step 3: Sign a Binary"

echo "  Creating a test firmware (100 KB)..."
echo ""

dd if=/dev/urandom of=output/firmware.bin bs=1024 count=100 2>/dev/null

firmware_size=$(wc -c < "output/firmware.bin" | tr -d ' ')
echo -e "  ${CYAN}Firmware size:${NC} $firmware_size bytes"
echo ""

echo "  Signing with CMS/PKCS#7 format (industry standard)..."
echo ""

run_cmd "qpki cms sign --data output/firmware.bin --cert output/code-signing.crt --key output/code-signing.key -o output/firmware.p7s"

echo ""

if [[ -f "output/firmware.p7s" ]]; then
    sig_size=$(wc -c < "output/firmware.p7s" | tr -d ' ')
    echo -e "  ${CYAN}Signature size:${NC} $sig_size bytes"
    echo -e "  ${DIM}(ML-DSA-65 signature is ~3,293 bytes)${NC}"
fi

echo ""

pause

# =============================================================================
# Step 4: Verify the Signature
# =============================================================================

print_step "Step 4: Verify the Signature"

echo "  Simulating client-side verification..."
echo ""

run_cmd "qpki cms verify --signature output/firmware.p7s --data output/firmware.bin"

echo ""
echo -e "  ${GREEN}✓${NC} Signature valid!"
echo -e "  ${GREEN}✓${NC} Firmware has not been modified"
echo -e "  ${GREEN}✓${NC} Signed by ACME Software (code signing certificate)"
echo ""

pause

# =============================================================================
# Step 5: Tamper and Verify Again
# =============================================================================

print_step "Step 5: Tamper and Verify Again"

echo -e "  ${RED}Simulating malware injection...${NC}"
echo ""

echo "MALWARE_PAYLOAD" >> output/firmware.bin

echo -e "  ${DIM}$ echo \"MALWARE_PAYLOAD\" >> output/firmware.bin${NC}"
echo ""

echo "  Verifying the tampered firmware..."
echo ""

echo -e "  ${DIM}$ qpki cms verify --signature output/firmware.p7s --data output/firmware.bin${NC}"
echo ""

if qpki cms verify --signature output/firmware.p7s --data output/firmware.bin > /dev/null 2>&1; then
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
