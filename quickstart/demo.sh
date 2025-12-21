#!/bin/bash
# =============================================================================
#  QUICK START: Classical vs Post-Quantum
#
#  Create both ECDSA and ML-DSA CAs, issue certificates, compare sizes.
#
#  Key Message: Same workflow, different sizes.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "Quick Start"

CLASSIC_CA="$DEMO_TMP/classic-ca"
PQC_CA="$DEMO_TMP/pqc-ca"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}Classical vs Post-Quantum: Same PKI, Different Crypto${NC}"
echo ""
echo -e "${DIM}Key Message: The PKI doesn't change. Only the algorithm changes.${NC}"
echo ""

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"I want to issue post-quantum certificates."
echo "   Does it change my PKI workflow?\""
echo ""
echo -e "  Short answer: ${GREEN}No.${NC} The workflow is identical."
echo "  Only the algorithm name changes. This demo proves it."
echo ""

echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo ""
printf "  %-12s %-20s %-20s\n" "Step" "Classical" "Post-Quantum"
echo "  ──────────────────────────────────────────────────────"
printf "  %-12s %-20s %-20s\n" "Create CA" "ECDSA P-384" "ML-DSA-65"
printf "  %-12s %-20s %-20s\n" "Issue cert" "Same workflow" "Same workflow"
printf "  %-12s %-20s %-20s\n" "Result" "Vulnerable" "Quantum-resistant"
echo ""

pause "Press Enter to start..."

init_steps 5

# =============================================================================
# Step 1: Create Classical CA
# =============================================================================

step "Create Classical Root CA" \
     "Profile 'ec/root-ca' = ECDSA P-384, 20 years validity, CA extensions"

run_cmd "$PKI_BIN init-ca --profile ec/root-ca --name 'Classic Root CA' --dir $CLASSIC_CA"

show_files "$CLASSIC_CA"

pause

# =============================================================================
# Step 2: Issue Classical TLS Certificate
# =============================================================================

step "Issue Classical TLS Certificate" \
     "Profile 'ec/tls-server' = ECDSA key, TLS Server extensions (EKU, SAN)"

run_cmd "$PKI_BIN issue --ca-dir $CLASSIC_CA --profile ec/tls-server --cn classic.example.com --dns classic.example.com --out $DEMO_TMP/classic-server.crt --key-out $DEMO_TMP/classic-server.key"

echo ""
echo -e "  ${GREEN}Certificate issued.${NC}"

pause

# =============================================================================
# Step 3: Create Post-Quantum CA
# =============================================================================

step "Create Post-Quantum Root CA" \
     "Profile 'ml-dsa/root-ca' = ML-DSA-65 (FIPS 204), 20 years, CA extensions"

run_cmd "$PKI_BIN init-ca --profile ml-dsa/root-ca --name 'PQ Root CA' --dir $PQC_CA"

show_files "$PQC_CA"

pause

# =============================================================================
# Step 4: Issue Post-Quantum TLS Certificate
# =============================================================================

step "Issue Post-Quantum TLS Certificate" \
     "Profile 'ml-dsa/tls-server' = ML-DSA key, TLS Server extensions"

run_cmd "$PKI_BIN issue --ca-dir $PQC_CA --profile ml-dsa/tls-server --cn pq.example.com --dns pq.example.com --out $DEMO_TMP/pq-server.crt --key-out $DEMO_TMP/pq-server.key"

echo ""
echo -e "  ${GREEN}Certificate issued.${NC}"

pause

# =============================================================================
# Step 5: Comparison
# =============================================================================

step "Size Comparison" \
     "Same workflow, different sizes."

# Get sizes
CLASSIC_CA_CERT_SIZE=$(cert_size "$CLASSIC_CA/ca.crt")
CLASSIC_CA_KEY_SIZE=$(key_size "$CLASSIC_CA/private/ca.key")
CLASSIC_CERT_SIZE=$(cert_size "$DEMO_TMP/classic-server.crt")
CLASSIC_KEY_SIZE=$(key_size "$DEMO_TMP/classic-server.key")

PQC_CA_CERT_SIZE=$(cert_size "$PQC_CA/ca.crt")
PQC_CA_KEY_SIZE=$(key_size "$PQC_CA/private/ca.key")
PQC_CERT_SIZE=$(cert_size "$DEMO_TMP/pq-server.crt")
PQC_KEY_SIZE=$(key_size "$DEMO_TMP/pq-server.key")

print_comparison_header

echo -e "${BOLD}CA Certificate${NC}"
print_comparison_row "  Cert size" "$CLASSIC_CA_CERT_SIZE" "$PQC_CA_CERT_SIZE" " B"
print_comparison_row "  Key size" "$CLASSIC_CA_KEY_SIZE" "$PQC_CA_KEY_SIZE" " B"

echo ""
echo -e "${BOLD}TLS Server Certificate${NC}"
print_comparison_row "  Cert size" "$CLASSIC_CERT_SIZE" "$PQC_CERT_SIZE" " B"
print_comparison_row "  Key size" "$CLASSIC_KEY_SIZE" "$PQC_KEY_SIZE" " B"

# =============================================================================
# Conclusion
# =============================================================================

echo ""
echo -e "${BOLD}What stayed the same:${NC}"
echo "  - Commands: init-ca, issue"
echo "  - Workflow: CA -> Certificate"
echo "  - Structure: X.509 certificates"
echo ""

echo -e "${BOLD}What changed:${NC}"
echo "  - Profile: ec/* -> ml-dsa/*"
echo "  - Sizes: ~5-10x larger"
echo ""

show_lesson "Switching to post-quantum is a profile change, not an architecture change.
Your PKI workflow stays exactly the same."

# =============================================================================
# Teaser
# =============================================================================

echo ""
echo -e "${BOLD}${YELLOW}But wait...${NC}"
echo ""
echo "  This classical PKI works perfectly today."
echo "  The question is: ${BOLD}for how long?${NC}"
echo ""
echo "  Your ECDSA certificates are being harvested right now."
echo "  When quantum computers arrive, they'll be decrypted."
echo ""
echo -e "  ${CYAN}Next mission:${NC} ./journey/00-revelation/demo.sh"
echo -e "  ${DIM}Discover the \"Store Now, Decrypt Later\" threat.${NC}"
echo ""

echo -e "${DIM}Explore artifacts: $DEMO_TMP${NC}"
echo ""

show_footer
