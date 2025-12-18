#!/bin/bash
# =============================================================================
#  UC-03: "The real problem: Store Now, Decrypt Later"
#
#  Demonstrate the SNDL threat and why PQC encryption is urgent
#
#  Key Message: Encrypted data captured today can be decrypted tomorrow.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "UC-03: Store Now, Decrypt Later"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"Our data is encrypted with TLS and AES-256."
echo "   Why should I worry about quantum computers?\""
echo ""
echo -e "${BOLD}THE PROBLEM:${NC}"
echo "  Adversaries are recording your encrypted traffic TODAY."
echo "  When quantum computers arrive, they'll decrypt it ALL."
echo "  This is called: ${RED}Store Now, Decrypt Later (SNDL)${NC}"
echo "  Also known as: ${RED}Harvest Now, Decrypt Later (HNDL)${NC}"
echo ""
echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Understand the SNDL threat timeline"
echo "  2. See why key exchange is the vulnerable point"
echo "  3. Calculate YOUR urgency with Mosca's inequality"
echo "  4. Explore the solution: ML-KEM (FIPS 203)"
echo ""

pause_for_explanation "Press Enter to understand the threat..."

# =============================================================================
# Step 1: The SNDL Attack
# =============================================================================

print_step "Step 1: The Store Now, Decrypt Later Attack"

echo -e "${CYAN}How SNDL works:${NC}"
echo ""
echo "  TODAY                              FUTURE (10-15 years?)"
echo "  ─────                              ────────────────────"
echo ""
echo "  ┌─────────────┐                    ┌─────────────────┐"
echo "  │   You       │                    │   Adversary     │"
echo "  │   send      │───────────────────►│   has stored    │"
echo "  │   data      │  Encrypted TLS     │   your traffic  │"
echo "  └─────────────┘  (captured)        └────────┬────────┘"
echo "                                              │"
echo "                                              ▼"
echo "                                     ┌─────────────────┐"
echo "                                     │    Quantum      │"
echo "                                     │    Computer     │"
echo "                                     └────────┬────────┘"
echo "                                              │"
echo "                                              ▼"
echo "                                     ┌─────────────────┐"
echo "                                     │  ${RED}DECRYPTED!${NC}     │"
echo "                                     │  All secrets    │"
echo "                                     │  exposed        │"
echo "                                     └─────────────────┘"
echo ""

echo -e "${YELLOW}Key insight:${NC} The encryption (AES-256) is NOT the problem."
echo "             The KEY EXCHANGE (ECDH/RSA) IS the problem."
echo ""

pause_for_explanation "Press Enter to see why key exchange is vulnerable..."

# =============================================================================
# Step 2: Why Key Exchange is Vulnerable
# =============================================================================

print_step "Step 2: The Weak Link - Key Exchange"

echo -e "${CYAN}TLS Handshake (simplified):${NC}"
echo ""
echo "  Client                              Server"
echo "    │                                    │"
echo "    │─── ClientHello ──────────────────►│"
echo "    │◄── ServerHello + Certificate ─────│"
echo "    │                                    │"
echo "    │    ${RED}Key Exchange (ECDHE)${NC}           │"
echo "    │─── Client Key Share ─────────────►│"
echo "    │◄── Server Key Share ──────────────│"
echo "    │                                    │"
echo "    │    Shared Secret = ECDH(keys)      │"
echo "    │    Session Key = KDF(shared)       │"
echo "    │                                    │"
echo "    │◄═══ Encrypted Application Data ═══►│"
echo ""

echo -e "${BOLD}The vulnerability:${NC}"
echo ""
echo "  ┌────────────────────────────────────────────────────┐"
echo "  │  A quantum computer can solve:                     │"
echo "  │                                                    │"
echo "  │  • Discrete Log (ECDH) → Shor's algorithm          │"
echo "  │  • Integer Factorization (RSA) → Shor's algorithm  │"
echo "  │                                                    │"
echo "  │  From PUBLIC keys, recover the SHARED SECRET       │"
echo "  │  Then decrypt ALL the recorded traffic             │"
echo "  └────────────────────────────────────────────────────┘"
echo ""

echo -e "${YELLOW}Note:${NC} AES-256 remains secure against quantum attacks."
echo "      Only the key exchange needs to change."
echo ""

pause_for_explanation "Press Enter to calculate YOUR urgency..."

# =============================================================================
# Step 3: Mosca's Inequality
# =============================================================================

print_step "Step 3: Calculate Your Urgency - Mosca's Inequality"

echo -e "${CYAN}Michele Mosca's formula:${NC}"
echo ""
echo "  ┌─────────────────────────────────────────────────────┐"
echo "  │                                                     │"
echo "  │   If  X + Y > Z  then  ${RED}ACT NOW${NC}                     │"
echo "  │                                                     │"
echo "  │   Where:                                            │"
echo "  │     X = Years until quantum computer exists         │"
echo "  │     Y = Years to migrate your systems               │"
echo "  │     Z = Years your data needs to stay secret        │"
echo "  │                                                     │"
echo "  └─────────────────────────────────────────────────────┘"
echo ""

echo -e "${BOLD}Example scenarios:${NC}"
echo ""
printf "  %-25s %5s %5s %5s %10s\n" "Data Type" "X" "Y" "Z" "X+Y > Z?"
echo "  ─────────────────────────────────────────────────────────────"
printf "  %-25s %5s %5s %5s %10s\n" "Web session (hours)" "10" "3" "0" "${GREEN}No${NC}"
printf "  %-25s %5s %5s %5s %10s\n" "Credit card (PCI: 7yr)" "10" "3" "7" "${GREEN}No${NC}"
printf "  %-25s %5s %5s %5s %10s\n" "Medical records (50yr)" "10" "5" "50" "${RED}YES!${NC}"
printf "  %-25s %5s %5s %5s %10s\n" "Government TOP SECRET" "10" "7" "75" "${RED}YES!${NC}"
printf "  %-25s %5s %5s %5s %10s\n" "Trade secrets (20yr)" "10" "5" "20" "${RED}YES!${NC}"
echo ""

echo -e "${YELLOW}Key insight:${NC} If your data needs to stay secret for 15+ years,"
echo "             you're already late to the PQC party."
echo ""

pause_for_explanation "Press Enter to see the solution..."

# =============================================================================
# Step 4: The Solution - ML-KEM
# =============================================================================

print_step "Step 4: The Solution - ML-KEM (FIPS 203)"

echo -e "${CYAN}ML-KEM: Module Lattice Key Encapsulation Mechanism${NC}"
echo ""
echo "  • NIST FIPS 203 Standard (August 2024)"
echo "  • Based on Module Learning With Errors (MLWE)"
echo "  • Quantum computers cannot efficiently solve lattice problems"
echo ""

echo -e "${BOLD}How ML-KEM works:${NC}"
echo ""
echo "  Alice                              Bob"
echo "    │                                  │"
echo "    │── Public Key (ML-KEM) ─────────►│"
echo "    │                                  │"
echo "    │     Bob: (ciphertext, secret)    │"
echo "    │          = Encaps(Alice_PK)      │"
echo "    │                                  │"
echo "    │◄─── Ciphertext ─────────────────│"
echo "    │                                  │"
echo "    │  Alice: secret                   │"
echo "    │         = Decaps(ciphertext)     │"
echo "    │                                  │"
echo "    │  Both have same shared secret!   │"
echo ""

echo -e "${BOLD}Size comparison with ECDH P-256:${NC}"
echo ""

print_comparison_header
echo -e "${BOLD}Key Encapsulation${NC}"
print_comparison_row "  Public key" "65" "1184" " B"
print_comparison_row "  Ciphertext" "65" "1088" " B"
print_comparison_row "  Shared secret" "32" "32" " B"
echo ""

echo -e "${GREEN}Good news:${NC} The shared secret is the same size!"
echo "           Only the key exchange messages are larger."
echo ""

pause_for_explanation "Press Enter for the key message..."

# =============================================================================
# Key Message
# =============================================================================

print_key_message "Encrypted data captured today can be decrypted tomorrow."

echo -e "${BOLD}Who needs to act NOW:${NC}"
echo ""
echo "  ${RED}■${NC} Healthcare (HIPAA: 50+ year records)"
echo "  ${RED}■${NC} Government (classified information)"
echo "  ${RED}■${NC} Financial services (long-term contracts)"
echo "  ${RED}■${NC} Legal (attorney-client privilege)"
echo "  ${RED}■${NC} Defense/Aerospace (decades of secrecy)"
echo "  ${RED}■${NC} Any data with > 15 year sensitivity"
echo ""

echo -e "${BOLD}What to do:${NC}"
echo "  1. ${CYAN}Inventory${NC} your sensitive data and its lifetime"
echo "  2. ${CYAN}Assess${NC} using Mosca's inequality"
echo "  3. ${CYAN}Plan${NC} hybrid deployment (classical + PQC)"
echo "  4. ${CYAN}Deploy${NC} ML-KEM for key exchange"
echo "  5. ${CYAN}Verify${NC} with quantum-safe certificates (UC-01, UC-02)"
echo ""

# =============================================================================
# Lesson Learned
# =============================================================================

show_lesson "SNDL is not a future problem — it's happening now.
Adversaries are storing your encrypted traffic today.
Calculate your urgency with Mosca's formula.
If X + Y > Z, you need PQC encryption immediately."

show_footer
