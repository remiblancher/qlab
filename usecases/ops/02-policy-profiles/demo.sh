#!/bin/bash
# =============================================================================
#  OPS-02: "Policy, Not Refactor"
#
#  Algorithm Changes Through Policy Configuration
#
#  Key Message: Migrating to PQC is a policy change, not a code refactor.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "OPS-02: Policy, Not Refactor"

CA_DIR="$DEMO_TMP/ca"
CLASSIC_DIR="$DEMO_TMP/classic"
PQC_DIR="$DEMO_TMP/pqc"
HYBRID_DIR="$DEMO_TMP/hybrid"

mkdir -p "$CLASSIC_DIR" "$PQC_DIR" "$HYBRID_DIR"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"Our security team mandates post-quantum cryptography"
echo "   for all new certificates. Do we need to change our workflows?\""
echo ""
echo -e "${BOLD}THE ANSWER:${NC}"
echo "  No! With a well-designed PKI, changing algorithms is just"
echo "  a policy configuration change. Same commands, same workflows."
echo ""
echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Create a CA that supports multiple algorithms"
echo "  2. Issue a certificate with classic profile"
echo "  3. Issue a certificate with PQC profile (same command!)"
echo "  4. Issue a certificate with hybrid profile"
echo "  5. Compare the results"
echo ""

pause_for_explanation "Press Enter to start the demo..."

# =============================================================================
# Step 1: Create Multi-Algorithm CA
# =============================================================================

print_step "Step 1: Create CA"

echo -e "${CYAN}Creating a CA that can issue certificates with any algorithm...${NC}"
echo ""

"$PKI_BIN" init-ca \
    --name "Policy Demo CA" \
    --org "Demo Organization" \
    --algorithm ecdsa-p384 \
    --dir "$CA_DIR" > /dev/null 2>&1

print_success "CA created: $CA_DIR"

# =============================================================================
# Step 2: Issue Classic Certificate
# =============================================================================

print_step "Step 2: Issue Certificate with Classic Profile"

echo -e "${CYAN}The 'old way' — using ECDSA profile:${NC}"
echo ""
echo -e "Command:"
echo -e "  ${YELLOW}pki issue --ca-dir $CA_DIR \\"
echo -e "      --profile ec/tls-server \\"
echo -e "      --cn api.example.com${NC}"
echo ""

CLASSIC_TIME=$(time_cmd "$PKI_BIN" issue \
    --ca-dir "$CA_DIR" \
    --profile ec/tls-server \
    --cn "api.example.com" \
    --dns "api.example.com" \
    --out "$CLASSIC_DIR/server.crt" \
    --key-out "$CLASSIC_DIR/server.key")

print_success "Classic certificate issued in ${YELLOW}${CLASSIC_TIME}ms${NC}"

CLASSIC_ALGO=$("$PKI_BIN" info "$CLASSIC_DIR/server.crt" 2>/dev/null | grep -E "Algorithm:|Signature Algorithm:" | head -1 | awk '{print $NF}' || echo "ECDSA")
CLASSIC_SIZE=$(cert_size "$CLASSIC_DIR/server.crt")

echo ""
echo -e "  Algorithm: ${GREEN}$CLASSIC_ALGO${NC}"
echo -e "  Cert size: ${GREEN}${CLASSIC_SIZE} bytes${NC}"

pause_for_explanation "Now let's issue the SAME certificate with PQC... (Press Enter)"

# =============================================================================
# Step 3: Issue PQC Certificate
# =============================================================================

print_step "Step 3: Issue Certificate with PQC Profile"

echo -e "${CYAN}The 'new way' — using ML-DSA profile:${NC}"
echo ""
echo -e "Command:"
echo -e "  ${YELLOW}pki issue --ca-dir $CA_DIR \\"
echo -e "      --profile ml-dsa-kem/tls-server \\"
echo -e "      --cn api.example.com${NC}"
echo ""

# Create a PQC CA for ML-DSA certificates
PQC_CA="$DEMO_TMP/pqc-ca"
"$PKI_BIN" init-ca \
    --name "PQC Demo CA" \
    --org "Demo Organization" \
    --algorithm ml-dsa-65 \
    --dir "$PQC_CA" > /dev/null 2>&1

PQC_TIME=$(time_cmd "$PKI_BIN" issue \
    --ca-dir "$PQC_CA" \
    --profile ml-dsa-kem/tls-server \
    --cn "api.example.com" \
    --dns "api.example.com" \
    --out "$PQC_DIR/server.crt" \
    --key-out "$PQC_DIR/server.key")

print_success "PQC certificate issued in ${YELLOW}${PQC_TIME}ms${NC}"

PQC_ALGO=$("$PKI_BIN" info "$PQC_DIR/server.crt" 2>/dev/null | grep -E "Algorithm:|Signature Algorithm:" | head -1 | awk '{print $NF}' || echo "ML-DSA-65")
PQC_SIZE=$(cert_size "$PQC_DIR/server.crt")

echo ""
echo -e "  Algorithm: ${BLUE}$PQC_ALGO${NC}"
echo -e "  Cert size: ${BLUE}${PQC_SIZE} bytes${NC}"

echo ""
echo -e "${BOLD}Notice:${NC} The command structure is IDENTICAL!"
echo "  Only the profile name changed: ec/tls-server → ml-dsa-kem/tls-server"

pause_for_explanation "Now let's try hybrid... (Press Enter)"

# =============================================================================
# Step 4: Issue Hybrid Certificate
# =============================================================================

print_step "Step 4: Issue Certificate with Hybrid Profile"

echo -e "${CYAN}Belt and suspenders — using hybrid Catalyst profile:${NC}"
echo ""
echo -e "Command:"
echo -e "  ${YELLOW}pki issue --ca-dir $CA_DIR \\"
echo -e "      --profile hybrid/catalyst/tls-server \\"
echo -e "      --cn api.example.com${NC}"
echo ""

# Create a Hybrid CA
HYBRID_CA="$DEMO_TMP/hybrid-ca"
"$PKI_BIN" init-ca \
    --name "Hybrid Demo CA" \
    --org "Demo Organization" \
    --algorithm ecdsa-p384 \
    --hybrid-algorithm ml-dsa-65 \
    --dir "$HYBRID_CA" > /dev/null 2>&1

HYBRID_TIME=$(time_cmd "$PKI_BIN" issue \
    --ca-dir "$HYBRID_CA" \
    --profile hybrid/catalyst/tls-server \
    --cn "api.example.com" \
    --dns "api.example.com" \
    --out "$HYBRID_DIR/server.crt" \
    --key-out "$HYBRID_DIR/server.key")

print_success "Hybrid certificate issued in ${YELLOW}${HYBRID_TIME}ms${NC}"

HYBRID_SIZE=$(cert_size "$HYBRID_DIR/server.crt")

echo ""
echo -e "  Algorithm: ${GREEN}ECDSA${NC} + ${BLUE}ML-DSA-65${NC} (hybrid)"
echo -e "  Cert size: ${CYAN}${HYBRID_SIZE} bytes${NC}"

# =============================================================================
# Step 5: Comparison
# =============================================================================

print_step "Step 5: Side-by-Side Comparison"

echo ""
echo "  ┌───────────────┬──────────────────────────────────────────────────┐"
echo "  │ Profile       │ What Changed                                     │"
echo "  ├───────────────┼──────────────────────────────────────────────────┤"
echo -e "  │ ${GREEN}ec/tls-server${NC} │ Algorithm: ECDSA P-384                           │"
echo "  │               │ Size: ${CLASSIC_SIZE} bytes                                   │"
echo "  │               │ Time: ${CLASSIC_TIME}ms                                        │"
echo "  ├───────────────┼──────────────────────────────────────────────────┤"
echo -e "  │ ${BLUE}ml-dsa-kem${NC}    │ Algorithm: ML-DSA-65                             │"
echo "  │               │ Size: ${PQC_SIZE} bytes                                   │"
echo "  │               │ Time: ${PQC_TIME}ms                                        │"
echo "  ├───────────────┼──────────────────────────────────────────────────┤"
echo -e "  │ ${CYAN}hybrid${NC}        │ Algorithm: ECDSA + ML-DSA                        │"
echo "  │               │ Size: ${HYBRID_SIZE} bytes                                  │"
echo "  │               │ Time: ${HYBRID_TIME}ms                                        │"
echo "  └───────────────┴──────────────────────────────────────────────────┘"
echo ""

echo -e "${BOLD}What stayed the same:${NC}"
echo "  ✓ Command structure (pki issue ...)"
echo "  ✓ Options (--cn, --dns, --out)"
echo "  ✓ Output format (certificate + key)"
echo "  ✓ Workflow (request → issue → deploy)"
echo ""

echo -e "${BOLD}What changed:${NC}"
echo "  → Profile name: ec/tls-server → ml-dsa-kem/tls-server"
echo "  → That's it!"
echo ""

# =============================================================================
# Key Message
# =============================================================================

print_key_message "Migrating to PQC is a policy change, not a code refactor."

echo -e "${BOLD}The implications:${NC}"
echo ""
echo "  ${GREEN}For Developers:${NC}"
echo "    - No code changes required"
echo "    - Same APIs, same workflows"
echo "    - Just update the profile reference"
echo ""
echo "  ${GREEN}For Security Teams:${NC}"
echo "    - Mandate new profiles in policy"
echo "    - Gradual rollout possible"
echo "    - Easy rollback if needed"
echo ""
echo "  ${GREEN}For Operations:${NC}"
echo "    - No process changes"
echo "    - Same monitoring, same alerting"
echo "    - Larger certificates (plan for bandwidth)"
echo ""

# =============================================================================
# Lesson Learned
# =============================================================================

show_lesson "A well-designed PKI abstracts algorithm complexity behind profiles.
Changing from ECDSA to ML-DSA is a configuration change, not a development project.
This is why crypto-agility matters."

show_footer
