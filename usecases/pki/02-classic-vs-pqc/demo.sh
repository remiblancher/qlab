#!/bin/bash
# =============================================================================
#  PKI-02: "Classic vs PQC: Nothing Changes"
#
#  Compare Classical (ECDSA) vs Post-Quantum (ML-DSA) certificates
#
#  Key Message: The PKI doesn't change. Only the algorithm changes.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "PKI-02: Classic vs PQC"

CLASSIC_CA="$DEMO_TMP/classic-ca"
PQC_CA="$DEMO_TMP/pqc-ca"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"I want to issue post-quantum certificates."
echo "   Does it change my PKI workflow?\""
echo ""

init_steps 5

echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Create a classical Root CA using profile 'ec/root-ca'"
echo "  2. Issue a TLS certificate using profile 'ec/tls-server'"
echo "  3. Create a post-quantum Root CA using profile 'ml-dsa-kem/root-ca'"
echo "  4. Issue a TLS certificate using profile 'ml-dsa-kem/tls-server'"
echo "  5. Compare sizes"
echo ""

echo -e "${DIM}A profile defines: algorithm + validity + X.509 extensions${NC}"
echo ""

pause "Press Enter to start..."

# =============================================================================
# Step 1: Create Classical CA
# =============================================================================

step "Create Classical Root CA" \
     "Profile 'ec/root-ca' = ECDSA P-384, 20 years validity, CA extensions"

run_cmd "$PKI_BIN init-ca --profile ec/root-ca --name 'Classic Root CA' --dir $CLASSIC_CA"
run_cmd "$PKI_BIN info $CLASSIC_CA/ca.crt"

show_files "$CLASSIC_CA"

pause

# =============================================================================
# Step 2: Issue Classical TLS Certificate
# =============================================================================

step "Issue Classical TLS Certificate" \
     "Profile 'ec/tls-server' = ECDSA key, TLS Server extensions (EKU, SAN)"

run_cmd "$PKI_BIN issue --ca-dir $CLASSIC_CA --profile ec/tls-server --cn classic.example.com --dns classic.example.com --out $DEMO_TMP/classic-server.crt --key-out $DEMO_TMP/classic-server.key"
run_cmd "$PKI_BIN info $DEMO_TMP/classic-server.crt"

pause

# =============================================================================
# Step 3: Create Post-Quantum CA
# =============================================================================

step "Create Post-Quantum Root CA" \
     "Profile 'ml-dsa-kem/root-ca' = ML-DSA-65 (FIPS 204), 20 years, CA extensions"

run_cmd "$PKI_BIN init-ca --profile ml-dsa-kem/root-ca --name 'PQ Root CA' --dir $PQC_CA"
run_cmd "$PKI_BIN info $PQC_CA/ca.crt"

show_files "$PQC_CA"

pause

# =============================================================================
# Step 4: Issue Post-Quantum TLS Certificate
# =============================================================================

step "Issue Post-Quantum TLS Certificate" \
     "Profile 'ml-dsa-kem/tls-server' = ML-DSA + ML-KEM keys, TLS Server extensions"

run_cmd "$PKI_BIN issue --ca-dir $PQC_CA --profile ml-dsa-kem/tls-server --cn pq.example.com --dns pq.example.com --out $DEMO_TMP/pq-server.crt --key-out $DEMO_TMP/pq-server.key"
run_cmd "$PKI_BIN info $DEMO_TMP/pq-server.crt"

pause

# =============================================================================
# Step 5: Comparison
# =============================================================================

step "Comparison" \
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
echo "  - Profile: ec/* -> ml-dsa-kem/*"
echo "  - Sizes: ~10x larger"
echo ""

show_lesson "Switching to post-quantum is a profile change, not an architecture change.
Your PKI workflow stays exactly the same."

echo -e "${DIM}Explore artifacts: $DEMO_TMP${NC}"
echo ""

show_footer
