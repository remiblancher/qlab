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
echo "  4. Compare signature sizes"
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
# Step 4: Comparison
# =============================================================================

print_step "Step 4: Comparison - Classical vs PQC Code Signing"

CLASSIC_CERT_SIZE=$(cert_size "$DEMO_TMP/classic-code.crt")
CLASSIC_KEY_SIZE=$(key_size "$DEMO_TMP/classic-code.key")
PQC_CERT_SIZE=$(cert_size "$DEMO_TMP/pqc-code.crt")
PQC_KEY_SIZE=$(key_size "$DEMO_TMP/pqc-code.key")

print_comparison_header

echo -e "${BOLD}Code Signing Certificate${NC}"
print_comparison_row "  Cert size" "$CLASSIC_CERT_SIZE" "$PQC_CERT_SIZE" " B"
print_comparison_row "  Key size" "$CLASSIC_KEY_SIZE" "$PQC_KEY_SIZE" " B"
print_comparison_row "  Issue time" "$CLASSIC_CERT_TIME" "$PQC_CERT_TIME" "ms"

echo ""
echo -e "${CYAN}Signature overhead for a 100 MB binary:${NC}"
echo "  Classical: ~100 bytes  (0.0001% of binary)"
echo "  PQC:       ~3,300 bytes (0.003% of binary)"
echo ""
echo -e "${BOLD}Negligible overhead for quantum resistance!${NC}"
echo ""

# =============================================================================
# Software Lifespan Context
# =============================================================================

print_step "Step 5: Why This Matters - Software Lifespan"

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
