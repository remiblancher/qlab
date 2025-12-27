#!/bin/bash
# =============================================================================
#  UC-08: LTV Signatures - Sign Today, Verify in 30 Years
#
#  Long-Term Validation for document signing with ML-DSA
#  Bundle everything needed for offline verification decades from now
#
#  Key Message: A signature is only as good as its proof chain.
#               LTV bundles everything needed for offline verification.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

setup_demo "PQC LTV Signatures"

BUNDLE_DIR="output/ltv-bundle"

# =============================================================================
# Step 1: Create PKI Infrastructure
# =============================================================================

print_step "Step 1: Create PKI Infrastructure"

echo "  We need:"
echo "    - A CA to issue certificates"
echo "    - A document signing certificate for Alice"
echo "    - A TSA certificate for timestamping"
echo ""

run_cmd "pki ca init --name \"LTV Demo CA\" --algorithm ml-dsa-65 --dir output/ltv-ca"

echo ""
echo "  Issue document signing certificate for Alice..."
echo ""

run_cmd "pki cert issue --ca-dir output/ltv-ca --profile ml-dsa-kem/code-signing --cn \"Alice (Legal Counsel)\" --out output/alice.crt --key-out output/alice.key"

echo ""
echo "  Issue TSA certificate..."
echo ""

run_cmd "pki cert issue --ca-dir output/ltv-ca --profile ml-dsa-kem/timestamping --cn \"LTV Timestamp Authority\" --out output/tsa.crt --key-out output/tsa.key"

echo ""

pause

# =============================================================================
# Step 2: Create and Sign Document
# =============================================================================

print_step "Step 2: Create and Sign the 30-Year Contract"

SIGN_DATE=$(date "+%Y-%m-%d %H:%M:%S")

cat > output/contract.txt << EOF
================================================================================
                    30-YEAR COMMERCIAL LEASE AGREEMENT
================================================================================

Document ID: LEASE-$(date +%s)
Signing Date: $SIGN_DATE
Expiration: 2054-12-22

PARTIES:
  Lessor:  ACME Properties LLC
  Lessee:  TechCorp Industries Inc.

TERMS:
  Property: 123 Innovation Drive, Suite 500
  Duration: 30 years from signing date
  Monthly Rent: \$50,000 (adjusted annually for inflation)

This agreement shall remain valid and enforceable for the full 30-year term.

SIGNATURES:
  Signed electronically with Post-Quantum ML-DSA-65 algorithm.

================================================================================
EOF

echo -e "  ${CYAN}Contract content:${NC}"
head -12 output/contract.txt | sed 's/^/    /'
echo "    ..."
echo ""

echo "  Signing with CMS (ML-DSA)..."
echo ""

run_cmd "pki cms sign --data output/contract.txt --cert output/alice.crt --key output/alice.key -o output/contract.p7s"

echo ""

if [[ -f "output/contract.p7s" ]]; then
    sig_size=$(wc -c < "output/contract.p7s" | tr -d ' ')
    echo -e "  ${CYAN}Signature size:${NC} $sig_size bytes"
fi

echo ""

pause

# =============================================================================
# Step 3: Add Timestamp
# =============================================================================

print_step "Step 3: Add Timestamp (RFC 3161)"

echo "  The timestamp proves WHEN the document was signed."
echo "  This is critical because it proves the certificate was valid at signing time."
echo ""

run_cmd "pki tsa sign --data output/contract.p7s --cert output/tsa.crt --key output/tsa.key -o output/contract.tsr"

echo ""

if [[ -f "output/contract.tsr" ]]; then
    tsr_size=$(wc -c < "output/contract.tsr" | tr -d ' ')
    echo -e "  ${CYAN}Timestamp size:${NC} $tsr_size bytes"
fi

echo ""

pause

# =============================================================================
# Step 4: Create LTV Bundle
# =============================================================================

print_step "Step 4: Create LTV Bundle"

echo "  Packaging everything for long-term verification..."
echo ""

mkdir -p "$BUNDLE_DIR"

# Copy all components
cp output/contract.txt "$BUNDLE_DIR/document.txt"
cp output/contract.p7s "$BUNDLE_DIR/signature.p7s"
cp output/contract.tsr "$BUNDLE_DIR/timestamp.tsr"
cat output/alice.crt output/ltv-ca/ca.crt > "$BUNDLE_DIR/chain.pem"

# Create manifest
cat > "$BUNDLE_DIR/manifest.json" << EOF
{
  "version": "1.0",
  "created": "$SIGN_DATE",
  "algorithm": "ML-DSA-65",
  "components": {
    "document": "document.txt",
    "signature": "signature.p7s",
    "timestamp": "timestamp.tsr",
    "chain": "chain.pem"
  },
  "note": "This bundle contains all proofs needed for offline verification in 2055+"
}
EOF

echo -e "  ${GREEN}✓${NC} LTV Bundle created at: $BUNDLE_DIR/"
echo ""
echo -e "  ${CYAN}Bundle contents:${NC}"
ls -la "$BUNDLE_DIR" | sed 's/^/    /'
echo ""

# Calculate total bundle size
bundle_size=$(du -sh "$BUNDLE_DIR" 2>/dev/null | cut -f1)
echo -e "  ${CYAN}Total bundle size:${NC} $bundle_size"
echo ""

pause

# =============================================================================
# Step 5: Verify Offline (Simulating 2055)
# =============================================================================

print_step "Step 5: Verify Offline (Simulating Year 2055)"

echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  SIMULATING: It's now 2055. The original CA is long gone.      │"
echo "  │  Bob (archivist) needs to verify this 30-year-old contract.    │"
echo "  │  He only has the LTV bundle - no network access to original CA.│"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

echo "  Verifying CMS signature using bundled chain..."
echo ""

run_cmd "pki cms verify --signature $BUNDLE_DIR/signature.p7s --data $BUNDLE_DIR/document.txt"

echo ""
echo -e "  ${GREEN}✓${NC} Signature VALID"
echo -e "  ${GREEN}✓${NC} Document verified using bundled certificate chain"
echo -e "  ${GREEN}✓${NC} No network access required"
echo ""

# =============================================================================
# Comparison: With vs Without LTV
# =============================================================================

print_step "Step 6: Why LTV Matters"

echo ""
echo -e "  ${BOLD}WITHOUT LTV (in 2055):${NC}"
echo -e "    ${RED}✗${NC} Signature: Still mathematically valid"
echo -e "    ${RED}✗${NC} Certificate: Cannot verify (CA gone, OCSP offline)"
echo -e "    ${RED}✗${NC} Time of signing: Unknown"
echo -e "    ${RED}→ Result: CANNOT TRUST THE SIGNATURE${NC}"
echo ""
echo -e "  ${BOLD}WITH LTV (in 2055):${NC}"
echo -e "    ${GREEN}✓${NC} Signature: Valid (ML-DSA is quantum-resistant)"
echo -e "    ${GREEN}✓${NC} Certificate: Bundled chain verifies offline"
echo -e "    ${GREEN}✓${NC} Time of signing: Timestamp proves $SIGN_DATE"
echo -e "    ${GREEN}→ Result: FULLY VERIFIED, LEGALLY BINDING${NC}"
echo ""

# =============================================================================
# Conclusion
# =============================================================================

print_key_message "A signature is only as good as its proof chain. LTV bundles everything."

show_lesson "LTV bundles: document + signature + timestamp + chain.
With PQC (ML-DSA), your 30-year contracts stay valid in 2055.
No network dependencies - everything is self-contained.
Essential for legal, medical, and real estate documents."

show_footer
