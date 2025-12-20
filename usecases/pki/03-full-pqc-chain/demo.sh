#!/bin/bash
# =============================================================================
#  UC-05: "Full post-quantum chain of trust"
#
#  Build a complete 3-level PQC PKI hierarchy
#
#  Key Message: Complete quantum-resistant PKI from root to end-entity.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "UC-05: Full post-quantum chain of trust"

ROOT_CA="$DEMO_TMP/pqc-root-ca"
ISSUING_CA="$DEMO_TMP/pqc-issuing-ca"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"I'm ready to go fully quantum-safe."
echo "   How do I build a complete PQC PKI from root to end-entity?\""
echo ""
echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Create a Root CA (ML-DSA-87 - highest security)"
echo "  2. Create an Issuing CA (ML-DSA-65 - signed by Root)"
echo "  3. Issue a TLS server certificate (ML-DSA-65 + ML-KEM-768)"
echo "  4. Examine the full chain of trust"
echo ""
echo -e "${CYAN}No classical cryptography anywhere in the chain.${NC}"
echo ""

pause_for_explanation "Press Enter to start the demo..."

# =============================================================================
# Step 1: Create Root CA (ML-DSA-87)
# =============================================================================

print_step "Step 1: Create Root CA (ML-DSA-87)"

echo -e "${CYAN}ML-DSA-87 (Module Lattice Digital Signature Algorithm)${NC}"
echo "  - NIST FIPS 204 standard"
echo "  - Security level 5 (~256-bit classical equivalent)"
echo "  - Recommended for long-lived root CAs"
echo ""

echo -e "Command:"
echo -e "  ${CYAN}pki init-ca --name \"PQC Root CA\" --algorithm ml-dsa-87 --dir $ROOT_CA${NC}"
echo ""

ROOT_CA_TIME=$(time_cmd "$PKI_BIN" init-ca \
    --name "PQC Root CA" \
    --org "Demo Organization" \
    --algorithm ml-dsa-87 \
    --dir "$ROOT_CA")

print_success "Root CA created in ${YELLOW}${ROOT_CA_TIME}ms${NC}"

show_cert_brief "$ROOT_CA/ca.crt" "PQC Root CA"

echo ""
echo -e "  ${CYAN}Inspect certificate:${NC} pki info $ROOT_CA/ca.crt"

# =============================================================================
# Step 2: Create Issuing CA (ML-DSA-65)
# =============================================================================

print_step "Step 2: Create Issuing CA (ML-DSA-65)"

echo -e "${CYAN}Subordinate CA signed by the Root CA${NC}"
echo "  - ML-DSA-65: Security level 3 (~192-bit)"
echo "  - Good balance of security and performance"
echo "  - Used to issue end-entity certificates"
echo ""

echo -e "Command:"
echo -e "  ${CYAN}pki init-ca --name \"PQC Issuing CA\" --algorithm ml-dsa-65 --parent $ROOT_CA --dir $ISSUING_CA${NC}"
echo ""

ISSUING_CA_TIME=$(time_cmd "$PKI_BIN" init-ca \
    --name "PQC Issuing CA" \
    --org "Demo Organization" \
    --algorithm ml-dsa-65 \
    --parent "$ROOT_CA" \
    --dir "$ISSUING_CA")

print_success "Issuing CA created in ${YELLOW}${ISSUING_CA_TIME}ms${NC}"

show_cert_brief "$ISSUING_CA/ca.crt" "PQC Issuing CA"

echo ""
echo -e "  ${CYAN}Inspect certificate:${NC} pki info $ISSUING_CA/ca.crt"

# =============================================================================
# Step 3: Issue TLS Server Certificate
# =============================================================================

print_step "Step 3: Issue TLS Server Certificate"

echo -e "${CYAN}End-entity certificate with dual algorithms:${NC}"
echo "  - ML-DSA-65 for digital signatures"
echo "  - ML-KEM-768 for key encapsulation (TLS handshake)"
echo ""

echo -e "Command:"
echo -e "  ${CYAN}pki issue --ca-dir $ISSUING_CA --profile ml-dsa-kem/tls-server --cn server.example.com${NC}"
echo ""

SERVER_CERT_TIME=$(time_cmd "$PKI_BIN" issue \
    --ca-dir "$ISSUING_CA" \
    --profile ml-dsa-kem/tls-server \
    --cn "server.example.com" \
    --dns "server.example.com,www.server.example.com" \
    --out "$DEMO_TMP/server.crt" \
    --key-out "$DEMO_TMP/server.key")

print_success "TLS Server certificate issued in ${YELLOW}${SERVER_CERT_TIME}ms${NC}"

show_cert_brief "$DEMO_TMP/server.crt" "TLS Server Certificate"

echo ""
echo -e "  ${CYAN}Inspect certificate:${NC} pki info $DEMO_TMP/server.crt"

# =============================================================================
# Step 4: Examine Chain of Trust
# =============================================================================

print_step "Step 4: Examine Chain of Trust"

echo -e "${CYAN}The full certificate chain:${NC}"
echo ""
echo "  ┌─────────────────────────────────────┐"
echo "  │           PQC Root CA               │"
echo "  │           ML-DSA-87                 │"
echo "  │       (NIST Level 5 - highest)      │"
echo "  └─────────────────┬───────────────────┘"
echo "                    │ signs"
echo "                    ▼"
echo "  ┌─────────────────────────────────────┐"
echo "  │         PQC Issuing CA              │"
echo "  │           ML-DSA-65                 │"
echo "  │          (NIST Level 3)             │"
echo "  └─────────────────┬───────────────────┘"
echo "                    │ signs"
echo "                    ▼"
echo "  ┌─────────────────────────────────────┐"
echo "  │       TLS Server Certificate        │"
echo "  │   ML-DSA-65 (sig) + ML-KEM-768 (enc)│"
echo "  │          (NIST Level 3)             │"
echo "  └─────────────────────────────────────┘"
echo ""

# =============================================================================
# Step 5: Size Comparison
# =============================================================================

print_step "Step 5: Size Comparison"

ROOT_CA_CERT_SIZE=$(cert_size "$ROOT_CA/ca.crt")
ROOT_CA_KEY_SIZE=$(key_size "$ROOT_CA/ca.key")
ISSUING_CA_CERT_SIZE=$(cert_size "$ISSUING_CA/ca.crt")
ISSUING_CA_KEY_SIZE=$(key_size "$ISSUING_CA/ca.key")
SERVER_CERT_SIZE=$(cert_size "$DEMO_TMP/server.crt")
SERVER_KEY_SIZE=$(key_size "$DEMO_TMP/server.key")

# Calculate chain size
CHAIN_SIZE=$((ROOT_CA_CERT_SIZE + ISSUING_CA_CERT_SIZE + SERVER_CERT_SIZE))

echo -e "${BOLD}Certificate Sizes:${NC}"
echo ""
printf "  %-25s %8s %8s\n" "" "Cert" "Key"
printf "  %-25s %8s %8s\n" "" "────" "────"
printf "  %-25s %7d B %7d B\n" "Root CA (ML-DSA-87)" "$ROOT_CA_CERT_SIZE" "$ROOT_CA_KEY_SIZE"
printf "  %-25s %7d B %7d B\n" "Issuing CA (ML-DSA-65)" "$ISSUING_CA_CERT_SIZE" "$ISSUING_CA_KEY_SIZE"
printf "  %-25s %7d B %7d B\n" "TLS Server" "$SERVER_CERT_SIZE" "$SERVER_KEY_SIZE"
echo ""
printf "  %-25s %7d B\n" "Full chain total" "$CHAIN_SIZE"
echo ""

echo -e "${CYAN}For comparison, a classical ECDSA chain would be ~3 KB total.${NC}"
echo -e "${CYAN}The trade-off: ~6x larger certificates for quantum resistance.${NC}"
echo ""

# =============================================================================
# Key Message
# =============================================================================

print_key_message "Complete quantum-resistant PKI from root to end-entity."

echo -e "${BOLD}What this demonstrates:${NC}"
echo "  - Full 3-level hierarchy (Root → Issuing → End-entity)"
echo "  - All certificates use post-quantum algorithms"
echo "  - No classical cryptography anywhere"
echo "  - Ready for post-quantum world"
echo ""

echo -e "${BOLD}Algorithm selection strategy:${NC}"
echo "  - Root CA: ML-DSA-87 (highest security, longest-lived)"
echo "  - Issuing CA: ML-DSA-65 (balanced)"
echo "  - End-entity: ML-DSA-65 + ML-KEM-768 (signatures + encryption)"
echo ""

echo -e "${BOLD}When to use Full PQC:${NC}"
echo "  - New internal PKI projects"
echo "  - Government/military systems"
echo "  - Long-lived IoT devices"
echo "  - Critical infrastructure"
echo ""

# =============================================================================
# Lesson Learned
# =============================================================================

show_lesson "Building a full PQC PKI uses the same concepts as classical PKI.
The hierarchy, trust model, and workflows are unchanged.
Only the algorithms differ - and they're larger."

show_footer
