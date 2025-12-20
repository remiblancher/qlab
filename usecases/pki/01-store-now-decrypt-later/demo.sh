#!/bin/bash
# =============================================================================
#  UC-03: "The real problem: Store Now, Decrypt Later"
#
#  Interactive Mosca calculator to assess your PQC migration urgency
#
#  Key Message: Encrypted data captured today can be decrypted tomorrow.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "UC-03: Store Now, Decrypt Later"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"Our data is encrypted. Why worry about quantum computers?\""
echo ""
echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Calculate YOUR urgency with Mosca's inequality"
echo ""

pause_for_explanation "Press Enter to start the calculator..."

# =============================================================================
# Step 1: Mosca's Inequality Calculator
# =============================================================================

print_step "Step 1: Mosca's Inequality Calculator"

echo -e "${CYAN}Formula: If X + Y > Z → You have time. Otherwise → ACT NOW${NC}"
echo ""
echo "  X = Years until quantum computers"
echo "  Y = Years to migrate to PQC"
echo "  Z = Years your data must stay secret"
echo ""

echo -e "${BOLD}Enter your values:${NC}"
echo ""

read -p "  X - Years until quantum computer (default: 10): " X
X=${X:-10}

read -p "  Y - Years to migrate your systems (default: 5): " Y
Y=${Y:-5}

read -p "  Z - Years your data must stay secret: " Z
if [[ -z "$Z" ]]; then
    echo ""
    echo -e "  ${YELLOW}Examples: Healthcare=50, Government=75, Financial=10${NC}"
    read -p "  Z: " Z
    Z=${Z:-20}
fi

# =============================================================================
# Step 2: Calculate Result
# =============================================================================

print_step "Step 2: Result"

SUM=$((X + Y))

echo "  X + Y = $X + $Y = $SUM"
echo "  Z = $Z"
echo ""

if [[ $SUM -gt $Z ]]; then
    print_success "$SUM > $Z → You have time, but start planning now."
else
    echo -e "  ${RED}⚠ $SUM ≤ $Z → ACT NOW! Your data is at risk.${NC}"
fi

# =============================================================================
# Key Message
# =============================================================================

print_key_message "Encrypted data captured today can be decrypted tomorrow."

# =============================================================================
# Lesson Learned
# =============================================================================

show_lesson "SNDL is happening now. Use Mosca's inequality to assess urgency.
See README.md and diagram.txt for detailed threat analysis."

show_footer
