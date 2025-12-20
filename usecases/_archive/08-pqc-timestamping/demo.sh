#!/bin/bash
# =============================================================================
#  UC-08: "Trust Now, Verify Forever"
#
#  Post-Quantum Timestamping
#
#  Key Message: Timestamps prove when documents existed.
#               PQC ensures those proofs remain valid for decades.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "UC-08: Trust Now, Verify Forever"

CLASSIC_TSA="$DEMO_TMP/classic-tsa"
PQC_TSA="$DEMO_TMP/pqc-tsa"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"We need to prove that this contract was signed on this exact date."
echo "   The proof must be valid for 30+ years for legal compliance.\""
echo ""
echo -e "${BOLD}THE PROBLEM:${NC}"
echo "  - A timestamp from 2024 might need validation in 2054"
echo "  - If quantum computers can forge the TSA's signature..."
echo "  - Attackers could backdate documents fraudulently"
echo ""
echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Create a classical Timestamp Authority (ECDSA)"
echo "  2. Create a PQC Timestamp Authority (ML-DSA-65)"
echo "  3. Issue TSA certificates"
echo "  4. Timestamp a document with both"
echo "  5. Verify the timestamps"
echo "  6. Compare token sizes"
echo ""

pause_for_explanation "Press Enter to start the demo..."

# =============================================================================
# Step 1: Create Classical TSA
# =============================================================================

print_step "Step 1: Create Classical Timestamp Authority (ECDSA P-384)"

echo -e "Command:"
echo -e "  ${CYAN}pki init-ca --name \"Classic Timestamp Authority\" --algorithm ecdsa-p384 --dir $CLASSIC_TSA${NC}"
echo ""

CLASSIC_TSA_TIME=$(time_cmd "$PKI_BIN" init-ca \
    --name "Classic Timestamp Authority" \
    --org "Demo Organization" \
    --algorithm ecdsa-p384 \
    --dir "$CLASSIC_TSA")

print_success "Classical TSA created in ${YELLOW}${CLASSIC_TSA_TIME}ms${NC}"

# =============================================================================
# Step 2: Create PQC TSA
# =============================================================================

print_step "Step 2: Create PQC Timestamp Authority (ML-DSA-65)"

echo -e "${CYAN}Why ML-DSA-65 for timestamping?${NC}"
echo "  - Timestamps may need validation 30+ years later"
echo "  - Legal/compliance requires long-term proof"
echo "  - Quantum computers can't forge PQC signatures"
echo ""

echo -e "Command:"
echo -e "  ${CYAN}pki init-ca --name \"PQC Timestamp Authority\" --algorithm ml-dsa-65 --dir $PQC_TSA${NC}"
echo ""

PQC_TSA_TIME=$(time_cmd "$PKI_BIN" init-ca \
    --name "PQC Timestamp Authority" \
    --org "Demo Organization" \
    --algorithm ml-dsa-65 \
    --dir "$PQC_TSA")

print_success "PQC TSA created in ${YELLOW}${PQC_TSA_TIME}ms${NC}"

# =============================================================================
# Step 3: Issue TSA Certificates
# =============================================================================

print_step "Step 3: Issue TSA Certificates"

echo -e "${CYAN}Issuing classical TSA certificate...${NC}"

CLASSIC_CERT_TIME=$(time_cmd "$PKI_BIN" issue \
    --ca-dir "$CLASSIC_TSA" \
    --profile ec/timestamping \
    --cn "ACME Timestamp Service (Classical)" \
    --out "$DEMO_TMP/classic-tsa.crt" \
    --key-out "$DEMO_TMP/classic-tsa.key")

print_success "Classical TSA certificate issued in ${YELLOW}${CLASSIC_CERT_TIME}ms${NC}"

echo ""
echo -e "${CYAN}Issuing PQC TSA certificate...${NC}"

PQC_CERT_TIME=$(time_cmd "$PKI_BIN" issue \
    --ca-dir "$PQC_TSA" \
    --profile ml-dsa-kem/timestamping \
    --cn "ACME Timestamp Service (PQC)" \
    --out "$DEMO_TMP/pqc-tsa.crt" \
    --key-out "$DEMO_TMP/pqc-tsa.key")

print_success "PQC TSA certificate issued in ${YELLOW}${PQC_CERT_TIME}ms${NC}"

echo ""
echo -e "  ${CYAN}Inspect certificates:${NC}"
echo -e "    pki info $DEMO_TMP/classic-tsa.crt"
echo -e "    pki info $DEMO_TMP/pqc-tsa.crt"

# =============================================================================
# Step 4: Timestamp a Document
# =============================================================================

print_step "Step 4: Timestamp a Document"

# Create test document
echo "Important contract signed on $(date)" > "$DEMO_TMP/document.txt"
echo -e "${CYAN}Created test document: $DEMO_TMP/document.txt${NC}"
echo ""

echo -e "${CYAN}Timestamping with classical TSA...${NC}"
echo -e "Command:"
echo -e "  ${CYAN}pki tsa sign --data document.txt --cert classic-tsa.crt --key classic-tsa.key -o classic.tsr${NC}"
echo ""

CLASSIC_TSA_SIGN_TIME=$(time_cmd "$PKI_BIN" tsa sign \
    --data "$DEMO_TMP/document.txt" \
    --cert "$DEMO_TMP/classic-tsa.crt" \
    --key "$DEMO_TMP/classic-tsa.key" \
    -o "$DEMO_TMP/classic.tsr")

print_success "Classical timestamp created in ${YELLOW}${CLASSIC_TSA_SIGN_TIME}ms${NC}"

echo ""
echo -e "${CYAN}Timestamping with PQC TSA...${NC}"
echo -e "Command:"
echo -e "  ${CYAN}pki tsa sign --data document.txt --cert pqc-tsa.crt --key pqc-tsa.key -o pqc.tsr${NC}"
echo ""

PQC_TSA_SIGN_TIME=$(time_cmd "$PKI_BIN" tsa sign \
    --data "$DEMO_TMP/document.txt" \
    --cert "$DEMO_TMP/pqc-tsa.crt" \
    --key "$DEMO_TMP/pqc-tsa.key" \
    -o "$DEMO_TMP/pqc.tsr")

print_success "PQC timestamp created in ${YELLOW}${PQC_TSA_SIGN_TIME}ms${NC}"

# =============================================================================
# Step 5: Verify Timestamps
# =============================================================================

print_step "Step 5: Verify Timestamps"

echo -e "${CYAN}Verifying classical timestamp...${NC}"
echo -e "Command:"
echo -e "  ${CYAN}pki tsa verify --token classic.tsr --data document.txt --ca ca.crt${NC}"
echo ""

"$PKI_BIN" tsa verify \
    --token "$DEMO_TMP/classic.tsr" \
    --data "$DEMO_TMP/document.txt" \
    --ca "$CLASSIC_TSA/ca.crt"

print_success "Classical timestamp verified"

echo ""
echo -e "${CYAN}Verifying PQC timestamp...${NC}"

"$PKI_BIN" tsa verify \
    --token "$DEMO_TMP/pqc.tsr" \
    --data "$DEMO_TMP/document.txt" \
    --ca "$PQC_TSA/ca.crt"

print_success "PQC timestamp verified"

# =============================================================================
# Step 6: Comparison
# =============================================================================

print_step "Step 6: Comparison - Classical vs PQC Timestamping"

CLASSIC_CERT_SIZE=$(cert_size "$DEMO_TMP/classic-tsa.crt")
CLASSIC_KEY_SIZE=$(key_size "$DEMO_TMP/classic-tsa.key")
PQC_CERT_SIZE=$(cert_size "$DEMO_TMP/pqc-tsa.crt")
PQC_KEY_SIZE=$(key_size "$DEMO_TMP/pqc-tsa.key")

CLASSIC_TOKEN_SIZE=$(stat -f%z "$DEMO_TMP/classic.tsr" 2>/dev/null || stat -c%s "$DEMO_TMP/classic.tsr" 2>/dev/null)
PQC_TOKEN_SIZE=$(stat -f%z "$DEMO_TMP/pqc.tsr" 2>/dev/null || stat -c%s "$DEMO_TMP/pqc.tsr" 2>/dev/null)

print_comparison_header

echo -e "${BOLD}TSA Certificate${NC}"
print_comparison_row "  Cert size" "$CLASSIC_CERT_SIZE" "$PQC_CERT_SIZE" " B"
print_comparison_row "  Key size" "$CLASSIC_KEY_SIZE" "$PQC_KEY_SIZE" " B"
print_comparison_row "  Issue time" "$CLASSIC_CERT_TIME" "$PQC_CERT_TIME" "ms"

echo ""
echo -e "${BOLD}Timestamp Token${NC}"
print_comparison_row "  Token size" "$CLASSIC_TOKEN_SIZE" "$PQC_TOKEN_SIZE" " B"
print_comparison_row "  Sign time" "$CLASSIC_TSA_SIGN_TIME" "$PQC_TSA_SIGN_TIME" "ms"

echo ""
echo -e "${BOLD}Minimal overhead for 30+ years of legal validity!${NC}"
echo ""

# =============================================================================
# Document Retention Context
# =============================================================================

print_step "Step 7: Why This Matters - Document Retention"

echo -e "${CYAN}How long do timestamped documents need to be valid?${NC}"
echo ""
echo "  Legal contracts:      30+ years   → ${RED}Needs PQC now${NC}"
echo "  Patents:              20+ years   → ${RED}Needs PQC now${NC}"
echo "  Medical records:      Lifetime    → ${RED}Needs PQC now${NC}"
echo "  Financial audits:     10-15 years → ${RED}Needs PQC now${NC}"
echo "  AI training logs:     10+ years   → ${RED}Needs PQC now${NC}"
echo "  Tax records:          7-10 years  → ${YELLOW}Plan for PQC${NC}"
echo ""

# =============================================================================
# Key Message
# =============================================================================

print_key_message "Timestamps prove when documents existed. PQC ensures those proofs remain valid."

echo -e "${BOLD}The threat:${NC}"
echo "  - Timestamps from today may need legal validation in 2054+"
echo "  - Quantum computers could forge classical TSA signatures"
echo "  - Attackers could backdate documents fraudulently"
echo ""

echo -e "${BOLD}The solution:${NC}"
echo "  - ML-DSA-65 signatures are quantum-resistant"
echo "  - Timestamp token overhead is minimal"
echo "  - Same RFC 3161 workflow, different algorithm"
echo ""

# =============================================================================
# Lesson Learned
# =============================================================================

show_lesson "Timestamping is the ultimate long-term commitment.
Legal and compliance requirements demand 30+ year validity.
PQC ensures your timestamps remain unforgeable forever."

show_footer
