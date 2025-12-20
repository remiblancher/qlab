#!/bin/bash
# =============================================================================
#  UC-07: "Smooth rotation with bundles"
#
#  Certificate Bundles for Coupled Lifecycle Management
#
#  Key Message: Bundles group related certificates for synchronized
#               renewal and revocation.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "UC-07: Smooth rotation with bundles"

HYBRID_CA="$DEMO_TMP/hybrid-ca"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"We have hybrid certificates with both classical and PQC keys."
echo "   How do we manage their lifecycle together?\""
echo ""
echo -e "${BOLD}THE PROBLEM:${NC}"
echo "  - Hybrid identities have multiple certificates"
echo "  - Each cert could expire or be revoked separately"
echo "  - Manual management leads to desynchronization"
echo ""
echo -e "${BOLD}THE SOLUTION:${NC}"
echo "  - Certificate bundles with coupled lifecycle"
echo "  - All certs share validity period"
echo "  - Renewal and revocation are atomic"
echo ""
echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Create a hybrid CA"
echo "  2. Enroll a certificate bundle"
echo "  3. Examine bundle contents"
echo "  4. Demonstrate bundle operations"
echo ""

pause_for_explanation "Press Enter to start the demo..."

# =============================================================================
# Step 1: Create Hybrid CA
# =============================================================================

print_step "Step 1: Create Hybrid CA"

echo -e "Command:"
echo -e "  ${CYAN}pki init-ca --name \"Hybrid CA\" --algorithm ecdsa-p384 --hybrid-algorithm ml-dsa-65 --dir $HYBRID_CA${NC}"
echo ""

HYBRID_CA_TIME=$(time_cmd "$PKI_BIN" init-ca \
    --name "Hybrid CA" \
    --org "Demo Organization" \
    --algorithm ecdsa-p384 \
    --hybrid-algorithm ml-dsa-65 \
    --dir "$HYBRID_CA")

print_success "Hybrid CA created in ${YELLOW}${HYBRID_CA_TIME}ms${NC}"

echo ""
echo -e "  ${CYAN}Inspect CA:${NC} pki info $HYBRID_CA/ca.crt"

# =============================================================================
# Step 2: Enroll Certificate Bundle
# =============================================================================

print_step "Step 2: Enroll Certificate Bundle"

echo -e "${CYAN}Enrolling creates a complete bundle with all certificates:${NC}"
echo "  - Classical certificate (ECDSA)"
echo "  - PQC certificate (ML-DSA)"
echo "  - All with coupled lifecycle"
echo ""

echo -e "Command:"
echo -e "  ${CYAN}pki enroll --ca-dir $HYBRID_CA --profile hybrid/catalyst/tls-client --subject \"CN=Alice,O=Demo\" --out $DEMO_TMP/alice${NC}"
echo ""

ENROLL_TIME=$(time_cmd "$PKI_BIN" enroll \
    --ca-dir "$HYBRID_CA" \
    --profile hybrid/catalyst/tls-client \
    --subject "CN=Alice,O=Demo Organization" \
    --out "$DEMO_TMP/alice")

print_success "Bundle enrolled in ${YELLOW}${ENROLL_TIME}ms${NC}"

# =============================================================================
# Step 3: Examine Bundle Contents
# =============================================================================

print_step "Step 3: Examine Bundle Contents"

echo -e "${CYAN}Bundle directory contents:${NC}"
echo ""
ls -la "$DEMO_TMP/alice/" 2>/dev/null || echo "  (bundle files created)"
echo ""

echo -e "${CYAN}Inspect the certificate:${NC}"
echo -e "  ${CYAN}pki info $DEMO_TMP/alice/*.crt${NC}"
echo ""

# Show certificate info
for crt in "$DEMO_TMP/alice"/*.crt; do
    if [ -f "$crt" ]; then
        echo -e "${BOLD}$(basename "$crt"):${NC}"
        "$PKI_BIN" info "$crt" 2>/dev/null | head -10
        echo ""
    fi
done

# =============================================================================
# Step 4: Bundle Operations
# =============================================================================

print_step "Step 4: Bundle Operations"

echo -e "${CYAN}List all bundles:${NC}"
echo -e "  ${CYAN}pki bundle list --ca-dir $HYBRID_CA${NC}"
echo ""

"$PKI_BIN" bundle list --ca-dir "$HYBRID_CA" 2>/dev/null || echo "  (bundles listed)"

echo ""
echo -e "${CYAN}Available bundle operations:${NC}"
echo ""
echo "  pki bundle list --ca-dir <ca>        # List all bundles"
echo "  pki bundle info <id> --ca-dir <ca>   # Show bundle details"
echo "  pki bundle renew <id> --ca-dir <ca>  # Renew all certs"
echo "  pki bundle revoke <id> --ca-dir <ca> # Revoke all certs"
echo "  pki bundle export <id> --ca-dir <ca> # Export combined PEM"
echo ""

# =============================================================================
# Why This Matters
# =============================================================================

print_step "Step 5: Why Bundles Matter"

echo -e "${CYAN}Without bundles:${NC}"
echo ""
echo "  Hybrid Identity \"Alice\""
echo "  ├── Classical cert (ECDSA)    → Expires 2026-01-15"
echo "  ├── PQC cert (ML-DSA)         → Expires 2026-01-15 (maybe?)"
echo "  └── KEM cert (ML-KEM)         → Expires 2026-01-16 (oops!)"
echo ""
echo "  ${RED}Problem: Certificates can get out of sync${NC}"
echo ""

echo -e "${CYAN}With bundles:${NC}"
echo ""
echo "  Bundle \"alice-20250119-abcd1234\""
echo "  ├── Classical cert (ECDSA)    ─┐"
echo "  ├── PQC cert (ML-DSA)         ─┼─► Same validity"
echo "  └── KEM cert (ML-KEM)         ─┘   Same renewal"
echo "                                      Same revocation"
echo ""
echo "  ${GREEN}Solution: All operations are atomic${NC}"
echo ""

# =============================================================================
# Key Message
# =============================================================================

print_key_message "Bundles group related certificates for synchronized lifecycle."

echo -e "${BOLD}What bundles provide:${NC}"
echo "  - Coupled validity periods"
echo "  - Atomic renewal (all certs together)"
echo "  - Atomic revocation (no orphaned certs)"
echo "  - Unified audit trail"
echo ""

echo -e "${BOLD}When to use bundles:${NC}"
echo "  - Hybrid certificates (classical + PQC)"
echo "  - TLS with separate signature and KEM certs"
echo "  - User identities with multiple certificates"
echo "  - Service accounts requiring rotation"
echo ""

# =============================================================================
# Lesson Learned
# =============================================================================

show_lesson "Certificate bundles prevent lifecycle desynchronization.
When you have multiple related certificates,
manage them as a unit, not individually."

show_footer
