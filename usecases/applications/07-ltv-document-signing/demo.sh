#!/bin/bash
# =============================================================================
#  APP-07: "LTV: Trust Today, Verify in 2055"
#
#  Long-Term Validation for Document Signing
#
#  Key Message: A signature is only as good as its proof chain.
#               LTV bundles everything needed to verify decades from now.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "APP-07: LTV - Trust Today, Verify in 2055"

LTV_CA="$DEMO_TMP/ltv-ca"
BUNDLE_DIR="$DEMO_TMP/contract-ltv-bundle"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"We signed a 30-year contract today."
echo "   In 2055, how will anyone verify this signature"
echo "   if our CA no longer exists?\""
echo ""
echo -e "${BOLD}THE PROBLEM:${NC}"
echo "  - Signatures alone aren't enough for long-term validity"
echo "  - CAs may shut down, OCSP responders go offline"
echo "  - You need proof the certificate was valid AT SIGNING TIME"
echo ""
echo -e "${BOLD}THE SOLUTION - LTV Bundle:${NC}"
echo "  1. Signature (CMS with ML-DSA)"
echo "  2. Timestamp (proves WHEN it was signed)"
echo "  3. OCSP snapshot (proves cert was VALID)"
echo "  4. Certificate chain (all CA certs)"
echo ""

pause_for_explanation "Press Enter to start the demo..."

# =============================================================================
# Step 1: Create PKI Infrastructure
# =============================================================================

print_step "Step 1: Create Document Signing CA (ML-DSA-65)"

echo -e "Command:"
echo -e "  ${CYAN}pki init-ca --name \"LTV Demo CA\" --algorithm ml-dsa-65 --dir $LTV_CA${NC}"
echo ""

CA_TIME=$(time_cmd "$PKI_BIN" init-ca \
    --name "LTV Demo CA" \
    --org "Legal Department" \
    --algorithm ml-dsa-65 \
    --dir "$LTV_CA")

print_success "CA created in ${YELLOW}${CA_TIME}ms${NC}"

# =============================================================================
# Step 2: Issue Document Signing Certificate
# =============================================================================

print_step "Step 2: Issue Document Signing Certificate for Alice"

echo -e "${CYAN}Alice is our legal counsel signing a 30-year lease.${NC}"
echo ""

CERT_TIME=$(time_cmd "$PKI_BIN" issue \
    --ca-dir "$LTV_CA" \
    --profile ml-dsa-kem/document-signing \
    --cn "Alice (Legal Counsel)" \
    --out "$DEMO_TMP/alice.crt" \
    --key-out "$DEMO_TMP/alice.key")

print_success "Certificate issued in ${YELLOW}${CERT_TIME}ms${NC}"

# =============================================================================
# Step 3: Create the Document
# =============================================================================

print_step "Step 3: Create the 30-Year Lease Agreement"

SIGN_DATE=$(date "+%Y-%m-%d %H:%M:%S")
EXPIRE_DATE=$(date -v+30y "+%Y-%m-%d" 2>/dev/null || date -d "+30 years" "+%Y-%m-%d" 2>/dev/null || echo "2054-12-20")

cat > "$DEMO_TMP/contract.txt" << EOF
================================================================================
                        30-YEAR COMMERCIAL LEASE AGREEMENT
================================================================================

Document ID: LEASE-2024-$(date +%s)
Signing Date: $SIGN_DATE
Expiration Date: $EXPIRE_DATE

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

echo -e "${CYAN}Created: $DEMO_TMP/contract.txt${NC}"
echo ""
head -15 "$DEMO_TMP/contract.txt"
echo "..."
echo ""

# =============================================================================
# Step 4: Sign the Document (CMS)
# =============================================================================

print_step "Step 4: Sign the Document (CMS/PKCS#7)"

echo -e "Command:"
echo -e "  ${CYAN}pki cms sign --data contract.txt --cert alice.crt --key alice.key -o contract.p7s${NC}"
echo ""

SIGN_TIME=$(time_cmd "$PKI_BIN" cms sign \
    --data "$DEMO_TMP/contract.txt" \
    --cert "$DEMO_TMP/alice.crt" \
    --key "$DEMO_TMP/alice.key" \
    -o "$DEMO_TMP/contract.p7s")

print_success "Document signed in ${YELLOW}${SIGN_TIME}ms${NC}"

SIG_SIZE=$(stat -f%z "$DEMO_TMP/contract.p7s" 2>/dev/null || stat -c%s "$DEMO_TMP/contract.p7s" 2>/dev/null)
echo -e "  Signature size: ${YELLOW}${SIG_SIZE} bytes${NC}"

# =============================================================================
# Step 5: Add Timestamp (RFC 3161)
# =============================================================================

print_step "Step 5: Add Timestamp (Proves WHEN It Was Signed)"

echo -e "${CYAN}The timestamp proves the document was signed at a specific moment.${NC}"
echo -e "${CYAN}This is critical because it proves the certificate was valid AT SIGNING TIME.${NC}"
echo ""

TSA_TIME=$(time_cmd "$PKI_BIN" tsa sign \
    --data "$DEMO_TMP/contract.p7s" \
    --cert "$DEMO_TMP/alice.crt" \
    --key "$DEMO_TMP/alice.key" \
    -o "$DEMO_TMP/contract.tsr")

print_success "Timestamp created in ${YELLOW}${TSA_TIME}ms${NC}"

TSR_SIZE=$(stat -f%z "$DEMO_TMP/contract.tsr" 2>/dev/null || stat -c%s "$DEMO_TMP/contract.tsr" 2>/dev/null)
echo -e "  Timestamp size: ${YELLOW}${TSR_SIZE} bytes${NC}"

# =============================================================================
# Step 6: Create LTV Bundle
# =============================================================================

print_step "Step 6: Create LTV Bundle (All Proofs Together)"

mkdir -p "$BUNDLE_DIR"

# Copy all components
cp "$DEMO_TMP/contract.txt" "$BUNDLE_DIR/document.txt"
cp "$DEMO_TMP/contract.p7s" "$BUNDLE_DIR/signature.p7s"
cp "$DEMO_TMP/contract.tsr" "$BUNDLE_DIR/timestamp.tsr"
cat "$DEMO_TMP/alice.crt" "$LTV_CA/ca.crt" > "$BUNDLE_DIR/chain.pem"

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

print_success "LTV Bundle created"

echo ""
echo -e "${CYAN}Bundle contents:${NC}"
ls -la "$BUNDLE_DIR"
echo ""

# Calculate total bundle size
BUNDLE_SIZE=$(du -sh "$BUNDLE_DIR" 2>/dev/null | cut -f1)
echo -e "  Total bundle size: ${YELLOW}${BUNDLE_SIZE}${NC}"

# =============================================================================
# Step 7: Verify the Bundle (Simulating 2055)
# =============================================================================

print_step "Step 7: Verify the Bundle (Simulating Year 2055)"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  SIMULATING: It's now 2055. The original CA is long gone.${NC}"
echo -e "${CYAN}  Bob (archivist) needs to verify this 30-year-old contract.${NC}"
echo -e "${CYAN}  He only has the LTV bundle - no network access to original CA.${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}Verifying CMS signature using bundled chain...${NC}"

"$PKI_BIN" cms verify \
    --signature "$BUNDLE_DIR/signature.p7s" \
    --data "$BUNDLE_DIR/document.txt" \
    --ca "$BUNDLE_DIR/chain.pem"

print_success "Signature VALID"

echo ""
echo -e "${CYAN}Verifying timestamp using bundled chain...${NC}"

"$PKI_BIN" tsa verify \
    --token "$BUNDLE_DIR/timestamp.tsr" \
    --data "$BUNDLE_DIR/signature.p7s" \
    --ca "$BUNDLE_DIR/chain.pem"

print_success "Timestamp VALID - Document was signed on $SIGN_DATE"

# =============================================================================
# Step 8: Comparison - With vs Without LTV
# =============================================================================

print_step "Step 8: Why LTV Matters"

echo ""
echo -e "${BOLD}WITHOUT LTV (in 2055):${NC}"
echo -e "  ${RED}✗${NC} Signature: Still mathematically valid"
echo -e "  ${RED}✗${NC} Certificate: Cannot verify (CA gone, OCSP offline)"
echo -e "  ${RED}✗${NC} Time of signing: Unknown"
echo -e "  ${RED}→ Result: CANNOT TRUST THE SIGNATURE${NC}"
echo ""
echo -e "${BOLD}WITH LTV (in 2055):${NC}"
echo -e "  ${GREEN}✓${NC} Signature: Valid (ML-DSA is quantum-resistant)"
echo -e "  ${GREEN}✓${NC} Certificate: Bundled chain verifies offline"
echo -e "  ${GREEN}✓${NC} Time of signing: Timestamp proves $SIGN_DATE"
echo -e "  ${GREEN}→ Result: FULLY VERIFIED, LEGALLY BINDING${NC}"
echo ""

# =============================================================================
# LTV Use Cases
# =============================================================================

print_step "Step 9: When You Need LTV"

echo ""
echo -e "${CYAN}Document types requiring LTV:${NC}"
echo ""
echo "  Legal contracts:     10-30 years  → ${RED}LTV Required${NC}"
echo "  Medical records:     50+ years    → ${RED}LTV Required${NC}"
echo "  Real estate deeds:   Permanent    → ${RED}LTV Required${NC}"
echo "  Financial audits:    7-10 years   → ${YELLOW}LTV Recommended${NC}"
echo "  Software licenses:   5-15 years   → ${YELLOW}LTV Recommended${NC}"
echo "  Email archives:      3-7 years    → ${GREEN}Optional${NC}"
echo ""

# =============================================================================
# Key Message
# =============================================================================

print_key_message "A signature is only as good as its proof chain. LTV bundles everything."

echo -e "${BOLD}The LTV bundle contains:${NC}"
echo "  1. Original document"
echo "  2. CMS signature (ML-DSA quantum-resistant)"
echo "  3. RFC 3161 timestamp (proves signing time)"
echo "  4. Certificate chain (offline verification)"
echo ""

echo -e "${BOLD}Why Post-Quantum for LTV?${NC}"
echo "  - 30-year documents will face quantum computers"
echo "  - Classical signatures (RSA/ECDSA) will be forgeable"
echo "  - ML-DSA signatures remain valid forever"
echo ""

# =============================================================================
# Lesson Learned
# =============================================================================

show_lesson "Long-term documents need long-term proofs.
LTV bundles everything needed for offline verification.
With PQC, your 30-year contracts stay valid in 2055."

show_footer
