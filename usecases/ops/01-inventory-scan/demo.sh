#!/bin/bash
# =============================================================================
#  OPS-01: "Inventory Before You Migrate"
#
#  Cryptographic Asset Discovery and Inventory
#
#  Key Message: Before you can migrate to PQC, you need to know what you have.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "OPS-01: Inventory Before You Migrate"

LEGACY_CA="$DEMO_TMP/legacy-ca"
STANDARD_CA="$DEMO_TMP/standard-ca"
PQC_CA="$DEMO_TMP/pqc-ca"
CERTS_DIR="$DEMO_TMP/certs"

mkdir -p "$CERTS_DIR"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"We want to migrate to post-quantum cryptography."
echo "   But first, we need to understand what we have.\""
echo ""
echo -e "${BOLD}THE CHALLENGE:${NC}"
echo "  Most organizations don't know:"
echo "    - How many certificates they have"
echo "    - What algorithms are in use"
echo "    - Which certificates are at risk"
echo ""
echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Create a mixed PKI environment (legacy + current + PQC)"
echo "  2. Scan all certificates"
echo "  3. Generate an inventory report"
echo "  4. Assess PQC readiness"
echo ""

pause_for_explanation "Press Enter to start the demo..."

# =============================================================================
# Step 1: Create Mixed PKI Environment
# =============================================================================

print_step "Step 1: Create Mixed PKI Environment"

echo -e "${CYAN}Simulating a typical enterprise with mixed algorithms...${NC}"
echo ""

# Legacy CA (RSA - older)
echo -e "  Creating ${YELLOW}Legacy CA${NC} (RSA-2048)..."
"$PKI_BIN" init-ca \
    --name "Legacy Root CA" \
    --org "Demo Organization" \
    --algorithm rsa-2048 \
    --dir "$LEGACY_CA" > /dev/null 2>&1

# Standard CA (ECDSA - current)
echo -e "  Creating ${GREEN}Standard CA${NC} (ECDSA P-384)..."
"$PKI_BIN" init-ca \
    --name "Standard Root CA" \
    --org "Demo Organization" \
    --algorithm ecdsa-p384 \
    --dir "$STANDARD_CA" > /dev/null 2>&1

# PQC CA (ML-DSA - future)
echo -e "  Creating ${BLUE}PQC CA${NC} (ML-DSA-65)..."
"$PKI_BIN" init-ca \
    --name "PQC Root CA" \
    --org "Demo Organization" \
    --algorithm ml-dsa-65 \
    --dir "$PQC_CA" > /dev/null 2>&1

# Issue certificates from each CA
echo ""
echo -e "  Issuing certificates..."

# Legacy certificates
"$PKI_BIN" issue --ca-dir "$LEGACY_CA" --profile rsa/tls-server \
    --cn "old-app.example.com" --dns "old-app.example.com" \
    --out "$CERTS_DIR/legacy-server-1.crt" --key-out "$CERTS_DIR/legacy-server-1.key" > /dev/null 2>&1
"$PKI_BIN" issue --ca-dir "$LEGACY_CA" --profile rsa/tls-server \
    --cn "legacy-api.example.com" --dns "legacy-api.example.com" \
    --out "$CERTS_DIR/legacy-server-2.crt" --key-out "$CERTS_DIR/legacy-server-2.key" > /dev/null 2>&1

# Standard certificates
"$PKI_BIN" issue --ca-dir "$STANDARD_CA" --profile ec/tls-server \
    --cn "api.example.com" --dns "api.example.com" \
    --out "$CERTS_DIR/standard-server-1.crt" --key-out "$CERTS_DIR/standard-server-1.key" > /dev/null 2>&1
"$PKI_BIN" issue --ca-dir "$STANDARD_CA" --profile ec/tls-server \
    --cn "web.example.com" --dns "web.example.com" \
    --out "$CERTS_DIR/standard-server-2.crt" --key-out "$CERTS_DIR/standard-server-2.key" > /dev/null 2>&1

# PQC certificates
"$PKI_BIN" issue --ca-dir "$PQC_CA" --profile ml-dsa-kem/tls-server \
    --cn "pq-api.example.com" --dns "pq-api.example.com" \
    --out "$CERTS_DIR/pqc-server-1.crt" --key-out "$CERTS_DIR/pqc-server-1.key" > /dev/null 2>&1
"$PKI_BIN" issue --ca-dir "$PQC_CA" --profile ml-dsa-kem/tls-server \
    --cn "pq-web.example.com" --dns "pq-web.example.com" \
    --out "$CERTS_DIR/pqc-server-2.crt" --key-out "$CERTS_DIR/pqc-server-2.key" > /dev/null 2>&1

print_success "Created 3 CAs and 6 end-entity certificates"

# =============================================================================
# Step 2: Inventory Scan
# =============================================================================

print_step "Step 2: Run Inventory Scan"

echo -e "${CYAN}Scanning all certificates in the workspace...${NC}"
echo ""

# Arrays to store results
declare -a CERT_FILES
declare -a CERT_SUBJECTS
declare -a CERT_ALGORITHMS
declare -a CERT_CATEGORIES

RSA_COUNT=0
ECDSA_COUNT=0
MLDSA_COUNT=0
TOTAL_COUNT=0

# Scan CA certificates
for CA_DIR in "$LEGACY_CA" "$STANDARD_CA" "$PQC_CA"; do
    if [ -f "$CA_DIR/ca.crt" ]; then
        CERT_FILES+=("$CA_DIR/ca.crt")
        SUBJECT=$("$PKI_BIN" info "$CA_DIR/ca.crt" 2>/dev/null | grep "Subject:" | head -1 | sed 's/.*CN=//' | cut -d',' -f1 || echo "Unknown")
        ALGO=$("$PKI_BIN" info "$CA_DIR/ca.crt" 2>/dev/null | grep -E "Algorithm:|Public Key:" | head -1 | awk '{print $NF}' || echo "Unknown")

        CERT_SUBJECTS+=("$SUBJECT")
        CERT_ALGORITHMS+=("$ALGO")
        TOTAL_COUNT=$((TOTAL_COUNT + 1))

        case "$ALGO" in
            *RSA*|*rsa*) RSA_COUNT=$((RSA_COUNT + 1)); CERT_CATEGORIES+=("Legacy") ;;
            *ECDSA*|*ecdsa*|*P-384*|*P-256*) ECDSA_COUNT=$((ECDSA_COUNT + 1)); CERT_CATEGORIES+=("Current") ;;
            *ML-DSA*|*ml-dsa*|*MLDSA*) MLDSA_COUNT=$((MLDSA_COUNT + 1)); CERT_CATEGORIES+=("PQC-Ready") ;;
            *) CERT_CATEGORIES+=("Unknown") ;;
        esac
    fi
done

# Scan end-entity certificates
for CERT in "$CERTS_DIR"/*.crt; do
    if [ -f "$CERT" ]; then
        CERT_FILES+=("$CERT")
        SUBJECT=$("$PKI_BIN" info "$CERT" 2>/dev/null | grep "Subject:" | head -1 | sed 's/.*CN=//' | cut -d',' -f1 || echo "Unknown")
        ALGO=$("$PKI_BIN" info "$CERT" 2>/dev/null | grep -E "Algorithm:|Public Key:" | head -1 | awk '{print $NF}' || echo "Unknown")

        CERT_SUBJECTS+=("$SUBJECT")
        CERT_ALGORITHMS+=("$ALGO")
        TOTAL_COUNT=$((TOTAL_COUNT + 1))

        case "$ALGO" in
            *RSA*|*rsa*) RSA_COUNT=$((RSA_COUNT + 1)); CERT_CATEGORIES+=("Legacy") ;;
            *ECDSA*|*ecdsa*|*P-384*|*P-256*) ECDSA_COUNT=$((ECDSA_COUNT + 1)); CERT_CATEGORIES+=("Current") ;;
            *ML-DSA*|*ml-dsa*|*MLDSA*) MLDSA_COUNT=$((MLDSA_COUNT + 1)); CERT_CATEGORIES+=("PQC-Ready") ;;
            *) CERT_CATEGORIES+=("Unknown") ;;
        esac
    fi
done

echo -e "  Found ${YELLOW}$TOTAL_COUNT${NC} certificates"
echo ""

# Display table
echo "  ┌────────────────────────────┬──────────────┬────────────┐"
echo "  │ Subject                    │ Algorithm    │ Category   │"
echo "  ├────────────────────────────┼──────────────┼────────────┤"

for i in "${!CERT_SUBJECTS[@]}"; do
    SUBJ="${CERT_SUBJECTS[$i]}"
    ALGO="${CERT_ALGORITHMS[$i]}"
    CAT="${CERT_CATEGORIES[$i]}"

    # Truncate for display
    SUBJ=$(echo "$SUBJ" | cut -c1-24)
    ALGO=$(echo "$ALGO" | cut -c1-12)

    case "$CAT" in
        "Legacy") CAT_COLOR="${YELLOW}⚠️  Legacy${NC}" ;;
        "Current") CAT_COLOR="${GREEN}✓  Current${NC}" ;;
        "PQC-Ready") CAT_COLOR="${BLUE}✓  PQC${NC}" ;;
        *) CAT_COLOR="$CAT" ;;
    esac

    printf "  │ %-26s │ %-12s │ %-10s │\n" "$SUBJ" "$ALGO" "$CAT"
done

echo "  └────────────────────────────┴──────────────┴────────────┘"

pause_for_explanation "Press Enter to generate the report..."

# =============================================================================
# Step 3: Generate Report
# =============================================================================

print_step "Step 3: Generate Inventory Report"

# Calculate percentages
if [ $TOTAL_COUNT -gt 0 ]; then
    RSA_PCT=$((RSA_COUNT * 100 / TOTAL_COUNT))
    ECDSA_PCT=$((ECDSA_COUNT * 100 / TOTAL_COUNT))
    MLDSA_PCT=$((MLDSA_COUNT * 100 / TOTAL_COUNT))
    PQC_READINESS=$MLDSA_PCT
else
    RSA_PCT=0
    ECDSA_PCT=0
    MLDSA_PCT=0
    PQC_READINESS=0
fi

REPORT_FILE="$DEMO_TMP/inventory-report.txt"

cat > "$REPORT_FILE" << EOF
================================================================================
              CRYPTOGRAPHIC INVENTORY REPORT
              Generated: $(date '+%Y-%m-%d %H:%M:%S')
================================================================================

SUMMARY
───────────────────────────────────────────────────────────────────────────────
Total Certificates Scanned: $TOTAL_COUNT

BY ALGORITHM TYPE:
  RSA-2048      : $RSA_COUNT ($RSA_PCT%)   ⚠️  Legacy - Plan migration
  ECDSA-P384    : $ECDSA_COUNT ($ECDSA_PCT%)   ✓  Current - Consider hybrid
  ML-DSA-65     : $MLDSA_COUNT ($MLDSA_PCT%)   ✓  PQC-Ready

PQC READINESS SCORE: $PQC_READINESS%

RECOMMENDATIONS
───────────────────────────────────────────────────────────────────────────────
EOF

if [ $RSA_COUNT -gt 0 ]; then
    echo "  [HIGH] Migrate $RSA_COUNT RSA certificates to ECDSA or PQC" >> "$REPORT_FILE"
fi
if [ $ECDSA_COUNT -gt 0 ]; then
    echo "  [MEDIUM] Plan hybrid migration for $ECDSA_COUNT ECDSA certificates" >> "$REPORT_FILE"
fi
if [ $MLDSA_COUNT -gt 0 ]; then
    echo "  [INFO] $MLDSA_COUNT certificates are already quantum-safe" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "================================================================================
" >> "$REPORT_FILE"

# Display report
echo ""
echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│              CRYPTOGRAPHIC INVENTORY REPORT                 │${NC}"
echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${NC}"
echo -e "${CYAN}│${NC}  Total Certificates: ${YELLOW}$TOTAL_COUNT${NC}                                   ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}                                                             ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  By Algorithm:                                              ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}    RSA-2048      : $RSA_COUNT ($RSA_PCT%) ${YELLOW}⚠️  Legacy${NC}                     ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}    ECDSA-P384    : $ECDSA_COUNT ($ECDSA_PCT%) ${GREEN}✓  Current${NC}                    ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}    ML-DSA-65     : $MLDSA_COUNT ($MLDSA_PCT%) ${BLUE}✓  PQC-Ready${NC}                   ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}                                                             ${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  PQC Readiness: ${GREEN}$PQC_READINESS%${NC}                                       ${CYAN}│${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
echo ""

print_success "Report saved to: $REPORT_FILE"

# =============================================================================
# Step 4: Migration Recommendations
# =============================================================================

print_step "Step 4: Migration Recommendations"

echo ""
echo -e "${BOLD}Priority Matrix:${NC}"
echo ""
echo "  ┌─────────────────┬───────────────────────────────────────────┐"
echo "  │ Priority        │ Action                                    │"
echo "  ├─────────────────┼───────────────────────────────────────────┤"

if [ $RSA_COUNT -gt 0 ]; then
    echo -e "  │ ${RED}HIGH${NC}            │ Migrate $RSA_COUNT RSA certificates             │"
    echo "  │                 │ → Replace with ECDSA or hybrid           │"
fi
if [ $ECDSA_COUNT -gt 0 ]; then
    echo -e "  │ ${YELLOW}MEDIUM${NC}          │ Plan hybrid for $ECDSA_COUNT ECDSA certificates    │"
    echo "  │                 │ → Add PQC via Catalyst certificates      │"
fi
if [ $MLDSA_COUNT -gt 0 ]; then
    echo -e "  │ ${GREEN}LOW${NC}             │ $MLDSA_COUNT ML-DSA certificates are ready          │"
    echo "  │                 │ → No action needed                       │"
fi

echo "  └─────────────────┴───────────────────────────────────────────┘"
echo ""

# =============================================================================
# Key Message
# =============================================================================

print_key_message "Discovery is the first step. You can't migrate what you don't know."

echo -e "${BOLD}What we learned:${NC}"
echo "  - How to scan and inventory PKI assets"
echo "  - How to categorize by algorithm type"
echo "  - How to calculate PQC readiness"
echo "  - How to prioritize migration efforts"
echo ""

echo -e "${BOLD}In production:${NC}"
echo "  - Use CBOM tools for enterprise-scale discovery"
echo "  - Integrate with asset management systems"
echo "  - Automate periodic scans"
echo "  - Track progress over time"
echo ""

# =============================================================================
# Lesson Learned
# =============================================================================

show_lesson "Before you can migrate to PQC, you need to know what you have.
Inventory is not optional — it's the foundation of your migration plan.
Start with discovery, then prioritize based on risk."

show_footer
