#!/bin/bash
# =============================================================================
#  UC-00: The Revelation - Store Now, Decrypt Later
#
#  Interactive Mosca calculator to assess your PQC migration urgency
#
#  Key Message: Encryption and signatures are both at risk. PQC is urgent.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

setup_demo "The Revelation: The Quantum Threat"

# Introduction
echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"Our data is encrypted. Why worry about quantum computers?\""
echo ""
echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Understand the SNDL threat"
echo "  2. Calculate YOUR urgency with Mosca's theorem"
echo ""

pause "Press Enter to start..."

# =============================================================================
# Step 1: The SNDL Threat
# =============================================================================

print_step "Step 1: The SNDL Threat"

echo "  Store Now, Decrypt Later (SNDL):"
echo ""
echo "  Adversaries capture your encrypted traffic TODAY."
echo "  When quantum computers arrive, they decrypt EVERYTHING."
echo ""
echo -e "  ${YELLOW}The attack requires NO active hacking — just recording traffic.${NC}"
echo ""
echo "  ┌─────────────────────────────────────────────────────────────┐"
echo "  │  TODAY                              FUTURE (10-15 years)    │"
echo "  │                                                             │"
echo "  │  [Capture Traffic]  ─────────►  [Quantum Computer]          │"
echo "  │         │                              │                    │"
echo "  │         │                              ▼                    │"
echo "  │         │                       [Decrypt ALL]               │"
echo "  │         │                       Your secrets                │"
echo "  │         ▼                       are exposed                 │"
echo "  │  [Store encrypted data]                                     │"
echo "  └─────────────────────────────────────────────────────────────┘"
echo ""

pause

# =============================================================================
# Step 2: Mosca's Inequality Calculator
# =============================================================================

print_step "Step 2: Mosca's Theorem Calculator"

echo -e "${CYAN}Formula: If X + Y > Z → ACT NOW${NC}"
echo ""
echo "  X = Security shelf-life (how long your data must stay secret)"
echo "  Y = Time to migrate your systems to post-quantum"
echo "  Z = Time until quantum computers break current crypto"
echo ""

# CI mode: use defaults without prompting
if [[ "${CI:-false}" == "true" ]]; then
    X=50
    Y=5
    Z=10
    echo "  [CI mode] Using defaults: X=$X, Y=$Y, Z=$Z"
else
    echo -e "${BOLD}Enter your values:${NC}"
    echo ""

    read -p "  X - Years your data must stay secret: " X
    if [[ -z "$X" ]]; then
        echo ""
        echo -e "  ${YELLOW}Examples: Healthcare=50, Government=75, Firmware=20${NC}"
        read -p "  X: " X
        X=${X:-50}
    fi

    read -p "  Y - Years to migrate your systems (default: 5): " Y
    Y=${Y:-5}

    read -p "  Z - Years until quantum computer (default: 10): " Z
    Z=${Z:-10}
fi

# =============================================================================
# Result
# =============================================================================

echo ""
print_step "Result"

SUM=$((X + Y))

echo "  X + Y = $X + $Y = $SUM"
echo "  Z = $Z"
echo ""

if [[ $SUM -gt $Z ]]; then
    echo -e "  ${RED}⚠ $SUM > $Z → ACT NOW! You need $X years of protection, but quantum arrives in $Z.${NC}"
else
    print_success "$SUM ≤ $Z → You have time, but start planning now."
fi

pause

# =============================================================================
# Step 3: The Solutions - NIST Standards
# =============================================================================

print_step "Step 3: The Solutions"

echo "  NIST finalized 3 post-quantum algorithms (August 2024):"
echo ""
echo "  ┌─────────────────────────────────────────────────────────────┐"
echo "  │  Algorithm   │  Standard  │  Protects Against  │  Replaces │"
echo "  ├─────────────────────────────────────────────────────────────┤"
echo "  │  ML-KEM      │  FIPS 203  │  SNDL (encryption) │  ECDH     │"
echo "  │  ML-DSA      │  FIPS 204  │  TNFL (signatures) │  ECDSA    │"
echo "  │  SLH-DSA     │  FIPS 205  │  TNFL (hash-based) │  RSA      │"
echo "  └─────────────────────────────────────────────────────────────┘"
echo ""
echo -e "  ${GREEN}This lab focuses on ML-DSA for PKI signatures.${NC}"
echo ""

# =============================================================================
# Conclusion
# =============================================================================

print_key_message "Encryption and signatures are both at risk. Start your PQC migration now."

show_lesson "SNDL and TNFL are happening now. Use Mosca's theorem to assess urgency.
See README.md for detailed threat analysis."

show_footer
