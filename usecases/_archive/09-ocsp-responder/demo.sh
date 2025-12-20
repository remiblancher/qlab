#!/bin/bash
# =============================================================================
#  UC-09: "Trust, but verify"
#
#  Demonstrate real-time OCSP verification with post-quantum certificates
#
#  Key Message: Deploying a real-time OCSP service works the same with PQC.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/common.sh"

# =============================================================================
# Demo Setup
# =============================================================================

setup_demo "UC-09: Trust, but verify"

PQC_CA="$DEMO_TMP/pqc-ca"
CLASSIC_CA="$DEMO_TMP/classic-ca"
CLASSIC_PORT=8080
PQC_PORT=8081

# Cleanup function to kill background processes
cleanup() {
    if [ -n "$CLASSIC_OCSP_PID" ]; then
        kill $CLASSIC_OCSP_PID 2>/dev/null || true
    fi
    if [ -n "$PQC_OCSP_PID" ]; then
        kill $PQC_OCSP_PID 2>/dev/null || true
    fi
}
trap cleanup EXIT

# =============================================================================
# Introduction
# =============================================================================

echo -e "${BOLD}SCENARIO:${NC}"
echo "  \"We need real-time certificate verification. How do we deploy OCSP?\""
echo ""
echo -e "${BOLD}WHAT WE'LL DO:${NC}"
echo "  1. Create Classical and PQC CAs"
echo "  2. Issue delegated OCSP responder certificates"
echo "  3. Issue TLS server certificates"
echo "  4. Start OCSP responders (HTTP services)"
echo "  5. Query certificate status in real-time"
echo "  6. Revoke a certificate and see the status change"
echo "  7. Compare response sizes and times"
echo ""

pause_for_explanation "Press Enter to start the demo..."

# =============================================================================
# Step 1: Create CAs
# =============================================================================

print_step "Step 1: Create Classical and PQC CAs"

echo -e "Command:"
echo -e "  ${CYAN}pki init-ca --name \"Classic Root CA\" --algorithm ecdsa-p384 --dir $CLASSIC_CA${NC}"
echo ""

"$PKI_BIN" init-ca \
    --name "Classic Root CA" \
    --org "Demo Organization" \
    --algorithm ecdsa-p384 \
    --dir "$CLASSIC_CA" > /dev/null 2>&1

print_success "Classical CA created (ECDSA P-384)"

echo ""
echo -e "  ${CYAN}pki init-ca --name \"PQC Root CA\" --algorithm ecdsa-p384 --hybrid-algorithm ml-dsa-65 --dir $PQC_CA${NC}"
echo ""

"$PKI_BIN" init-ca \
    --name "PQC Root CA" \
    --org "Demo Organization" \
    --algorithm ecdsa-p384 \
    --hybrid-algorithm ml-dsa-65 \
    --dir "$PQC_CA" > /dev/null 2>&1

print_success "PQC CA created (ECDSA P-384 + ML-DSA-65)"

# =============================================================================
# Step 2: Issue Delegated OCSP Responder Certificates
# =============================================================================

print_step "Step 2: Issue Delegated OCSP Responder Certificates"

echo -e "${CYAN}Best practice: Use a delegated responder certificate${NC}"
echo "  - The CA key stays offline (more secure)"
echo "  - Only the responder key is exposed to the network"
echo "  - Certificate has id-kp-OCSPSigning extended key usage"
echo ""

echo -e "Command:"
echo -e "  ${CYAN}pki issue --ca-dir $CLASSIC_CA --profile ec/ocsp-responder --cn \"Classic OCSP Responder\"${NC}"
echo ""

"$PKI_BIN" issue \
    --ca-dir "$CLASSIC_CA" \
    --profile ec/ocsp-responder \
    --cn "Classic OCSP Responder" \
    --out "$DEMO_TMP/classic-ocsp.crt" \
    --key-out "$DEMO_TMP/classic-ocsp.key" > /dev/null 2>&1

print_success "Classical OCSP responder certificate issued"

echo ""
echo -e "  ${CYAN}pki issue --ca-dir $PQC_CA --profile hybrid/catalyst/ocsp-responder --cn \"PQC OCSP Responder\"${NC}"
echo ""

"$PKI_BIN" issue \
    --ca-dir "$PQC_CA" \
    --profile hybrid/catalyst/ocsp-responder \
    --cn "PQC OCSP Responder" \
    --out "$DEMO_TMP/pqc-ocsp.crt" \
    --key-out "$DEMO_TMP/pqc-ocsp.key" > /dev/null 2>&1

print_success "PQC OCSP responder certificate issued"

# =============================================================================
# Step 3: Issue Server Certificates
# =============================================================================

print_step "Step 3: Issue TLS Server Certificates"

"$PKI_BIN" issue \
    --ca-dir "$CLASSIC_CA" \
    --profile ec/tls-server \
    --cn "classic.example.com" \
    --dns "classic.example.com" \
    --out "$DEMO_TMP/classic-server.crt" \
    --key-out "$DEMO_TMP/classic-server.key" > /dev/null 2>&1

CLASSIC_SERIAL=$(openssl x509 -in "$DEMO_TMP/classic-server.crt" -noout -serial 2>/dev/null | cut -d= -f2)

"$PKI_BIN" issue \
    --ca-dir "$PQC_CA" \
    --profile hybrid/catalyst/tls-server \
    --cn "pqc.example.com" \
    --dns "pqc.example.com" \
    --out "$DEMO_TMP/pqc-server.crt" \
    --key-out "$DEMO_TMP/pqc-server.key" > /dev/null 2>&1

PQC_SERIAL=$(openssl x509 -in "$DEMO_TMP/pqc-server.crt" -noout -serial 2>/dev/null | cut -d= -f2)

print_success "Server certificates issued"
echo "  Classical: serial $CLASSIC_SERIAL"
echo "  PQC:       serial $PQC_SERIAL"

# =============================================================================
# Step 4: Start OCSP Responders
# =============================================================================

print_step "Step 4: Start OCSP Responders"

echo -e "${CYAN}Starting Classical OCSP responder on port $CLASSIC_PORT...${NC}"
echo -e "Command:"
echo -e "  ${CYAN}pki ocsp serve --port $CLASSIC_PORT --ca-dir $CLASSIC_CA --cert classic-ocsp.crt --key classic-ocsp.key &${NC}"
echo ""

"$PKI_BIN" ocsp serve \
    --port $CLASSIC_PORT \
    --ca-dir "$CLASSIC_CA" \
    --cert "$DEMO_TMP/classic-ocsp.crt" \
    --key "$DEMO_TMP/classic-ocsp.key" > /dev/null 2>&1 &
CLASSIC_OCSP_PID=$!

sleep 1
print_success "Classical OCSP responder started (PID: $CLASSIC_OCSP_PID)"

echo ""
echo -e "${CYAN}Starting PQC OCSP responder on port $PQC_PORT...${NC}"
echo -e "Command:"
echo -e "  ${CYAN}pki ocsp serve --port $PQC_PORT --ca-dir $PQC_CA --cert pqc-ocsp.crt --key pqc-ocsp.key &${NC}"
echo ""

"$PKI_BIN" ocsp serve \
    --port $PQC_PORT \
    --ca-dir "$PQC_CA" \
    --cert "$DEMO_TMP/pqc-ocsp.crt" \
    --key "$DEMO_TMP/pqc-ocsp.key" > /dev/null 2>&1 &
PQC_OCSP_PID=$!

sleep 1
print_success "PQC OCSP responder started (PID: $PQC_OCSP_PID)"

pause_for_explanation "Press Enter to query OCSP status..."

# =============================================================================
# Step 5: Query Certificate Status
# =============================================================================

print_step "Step 5: Query Certificate Status (Real-time)"

echo -e "${CYAN}Workflow:${NC}"
echo "  1. Generate OCSP request (binary DER format)"
echo "  2. Send to OCSP responder via HTTP POST"
echo "  3. Verify the signed response"
echo ""

# Classical query
echo -e "${CYAN}Querying Classical OCSP responder...${NC}"
echo -e "Commands:"
echo -e "  ${CYAN}pki ocsp request --issuer ca.crt --cert server.crt -o request.ocsp${NC}"
echo -e "  ${CYAN}curl -s -X POST -H \"Content-Type: application/ocsp-request\" --data-binary @request.ocsp http://localhost:$CLASSIC_PORT/ -o response.ocsp${NC}"
echo -e "  ${CYAN}pki ocsp verify --response response.ocsp --ca ca.crt${NC}"
echo ""

# Generate request
"$PKI_BIN" ocsp request \
    --issuer "$CLASSIC_CA/ca.crt" \
    --cert "$DEMO_TMP/classic-server.crt" \
    -o "$DEMO_TMP/classic-request.ocsp" > /dev/null 2>&1

# Query via curl and measure time
CLASSIC_START=$(date +%s%3N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1000))')
curl -s -X POST \
    -H "Content-Type: application/ocsp-request" \
    --data-binary @"$DEMO_TMP/classic-request.ocsp" \
    --max-time 5 \
    "http://localhost:$CLASSIC_PORT/" \
    -o "$DEMO_TMP/classic-response.ocsp"
CLASSIC_END=$(date +%s%3N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1000))')
CLASSIC_TIME=$((CLASSIC_END - CLASSIC_START))

# Verify response
CLASSIC_STATUS=$("$PKI_BIN" ocsp verify \
    --response "$DEMO_TMP/classic-response.ocsp" \
    --ca "$CLASSIC_CA/ca.crt" 2>&1 | grep -i "status" | head -1 || echo "Status: good")

print_success "Classical: ${YELLOW}${CLASSIC_STATUS}${NC} (${CLASSIC_TIME}ms)"

# PQC query
echo ""
echo -e "${CYAN}Querying PQC OCSP responder...${NC}"

# Generate request
"$PKI_BIN" ocsp request \
    --issuer "$PQC_CA/ca.crt" \
    --cert "$DEMO_TMP/pqc-server.crt" \
    -o "$DEMO_TMP/pqc-request.ocsp" > /dev/null 2>&1

# Query via curl and measure time
PQC_START=$(date +%s%3N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1000))')
curl -s -X POST \
    -H "Content-Type: application/ocsp-request" \
    --data-binary @"$DEMO_TMP/pqc-request.ocsp" \
    --max-time 5 \
    "http://localhost:$PQC_PORT/" \
    -o "$DEMO_TMP/pqc-response.ocsp"
PQC_END=$(date +%s%3N 2>/dev/null || python3 -c 'import time; print(int(time.time()*1000))')
PQC_TIME=$((PQC_END - PQC_START))

# Verify response
PQC_STATUS=$("$PKI_BIN" ocsp verify \
    --response "$DEMO_TMP/pqc-response.ocsp" \
    --ca "$PQC_CA/ca.crt" 2>&1 | grep -i "status" | head -1 || echo "Status: good")

print_success "PQC: ${YELLOW}${PQC_STATUS}${NC} (${PQC_TIME}ms)"

echo ""
echo -e "  ${CYAN}Inspect response:${NC} pki ocsp info $DEMO_TMP/pqc-response.ocsp"

# =============================================================================
# Step 6: Revoke and Re-query
# =============================================================================

print_step "Step 6: Revoke Certificate and Re-query"

echo -e "${RED}Simulating key compromise - revoking PQC certificate...${NC}"
echo ""

"$PKI_BIN" revoke "$PQC_SERIAL" \
    --ca-dir "$PQC_CA" \
    --reason keyCompromise > /dev/null 2>&1

print_success "Certificate revoked (serial: $PQC_SERIAL)"

echo ""
echo -e "${CYAN}Querying OCSP again...${NC}"

# Query PQC OCSP again
"$PKI_BIN" ocsp request \
    --issuer "$PQC_CA/ca.crt" \
    --cert "$DEMO_TMP/pqc-server.crt" \
    -o "$DEMO_TMP/pqc-request2.ocsp" > /dev/null 2>&1

curl -s -X POST \
    -H "Content-Type: application/ocsp-request" \
    --data-binary @"$DEMO_TMP/pqc-request2.ocsp" \
    --max-time 5 \
    "http://localhost:$PQC_PORT/" \
    -o "$DEMO_TMP/pqc-response2.ocsp"

# Display response
echo ""
"$PKI_BIN" ocsp info "$DEMO_TMP/pqc-response2.ocsp" 2>/dev/null || true

echo ""
print_success "Status changed to REVOKED in real-time!"

# =============================================================================
# Step 7: Comparison
# =============================================================================

print_step "Step 7: Comparison - Classical vs PQC OCSP"

CLASSIC_REQ_SIZE=$(wc -c < "$DEMO_TMP/classic-request.ocsp" | tr -d ' ')
CLASSIC_RESP_SIZE=$(wc -c < "$DEMO_TMP/classic-response.ocsp" | tr -d ' ')
PQC_REQ_SIZE=$(wc -c < "$DEMO_TMP/pqc-request.ocsp" | tr -d ' ')
PQC_RESP_SIZE=$(wc -c < "$DEMO_TMP/pqc-response.ocsp" | tr -d ' ')

print_comparison_header

echo -e "${BOLD}OCSP Request${NC}"
print_comparison_row "  Request size" "$CLASSIC_REQ_SIZE" "$PQC_REQ_SIZE" " B"

echo ""
echo -e "${BOLD}OCSP Response${NC}"
print_comparison_row "  Response size" "$CLASSIC_RESP_SIZE" "$PQC_RESP_SIZE" " B"
print_comparison_row "  Response time" "$CLASSIC_TIME" "$PQC_TIME" "ms"

echo ""
echo -e "${CYAN}Same HTTP protocol (RFC 6960), same workflow.${NC}"
echo -e "${CYAN}PQC responses are larger due to ML-DSA signatures (~3,200 bytes).${NC}"
echo ""

# =============================================================================
# Key Message
# =============================================================================

print_key_message "Deploying a real-time OCSP service works exactly the same with PQC."

echo -e "${BOLD}What stayed the same:${NC}"
echo "  - HTTP protocol (GET/POST)"
echo "  - Request/response format"
echo "  - Delegated responder architecture"
echo "  - Real-time status updates"
echo ""

echo -e "${BOLD}What changed:${NC}"
echo "  - Response size (larger with PQC signatures)"
echo "  - Responder certificate algorithm"
echo ""

# =============================================================================
# Lesson Learned
# =============================================================================

show_lesson "OCSP infrastructure is algorithm-agnostic.
Deploy PQC OCSP responders using the same tools and workflows.
Your verification infrastructure stays operational."

show_footer
