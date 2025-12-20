#!/bin/bash
# =============================================================================
#  UC-01: "Nothing changes... except the algorithm"
#
#  Compare Classical (ECDSA) vs Post-Quantum (ML-DSA) TLS certificates
#
#  Key Message: The PKI doesn't change. Only the algorithm changes.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "UC-01: Nothing changes... except the algorithm"

CLASSIC_CA="$DEMO_TMP/classic-ca"
PQC_CA="$DEMO_TMP/pqc-ca"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"I want to issue post-quantum certificates."
echo "   Does it change my PKI workflow?\""
echo ""
echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Create a classical CA (ECDSA P-384)"
echo "  2. Issue a classical TLS server certificate"
echo "  3. Create a post-quantum CA (ML-DSA-65)"
echo "  4. Issue a post-quantum TLS server certificate"
echo "  5. Compare: key sizes, signature sizes, generation times"
echo ""

pause_for_explanation "Press Enter to start the demo..."

# =============================================================================
# Step 1: Create Classical CA
# =============================================================================

print_step "Step 1: Create Classical CA (ECDSA P-384)"

echo -e "Command:"
echo -e "  ${CYAN}pki init-ca --name \"Classic Root CA\" --algorithm ecdsa-p384 --dir $CLASSIC_CA${NC}"
echo ""

CLASSIC_CA_TIME=$(time_cmd "$PKI_BIN" init-ca \
    --name "Classic Root CA" \
    --org "Demo Organization" \
    --algorithm ecdsa-p384 \
    --dir "$CLASSIC_CA")

print_success "Classical CA created in ${YELLOW}${CLASSIC_CA_TIME}ms${NC}"

# =============================================================================
# Step 2: Issue Classical TLS Certificate
# =============================================================================

print_step "Step 2: Issue Classical TLS Server Certificate"

echo -e "Command:"
echo -e "  ${CYAN}pki issue --ca-dir $CLASSIC_CA --profile ec/tls-server --cn classic.example.com${NC}"
echo ""

CLASSIC_CERT_TIME=$(time_cmd "$PKI_BIN" issue \
    --ca-dir "$CLASSIC_CA" \
    --profile ec/tls-server \
    --cn "classic.example.com" \
    --dns "classic.example.com,www.classic.example.com" \
    --out "$DEMO_TMP/classic-server.crt" \
    --key-out "$DEMO_TMP/classic-server.key")

print_success "Classical certificate issued in ${YELLOW}${CLASSIC_CERT_TIME}ms${NC}"

show_cert_brief "$DEMO_TMP/classic-server.crt" "Classical TLS Certificate"

echo ""
echo -e "  ${CYAN}Inspect certificate:${NC} pki info $DEMO_TMP/classic-server.crt"

# =============================================================================
# Step 3: Create Post-Quantum CA
# =============================================================================

print_step "Step 3: Create Post-Quantum CA (ML-DSA-65)"

echo -e "${CYAN}ML-DSA (Module Lattice Digital Signature Algorithm)${NC}"
echo "  - NIST FIPS 204 standard"
echo "  - Security level 3 (~192-bit classical equivalent)"
echo "  - Resistant to quantum attacks"
echo ""

echo -e "Command:"
echo -e "  ${CYAN}pki init-ca --name \"PQ Root CA\" --algorithm ml-dsa-65 --dir $PQC_CA${NC}"
echo ""

PQC_CA_TIME=$(time_cmd "$PKI_BIN" init-ca \
    --name "PQ Root CA" \
    --org "Demo Organization" \
    --algorithm ml-dsa-65 \
    --dir "$PQC_CA")

print_success "Post-Quantum CA created in ${YELLOW}${PQC_CA_TIME}ms${NC}"

# =============================================================================
# Step 4: Issue Post-Quantum TLS Certificate
# =============================================================================

print_step "Step 4: Issue Post-Quantum TLS Server Certificate"

echo -e "Command:"
echo -e "  ${CYAN}pki issue --ca-dir $PQC_CA --profile ml-dsa-kem/tls-server --cn pq.example.com${NC}"
echo ""

PQC_CERT_TIME=$(time_cmd "$PKI_BIN" issue \
    --ca-dir "$PQC_CA" \
    --profile ml-dsa-kem/tls-server \
    --cn "pq.example.com" \
    --dns "pq.example.com,www.pq.example.com" \
    --out "$DEMO_TMP/pq-server.crt" \
    --key-out "$DEMO_TMP/pq-server.key")

print_success "Post-Quantum certificate issued in ${YELLOW}${PQC_CERT_TIME}ms${NC}"

show_cert_brief "$DEMO_TMP/pq-server.crt" "Post-Quantum TLS Certificate"

echo ""
echo -e "  ${CYAN}Inspect certificate:${NC} pki info $DEMO_TMP/pq-server.crt"

# =============================================================================
# Step 5: Comparison
# =============================================================================

print_step "Step 5: Comparison - Classical vs Post-Quantum"

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
print_comparison_row "  Init time" "$CLASSIC_CA_TIME" "$PQC_CA_TIME" "ms"

echo ""
echo -e "${BOLD}TLS Server Certificate${NC}"
print_comparison_row "  Cert size" "$CLASSIC_CERT_SIZE" "$PQC_CERT_SIZE" " B"
print_comparison_row "  Key size" "$CLASSIC_KEY_SIZE" "$PQC_KEY_SIZE" " B"
print_comparison_row "  Issue time" "$CLASSIC_CERT_TIME" "$PQC_CERT_TIME" "ms"

# =============================================================================
# Key Message
# =============================================================================

print_key_message "The PKI doesn't change. Only the algorithm changes."

echo -e "${BOLD}What stayed the same:${NC}"
echo "  - Certificate structure (X.509)"
echo "  - CA hierarchy concept"
echo "  - Issuance workflow"
echo "  - Revocation mechanism"
echo "  - Trust model"
echo ""

echo -e "${BOLD}What changed:${NC}"
echo "  - Signature algorithm (ECDSA -> ML-DSA)"
echo "  - Key and signature sizes (larger)"
echo "  - Processing time (slightly longer)"
echo ""

echo -e "${BOLD}The trade-off:${NC}"
echo "  Larger certificates and keys = Protection against quantum computers"
echo ""

# =============================================================================
# Lesson Learned
# =============================================================================

show_lesson "Post-quantum PKI uses the same concepts as classical PKI.
The migration is about changing algorithms, not changing architecture.
Your PKI knowledge remains 100% applicable."

show_footer
