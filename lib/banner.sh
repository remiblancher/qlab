#!/bin/bash
# =============================================================================
# Banner for Post-Quantum PKI Lab
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

show_banner() {
    local title="${1:-Post-Quantum PKI Lab}"

    echo -e "${BOLD_CYAN}"
    cat << 'EOF'
  ____   ___    ____  _  _____    _        _    ____
 |  _ \ / _ \  |  _ \| |/ /_ _|  | |      / \  | __ )
 | |_) | | | | | |_) | ' / | |   | |     / _ \ |  _ \
 |  __/| |_| | |  __/| . \ | |   | |___ / ___ \| |_) |
 |_|    \__\_\ |_|   |_|\_\___|  |_____/_/   \_\____/
EOF
    echo -e "${NC}"
    echo -e "${BOLD_WHITE}  $title${NC}"
    echo -e "${CYAN}  ─────────────────────────────────────────────────${NC}"
    echo -e "  ${PURPLE}QentriQ${NC} — Quantum-Safe PKI"
    echo -e "  ${BLUE}https://qentriq.com${NC}"
    echo ""
}

show_footer() {
    echo ""
    echo -e "${CYAN}  ─────────────────────────────────────────────────${NC}"
    echo -e "  ${BOLD}Need help with your PQC transition?${NC}"
    echo -e "  Contact ${PURPLE}QentriQ${NC}: ${BLUE}https://qentriq.com${NC}"
    echo ""
}

show_lesson() {
    local lesson="$1"
    echo ""
    echo -e "${BG_GREEN}${BOLD_WHITE} WHAT YOU LEARNED ${NC}"
    echo -e "${GREEN}$lesson${NC}"
    echo ""
}
