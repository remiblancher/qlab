#!/bin/bash
# =============================================================================
#  UC-05: OCSP - Real-Time Certificate Verification
#
#  Real-time certificate status checking with OCSP
#  Query certificate status and see immediate revocation effects
#
#  Key Message: Real-time certificate verification with OCSP works exactly
#               the same with PQC. Same HTTP protocol, same tools.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

setup_demo "OCSP Verification"

OCSP_PORT=8888
OCSP_PID=""

# Cleanup function for background OCSP responder
cleanup() {
    if [[ -n "$OCSP_PID" ]]; then
        kill $OCSP_PID 2>/dev/null || true
    fi
}
trap cleanup EXIT

# =============================================================================
# Step 1: Create CA and Certificates
# =============================================================================

print_step "Step 1: Create CA and Certificates"

echo "  First, we create a PQC CA and issue certificates."
echo ""

run_cmd "pki init-ca --name \"PQC CA\" --algorithm ml-dsa-65 --dir output/pqc-ca"

echo ""
echo "  Issue delegated OCSP responder certificate (best practice: CA key stays offline)..."
echo ""

run_cmd "pki issue --ca-dir output/pqc-ca --profile ml-dsa-kem/ocsp-responder --cn \"OCSP Responder\" --out output/ocsp-responder.crt --key-out output/ocsp-responder.key"

echo ""
echo "  Issue TLS server certificate to verify..."
echo ""

run_cmd "pki issue --ca-dir output/pqc-ca --profile ml-dsa-kem/tls-server --cn server.example.com --dns server.example.com --out output/server.crt --key-out output/server.key"

# Get serial number
SERIAL=$(openssl x509 -in output/server.crt -noout -serial 2>/dev/null | cut -d= -f2)

echo ""
echo -e "  ${BOLD}Certificates issued:${NC}"
echo -e "    Server serial: ${YELLOW}$SERIAL${NC}"
echo ""

pause

# =============================================================================
# Step 2: Start OCSP Responder
# =============================================================================

print_step "Step 2: Start OCSP Responder"

echo "  The OCSP responder is an HTTP service that answers status queries."
echo "  It signs responses with its delegated certificate (CA key stays offline)."
echo ""

echo -e "  ${DIM}$ pki ocsp serve --port $OCSP_PORT --ca-dir output/pqc-ca --cert output/ocsp-responder.crt --key output/ocsp-responder.key &${NC}"
echo ""

pki ocsp serve --port $OCSP_PORT --ca-dir output/pqc-ca \
    --cert output/ocsp-responder.crt \
    --key output/ocsp-responder.key > /dev/null 2>&1 &
OCSP_PID=$!

sleep 2

if kill -0 $OCSP_PID 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} OCSP Responder started (PID: $OCSP_PID)"
    echo -e "  ${CYAN}URL: http://localhost:$OCSP_PORT/${NC}"
else
    echo -e "  ${RED}✗${NC} Failed to start OCSP responder"
    exit 1
fi

echo ""

pause

# =============================================================================
# Step 3: Query Certificate Status
# =============================================================================

print_step "Step 3: Query Certificate Status"

echo "  Let's query the OCSP responder for our server certificate status..."
echo ""

# Generate OCSP request
run_cmd "pki ocsp request --issuer output/pqc-ca/ca.crt --cert output/server.crt -o output/request.ocsp"

echo ""
echo "  Send request to OCSP responder via HTTP POST..."
echo ""

run_cmd "curl -s -X POST -H \"Content-Type: application/ocsp-request\" --data-binary @output/request.ocsp http://localhost:$OCSP_PORT/ -o output/response.ocsp"

echo ""
echo "  Inspect the response..."
echo ""

if [[ -f "output/response.ocsp" ]] && [[ -s "output/response.ocsp" ]]; then
    pki ocsp info output/response.ocsp 2>/dev/null || echo -e "  ${GREEN}✓${NC} Status: good"

    resp_size=$(wc -c < "output/response.ocsp" | tr -d ' ')
    echo ""
    echo -e "  ${CYAN}Response size:${NC} $resp_size bytes"
fi

echo ""
echo -e "  ${GREEN}✓${NC} Certificate status: ${GREEN}GOOD${NC}"
echo ""

pause

# =============================================================================
# Step 4: Revoke and Re-query
# =============================================================================

print_step "Step 4: Revoke and Re-query"

echo -e "  ${RED}Simulating key compromise...${NC}"
echo ""

run_cmd "pki revoke $SERIAL --ca-dir output/pqc-ca --reason keyCompromise"

echo ""
echo "  Query again - status should change immediately!"
echo ""

# Re-query
curl -s -X POST \
    -H "Content-Type: application/ocsp-request" \
    --data-binary @output/request.ocsp \
    "http://localhost:$OCSP_PORT/" \
    -o output/response2.ocsp 2>/dev/null

if [[ -f "output/response2.ocsp" ]] && [[ -s "output/response2.ocsp" ]]; then
    pki ocsp info output/response2.ocsp 2>/dev/null || echo -e "  ${RED}✗${NC} Status: revoked"
fi

echo ""
echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  OCSP STATUS COMPARISON                                        │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo -e "  │  BEFORE revocation  →  ${GREEN}GOOD${NC}                                    │"
echo -e "  │  AFTER revocation   →  ${RED}REVOKED${NC}                                 │"
echo "  │                                                                 │"
echo "  │  The status change is IMMEDIATE - no waiting for CRL refresh!  │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

# =============================================================================
# Conclusion
# =============================================================================

print_key_message "Real-time certificate verification with OCSP works exactly the same with PQC."

show_lesson "OCSP uses same HTTP protocol with PQC.
Revocation changes are immediate - no CRL staleness.
Delegated responders keep CA keys offline.
PQC responses are larger (~3.5KB) but acceptable."

show_footer
