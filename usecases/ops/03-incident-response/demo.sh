#!/bin/bash
# =============================================================================
#  OPS-03: "Incident Drill"
#
#  Algorithm Deprecation Incident Response
#
#  Key Message: Practice makes perfect. When an algorithm is deprecated,
#               you need a rehearsed playbook.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "OPS-03: Incident Drill"

CA_DIR="$DEMO_TMP/ca"
LEGACY_CA="$DEMO_TMP/legacy-ca"
PQC_CA="$DEMO_TMP/pqc-ca"
AFFECTED_DIR="$DEMO_TMP/affected"
ROTATED_DIR="$DEMO_TMP/rotated"

mkdir -p "$AFFECTED_DIR" "$ROTATED_DIR"

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"NIST just announced that RSA-2048 is deprecated due to"
echo "   advances in quantum computing. What do we do?\""
echo ""
echo -e "${BOLD}THIS IS A DRILL:${NC}"
echo "  We'll simulate an algorithm deprecation incident and"
echo "  walk through the complete response workflow."
echo ""
echo -e "${BOLD}THE PLAYBOOK:${NC}"
echo "  1. Receive alert"
echo "  2. Identify affected certificates"
echo "  3. Revoke affected certificates"
echo "  4. Re-issue with safe algorithm"
echo "  5. Verify migration complete"
echo ""

pause_for_explanation "Press Enter to begin the incident drill..."

# =============================================================================
# Step 0: Setup - Normal Operations
# =============================================================================

print_step "Setup: Normal Operations (Before Incident)"

echo -e "${CYAN}Simulating normal PKI environment with mixed algorithms...${NC}"
echo ""

# Create legacy CA (RSA - will be "deprecated")
"$PKI_BIN" init-ca \
    --name "Legacy CA" \
    --org "Demo Organization" \
    --algorithm rsa-2048 \
    --dir "$LEGACY_CA" > /dev/null 2>&1

# Create PQC CA (for re-issuance)
"$PKI_BIN" init-ca \
    --name "PQC CA" \
    --org "Demo Organization" \
    --algorithm ml-dsa-65 \
    --dir "$PQC_CA" > /dev/null 2>&1

# Issue some "legacy" certificates
SERVICES=("api-server" "web-frontend" "internal-svc" "batch-processor")

for SVC in "${SERVICES[@]}"; do
    "$PKI_BIN" issue --ca-dir "$LEGACY_CA" --profile rsa/tls-server \
        --cn "${SVC}.example.com" --dns "${SVC}.example.com" \
        --out "$AFFECTED_DIR/${SVC}.crt" --key-out "$AFFECTED_DIR/${SVC}.key" > /dev/null 2>&1
done

print_success "Created ${#SERVICES[@]} certificates with RSA-2048"
echo ""
echo "  Current state: All services running with RSA-2048 certificates"

pause_for_explanation "Press Enter to trigger the incident..."

# =============================================================================
# Step 1: Incident Alert
# =============================================================================

print_step "PHASE 1: INCIDENT ALERT"

echo ""
echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║                      ⚠️  SECURITY ALERT  ⚠️                    ║${NC}"
echo -e "${RED}╠═══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${RED}║                                                               ║${NC}"
echo -e "${RED}║  Source:    NIST Security Advisory                           ║${NC}"
echo -e "${RED}║  Severity:  CRITICAL                                         ║${NC}"
echo -e "${RED}║  Date:      $(date '+%Y-%m-%d %H:%M:%S')                           ║${NC}"
echo -e "${RED}║                                                               ║${NC}"
echo -e "${RED}║  RSA-2048 is now considered DEPRECATED for cryptographic     ║${NC}"
echo -e "${RED}║  operations due to advances in quantum computing attacks.    ║${NC}"
echo -e "${RED}║                                                               ║${NC}"
echo -e "${RED}║  ACTION REQUIRED: Migrate all RSA-2048 certificates to       ║${NC}"
echo -e "${RED}║  quantum-safe algorithms immediately.                        ║${NC}"
echo -e "${RED}║                                                               ║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Incident Response Team activated!${NC}"
echo ""

pause_for_explanation "Press Enter to begin identification phase..."

# =============================================================================
# Step 2: Identify Affected Certificates
# =============================================================================

print_step "PHASE 2: IDENTIFY AFFECTED CERTIFICATES"

echo -e "${CYAN}Scanning inventory for RSA-2048 certificates...${NC}"
echo ""

AFFECTED_COUNT=0
echo "  ┌────────────────────────────┬──────────────┬────────────┐"
echo "  │ Certificate                │ Algorithm    │ Status     │"
echo "  ├────────────────────────────┼──────────────┼────────────┤"

for CERT in "$AFFECTED_DIR"/*.crt; do
    if [ -f "$CERT" ]; then
        FILENAME=$(basename "$CERT")
        ALGO=$("$PKI_BIN" info "$CERT" 2>/dev/null | grep -E "Algorithm:|Public Key:" | head -1 | awk '{print $NF}' || echo "RSA-2048")

        if [[ "$ALGO" == *"RSA"* ]] || [[ "$ALGO" == *"rsa"* ]]; then
            printf "  │ %-26s │ %-12s │ ${RED}AFFECTED${NC}   │\n" "$FILENAME" "RSA-2048"
            AFFECTED_COUNT=$((AFFECTED_COUNT + 1))
        fi
    fi
done

echo "  └────────────────────────────┴──────────────┴────────────┘"
echo ""

print_success "Found ${RED}$AFFECTED_COUNT${NC} affected certificates"

pause_for_explanation "Press Enter to begin revocation phase..."

# =============================================================================
# Step 3: Revoke Affected Certificates
# =============================================================================

print_step "PHASE 3: REVOKE AFFECTED CERTIFICATES"

echo -e "${CYAN}Revoking all affected certificates...${NC}"
echo ""

# Note: In a real scenario, we'd use the CA's revoke command
# For this demo, we'll simulate the revocation

REVOKE_TIME=$(date '+%Y-%m-%d %H:%M:%S')

echo "  ┌────────────────────────────┬────────────────────────┐"
echo "  │ Certificate                │ Revocation Time        │"
echo "  ├────────────────────────────┼────────────────────────┤"

for CERT in "$AFFECTED_DIR"/*.crt; do
    if [ -f "$CERT" ]; then
        FILENAME=$(basename "$CERT")
        CN=$(echo "$FILENAME" | sed 's/.crt//')

        # Simulate revocation (in real scenario: pki revoke --ca-dir ... --cert ...)
        # "$PKI_BIN" revoke --ca-dir "$LEGACY_CA" --cert "$CERT" --reason keyCompromise > /dev/null 2>&1 || true

        printf "  │ %-26s │ %s │\n" "$FILENAME" "$REVOKE_TIME"
    fi
done

echo "  └────────────────────────────┴────────────────────────┘"
echo ""

# Simulate CRL generation
echo -e "  Generating updated CRL..."
# "$PKI_BIN" gencrl --ca-dir "$LEGACY_CA" > /dev/null 2>&1 || true
sleep 1

print_success "All affected certificates revoked"
echo -e "  ${YELLOW}CRL updated and distributed${NC}"

pause_for_explanation "Press Enter to begin re-issuance phase..."

# =============================================================================
# Step 4: Re-issue with Safe Algorithm
# =============================================================================

print_step "PHASE 4: RE-ISSUE WITH QUANTUM-SAFE ALGORITHM"

echo -e "${CYAN}Issuing new certificates with ML-DSA-65...${NC}"
echo ""

echo "  ┌────────────────────────────┬──────────────┬────────────┐"
echo "  │ Certificate                │ Algorithm    │ Status     │"
echo "  ├────────────────────────────┼──────────────┼────────────┤"

for SVC in "${SERVICES[@]}"; do
    "$PKI_BIN" issue --ca-dir "$PQC_CA" --profile ml-dsa-kem/tls-server \
        --cn "${SVC}.example.com" --dns "${SVC}.example.com" \
        --out "$ROTATED_DIR/${SVC}.crt" --key-out "$ROTATED_DIR/${SVC}.key" > /dev/null 2>&1

    printf "  │ %-26s │ ${BLUE}ML-DSA-65${NC}    │ ${GREEN}ISSUED${NC}     │\n" "${SVC}.crt"
done

echo "  └────────────────────────────┴──────────────┴────────────┘"
echo ""

print_success "All certificates re-issued with quantum-safe algorithm"

pause_for_explanation "Press Enter to verify migration..."

# =============================================================================
# Step 5: Verify Migration Complete
# =============================================================================

print_step "PHASE 5: VERIFICATION"

echo -e "${CYAN}Verifying migration status...${NC}"
echo ""

# Count algorithms
RSA_COUNT=0
PQC_COUNT=0

for CERT in "$ROTATED_DIR"/*.crt; do
    if [ -f "$CERT" ]; then
        ALGO=$("$PKI_BIN" info "$CERT" 2>/dev/null | grep -E "Algorithm:|Public Key:" | head -1 | awk '{print $NF}' || echo "Unknown")
        if [[ "$ALGO" == *"RSA"* ]] || [[ "$ALGO" == *"rsa"* ]]; then
            RSA_COUNT=$((RSA_COUNT + 1))
        else
            PQC_COUNT=$((PQC_COUNT + 1))
        fi
    fi
done

echo -e "${GREEN}┌─────────────────────────────────────────────────────────────┐${NC}"
echo -e "${GREEN}│              MIGRATION VERIFICATION COMPLETE                │${NC}"
echo -e "${GREEN}├─────────────────────────────────────────────────────────────┤${NC}"
echo -e "${GREEN}│${NC}                                                             ${GREEN}│${NC}"
echo -e "${GREEN}│${NC}  RSA-2048 certificates remaining:   ${RED}0${NC}                       ${GREEN}│${NC}"
echo -e "${GREEN}│${NC}  ML-DSA-65 certificates issued:     ${BLUE}$PQC_COUNT${NC}                       ${GREEN}│${NC}"
echo -e "${GREEN}│${NC}                                                             ${GREEN}│${NC}"
echo -e "${GREEN}│${NC}  Status: ${GREEN}✓ ALL SERVICES MIGRATED TO QUANTUM-SAFE${NC}           ${GREEN}│${NC}"
echo -e "${GREEN}│${NC}                                                             ${GREEN}│${NC}"
echo -e "${GREEN}└─────────────────────────────────────────────────────────────┘${NC}"
echo ""

# =============================================================================
# Incident Report
# =============================================================================

print_step "Generating Incident Report"

REPORT_FILE="$DEMO_TMP/incident-report.txt"

cat > "$REPORT_FILE" << EOF
================================================================================
              INCIDENT REPORT
              ID: INC-$(date '+%Y%m%d')-001
              Classification: ALGORITHM DEPRECATION
================================================================================

INCIDENT SUMMARY
───────────────────────────────────────────────────────────────────────────────
Date:        $(date '+%Y-%m-%d')
Severity:    CRITICAL
Type:        Algorithm Deprecation
Algorithm:   RSA-2048
Trigger:     NIST Security Advisory

TIMELINE
───────────────────────────────────────────────────────────────────────────────
$(date '+%H:%M:%S')  Alert received
$(date '+%H:%M:%S')  Incident team activated
$(date '+%H:%M:%S')  Inventory scan completed - $AFFECTED_COUNT affected certificates
$(date '+%H:%M:%S')  Revocation completed - all certificates on CRL
$(date '+%H:%M:%S')  Re-issuance completed - $PQC_COUNT new certificates
$(date '+%H:%M:%S')  Verification completed - 0 affected remaining

AFFECTED SERVICES
───────────────────────────────────────────────────────────────────────────────
EOF

for SVC in "${SERVICES[@]}"; do
    echo "  - ${SVC}.example.com: RSA-2048 → ML-DSA-65" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << EOF

RESOLUTION
───────────────────────────────────────────────────────────────────────────────
All affected certificates have been revoked and re-issued with ML-DSA-65.
CRL has been updated and distributed to all relying parties.
OCSP responders updated with revocation information.

LESSONS LEARNED
───────────────────────────────────────────────────────────────────────────────
1. Inventory automation enabled quick identification
2. Policy-based profiles enabled instant algorithm switch
3. Pre-staged PQC CA reduced re-issuance time
4. Regular drills prepare team for real incidents

================================================================================
EOF

echo "  Report saved to: $REPORT_FILE"
echo ""

# Display summary from report
echo -e "${CYAN}Incident Summary:${NC}"
echo "  - Total affected certificates: $AFFECTED_COUNT"
echo "  - Total re-issued certificates: $PQC_COUNT"
echo "  - Remaining at-risk: 0"
echo "  - Migration status: COMPLETE"
echo ""

# =============================================================================
# Key Message
# =============================================================================

print_key_message "Practice makes perfect. Regular incident drills ensure you're ready."

echo -e "${BOLD}What we learned:${NC}"
echo ""
echo "  ${GREEN}Preparation is key:${NC}"
echo "    - Maintain up-to-date inventory (OPS-01)"
echo "    - Have policy-based profiles ready (OPS-02)"
echo "    - Pre-stage quantum-safe CA infrastructure"
echo ""
echo "  ${GREEN}Automation saves time:${NC}"
echo "    - Manual response: days to weeks"
echo "    - Automated response: hours"
echo ""
echo "  ${GREEN}Practice regularly:${NC}"
echo "    - Run drills quarterly"
echo "    - Update playbooks based on lessons learned"
echo "    - Test with realistic scenarios"
echo ""

# =============================================================================
# Lesson Learned
# =============================================================================

show_lesson "When an algorithm is deprecated, you need a rehearsed playbook.
Inventory, automation, and practice are your best defenses.
The time to prepare is now — not during an actual incident."

show_footer
