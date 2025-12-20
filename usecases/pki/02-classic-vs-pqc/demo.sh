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
echo "  1. Create a classical CA (ECDSA P-384)"
echo "  2. Issue a classical TLS server certificate"
echo "  3. Create a post-quantum CA (ML-DSA-65)"
echo "  4. Issue a post-quantum TLS server certificate"
echo "  5. Compare: sizes and performance"
echo ""

pause "Press Enter to start..."

# =============================================================================
# Step 1: Create Classical CA
# =============================================================================

step "Create Classical CA (ECDSA P-384)" \
     "ECDSA with curve P-384 provides ~192-bit security against classical computers."

run_cmd "$PKI_BIN init-ca --name 'Classic Root CA' --org 'Demo' --algorithm ecdsa-p384 --dir $CLASSIC_CA"

show_files "$CLASSIC_CA"

pause

# =============================================================================
# Step 2: Issue Classical TLS Certificate
# =============================================================================

step "Issue Classical TLS Certificate" \
     "Standard server certificate for classic.example.com"

run_cmd "$PKI_BIN issue --ca-dir $CLASSIC_CA --profile ec/tls-server --cn classic.example.com --out $DEMO_TMP/classic-server.crt --key-out $DEMO_TMP/classic-server.key"

show_cert_brief "$DEMO_TMP/classic-server.crt" "Classical TLS Certificate"

pause

# =============================================================================
# Step 3: Create Post-Quantum CA
# =============================================================================

step "Create Post-Quantum CA (ML-DSA-65)" \
     "ML-DSA (FIPS 204) provides quantum-resistant signatures at security level 3."

run_cmd "$PKI_BIN init-ca --name 'PQ Root CA' --org 'Demo' --algorithm ml-dsa-65 --dir $PQC_CA"

show_files "$PQC_CA"

pause

# =============================================================================
# Step 4: Issue Post-Quantum TLS Certificate
# =============================================================================

step "Issue Post-Quantum TLS Certificate" \
     "Same workflow, different algorithm - certificate for pq.example.com"

run_cmd "$PKI_BIN issue --ca-dir $PQC_CA --profile ml-dsa-kem/tls-server --cn pq.example.com --out $DEMO_TMP/pq-server.crt --key-out $DEMO_TMP/pq-server.key"

show_cert_brief "$DEMO_TMP/pq-server.crt" "Post-Quantum TLS Certificate"

pause

# =============================================================================
# Step 5: Comparison
# =============================================================================

step "Comparison" \
     "Let's compare the sizes between classical and post-quantum."

# Get sizes
CLASSIC_CA_CERT_SIZE=$(cert_size "$CLASSIC_CA/ca.crt")
CLASSIC_CA_KEY_SIZE=$(key_size "$CLASSIC_CA/ca.key")
CLASSIC_CERT_SIZE=$(cert_size "$DEMO_TMP/classic-server.crt")
CLASSIC_KEY_SIZE=$(key_size "$DEMO_TMP/classic-server.key")

PQC_CA_CERT_SIZE=$(cert_size "$PQC_CA/ca.crt")
PQC_CA_KEY_SIZE=$(key_size "$PQC_CA/ca.key")
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
echo "  - Certificate structure (X.509)"
echo "  - CA hierarchy concept"
echo "  - Issuance workflow"
echo "  - Trust model"
echo ""

echo -e "${BOLD}What changed:${NC}"
echo "  - Algorithm: ECDSA -> ML-DSA"
echo "  - Sizes: ~10x larger certificates and keys"
echo ""

show_lesson "Post-quantum PKI uses the same concepts as classical PKI.
The migration is about changing algorithms, not changing architecture."

echo -e "${DIM}Explore generated artifacts: $DEMO_TMP${NC}"
echo ""

show_footer
