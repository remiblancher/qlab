#!/bin/bash
# =============================================================================
#  UC-10: Crypto-Agility - Migrate Without Breaking
#
#  Demonstrate the 3-phase migration strategy:
#  Phase 1: Classic (ECDSA) → Phase 2: Hybrid → Phase 3: Full PQC
#
#  Key Message: Crypto-agility is the ability to change algorithms
#               without breaking your system.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

setup_demo "PQC Crypto-Agility"

# =============================================================================
# Step 1: Understand Crypto-Agility
# =============================================================================

print_step "Step 1: What is Crypto-Agility?"

echo "  Crypto-agility is the ability of a system to:"
echo ""
echo "    1. CHANGE algorithms without redesigning architecture"
echo "    2. SUPPORT multiple algorithms during transition"
echo "    3. ROLLBACK quickly if problems occur"
echo ""
echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  THE 3-PHASE MIGRATION STRATEGY                                │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │                                                                 │"
echo "  │  PHASE 1: CLASSIC (today)                                      │"
echo "  │    → ECDSA certificates                                        │"
echo "  │    → Status quo, inventory your systems                        │"
echo "  │                                                                 │"
echo "  │  PHASE 2: HYBRID (transition)                                  │"
echo "  │    → ECDSA + ML-DSA in same certificate                        │"
echo "  │    → Legacy clients use ECDSA, modern use both                 │"
echo "  │    → 100% compatibility                                        │"
echo "  │                                                                 │"
echo "  │  PHASE 3: FULL PQC (when ready)                                │"
echo "  │    → ML-DSA only                                               │"
echo "  │    → After ALL clients migrated                                │"
echo "  │                                                                 │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

pause

# =============================================================================
# Step 2: Phase 1 - Create Classic CA (ECDSA)
# =============================================================================

print_step "Step 2: Phase 1 - Classic CA (ECDSA)"

echo "  Creating a classic ECDSA CA (current state)..."
echo ""

run_cmd "pki ca init --name \"Classic CA\" --algorithm ec-p256 --dir output/classic-ca"

echo ""

# Show certificate info
if [[ -f "output/classic-ca/ca.crt" ]]; then
    cert_size=$(wc -c < "output/classic-ca/ca.crt" | tr -d ' ')
    echo -e "  ${CYAN}Certificate size:${NC} $cert_size bytes"
    echo -e "  ${DIM}(ECDSA P-256 public key: ~91 bytes)${NC}"
fi

echo ""
echo "  Issue a server certificate with ECDSA..."
echo ""

run_cmd "pki cert issue --ca-dir output/classic-ca --profile ec/tls-server --cn \"server.example.com\" --dns server.example.com --out output/classic-server.crt --key-out output/classic-server.key"

echo ""

pause

# =============================================================================
# Step 3: Phase 2 - Create Hybrid CA (ECDSA + ML-DSA)
# =============================================================================

print_step "Step 3: Phase 2 - Hybrid CA (ECDSA + ML-DSA)"

echo "  Creating a hybrid CA with Catalyst mode..."
echo "  Both ECDSA and ML-DSA signatures in one certificate."
echo ""

run_cmd "pki ca init --name \"Hybrid CA\" --algorithm ec-p256 --hybrid-algorithm ml-dsa-65 --dir output/hybrid-ca"

echo ""

if [[ -f "output/hybrid-ca/ca.crt" ]]; then
    cert_size=$(wc -c < "output/hybrid-ca/ca.crt" | tr -d ' ')
    echo -e "  ${CYAN}Certificate size:${NC} $cert_size bytes"
    echo -e "  ${DIM}(Contains BOTH ECDSA and ML-DSA-65 signatures)${NC}"
fi

echo ""
echo "  Issue a hybrid server certificate..."
echo ""

run_cmd "pki cert issue --ca-dir output/hybrid-ca --profile hybrid/catalyst/tls-server --cn \"server.example.com\" --dns server.example.com --out output/hybrid-server.crt --key-out output/hybrid-server.key"

echo ""

pause

# =============================================================================
# Step 4: Phase 3 - Create Full PQC CA (ML-DSA)
# =============================================================================

print_step "Step 4: Phase 3 - Full PQC CA (ML-DSA)"

echo "  Creating a full post-quantum CA..."
echo "  ML-DSA-65 only (no classical fallback)."
echo ""

run_cmd "pki ca init --name \"PQC CA\" --algorithm ml-dsa-65 --dir output/pqc-ca"

echo ""

if [[ -f "output/pqc-ca/ca.crt" ]]; then
    cert_size=$(wc -c < "output/pqc-ca/ca.crt" | tr -d ' ')
    echo -e "  ${CYAN}Certificate size:${NC} $cert_size bytes"
    echo -e "  ${DIM}(ML-DSA-65 public key: ~1,952 bytes)${NC}"
fi

echo ""
echo "  Issue a PQC server certificate..."
echo ""

run_cmd "pki cert issue --ca-dir output/pqc-ca --profile ml-dsa-kem/tls-server --cn \"server.example.com\" --dns server.example.com --out output/pqc-server.crt --key-out output/pqc-server.key"

echo ""

pause

# =============================================================================
# Step 5: Test Interoperability
# =============================================================================

print_step "Step 5: Test Interoperability"

echo "  Testing how different clients handle each certificate type:"
echo ""

echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  INTEROPERABILITY MATRIX                                       │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │                                                                 │"
echo "  │  Certificate     │  OpenSSL (Legacy)  │  pki (PQC-aware)       │"
echo "  │  ──────────────────────────────────────────────────────────────│"

# Test Classic
echo -n "  │  Classic (ECDSA) │  "
if openssl verify -CAfile output/classic-ca/ca.crt output/classic-server.crt > /dev/null 2>&1; then
    echo -ne "${GREEN}✓ OK${NC}               │  "
else
    echo -ne "${RED}✗ FAIL${NC}             │  "
fi
if pki verify --ca output/classic-ca/ca.crt --cert output/classic-server.crt > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}                   │"
else
    echo -e "${RED}✗ FAIL${NC}                 │"
fi

# Test Hybrid
echo -n "  │  Hybrid          │  "
if openssl verify -CAfile output/hybrid-ca/ca.crt output/hybrid-server.crt > /dev/null 2>&1; then
    echo -ne "${GREEN}✓ OK${NC}               │  "
else
    echo -ne "${YELLOW}~ Partial${NC}          │  "
fi
if pki verify --ca output/hybrid-ca/ca.crt --cert output/hybrid-server.crt > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}                   │"
else
    echo -e "${RED}✗ FAIL${NC}                 │"
fi

# Test PQC
echo -n "  │  Full PQC        │  "
if openssl verify -CAfile output/pqc-ca/ca.crt output/pqc-server.crt > /dev/null 2>&1; then
    echo -ne "${GREEN}✓ OK${NC}               │  "
else
    echo -ne "${RED}✗ FAIL${NC}             │  "
fi
if pki verify --ca output/pqc-ca/ca.crt --cert output/pqc-server.crt > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}                   │"
else
    echo -e "${RED}✗ FAIL${NC}                 │"
fi

echo "  │                                                                 │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

echo "  Key insight:"
echo "    - Hybrid certificates work with BOTH legacy and modern clients"
echo "    - Full PQC requires PQC-aware clients"
echo "    - Hybrid is the bridge for gradual migration"
echo ""

pause

# =============================================================================
# Step 6: Size Comparison
# =============================================================================

print_step "Step 6: Size Comparison"

echo "  Certificate sizes across the migration phases:"
echo ""

classic_ca_size=$(wc -c < "output/classic-ca/ca.crt" 2>/dev/null | tr -d ' ')
hybrid_ca_size=$(wc -c < "output/hybrid-ca/ca.crt" 2>/dev/null | tr -d ' ')
pqc_ca_size=$(wc -c < "output/pqc-ca/ca.crt" 2>/dev/null | tr -d ' ')

classic_cert_size=$(wc -c < "output/classic-server.crt" 2>/dev/null | tr -d ' ')
hybrid_cert_size=$(wc -c < "output/hybrid-server.crt" 2>/dev/null | tr -d ' ')
pqc_cert_size=$(wc -c < "output/pqc-server.crt" 2>/dev/null | tr -d ' ')

echo "  ┌──────────────────────────────────────────────────────────────────┐"
echo "  │  Phase         │  CA Cert    │  Server Cert  │  Signature       │"
echo "  ├──────────────────────────────────────────────────────────────────┤"
printf "  │  Phase 1       │  %6s B   │  %6s B     │  ECDSA (~64 B)   │\n" "$classic_ca_size" "$classic_cert_size"
printf "  │  Phase 2       │  %6s B   │  %6s B     │  ECDSA+ML-DSA    │\n" "$hybrid_ca_size" "$hybrid_cert_size"
printf "  │  Phase 3       │  %6s B   │  %6s B     │  ML-DSA (~3.3 KB)│\n" "$pqc_ca_size" "$pqc_cert_size"
echo "  └──────────────────────────────────────────────────────────────────┘"
echo ""

echo "  Size increase is expected and acceptable for security benefits."
echo ""

# =============================================================================
# Conclusion
# =============================================================================

print_key_message "Crypto-agility is the ability to change algorithms without breaking your system. Hybrid is the bridge."

show_lesson "Phase 1 (Classic): Inventory your current certificates.
Phase 2 (Hybrid): Deploy certificates with BOTH classical and PQC.
Phase 3 (Full PQC): When ALL clients are migrated.
Hybrid provides 100% compatibility + PQC protection.
Never do a \"big bang\" migration - it's too risky."

show_footer
