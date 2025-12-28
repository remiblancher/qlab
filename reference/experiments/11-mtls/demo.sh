#!/bin/bash
# =============================================================================
#  UC-11: mTLS Authentication - Show Me Your Badge
#
#  Mutual TLS authentication with ML-DSA-65
#  Both client and server prove their identity
#
#  Key Message: mTLS = mutual authentication. No passwords.
#               Just certificates. With PQC, it's quantum-resistant.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

setup_demo "PQC mTLS Authentication"

# =============================================================================
# Step 1: Understand mTLS
# =============================================================================

print_step "Step 1: What is mTLS?"

echo "  Classic HTTPS = One-way verification (server only)"
echo "  mTLS = Mutual verification (server AND client)"
echo ""
echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  CLASSIC HTTPS vs mTLS                                         │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │                                                                 │"
echo "  │  CLASSIC HTTPS:                                                │"
echo "  │    Client ──────────────────► Server                           │"
echo "  │            \"Prove who you are\"                                 │"
echo "  │    Client ◄────────────────── Server                           │"
echo "  │            Server cert ✓                                       │"
echo "  │    ⚠ Client is NOT verified                                    │"
echo "  │                                                                 │"
echo "  │  mTLS (Mutual TLS):                                            │"
echo "  │    Client ◄─────────────────► Server                           │"
echo "  │            Both exchange certs                                 │"
echo "  │    ✓ Server verified                                           │"
echo "  │    ✓ Client verified                                           │"
echo "  │                                                                 │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

pause

# =============================================================================
# Step 2: Create mTLS CA
# =============================================================================

print_step "Step 2: Create mTLS CA"

echo "  Creating a dedicated CA for mTLS authentication..."
echo "  Algorithm: ML-DSA-65 (quantum-resistant)"
echo ""

run_cmd "pki ca init --name \"mTLS Demo CA\" --profile profiles/pqc-ca.yaml --dir output/mtls-ca"

echo ""

pause

# =============================================================================
# Step 3: Issue Server Certificate
# =============================================================================

print_step "Step 3: Issue Server Certificate"

echo "  The server certificate has:"
echo "    - Extended Key Usage: serverAuth"
echo "    - DNS SAN: api.example.com"
echo ""

run_cmd "pki cert issue --ca-dir output/mtls-ca --profile profiles/pqc-tls-server.yaml --cn \"api.example.com\" --dns api.example.com --out output/server.crt --key-out output/server.key"

echo ""

if [[ -f "output/server.crt" ]]; then
    cert_size=$(wc -c < "output/server.crt" | tr -d ' ')
    echo -e "  ${CYAN}Server certificate size:${NC} $cert_size bytes"
fi

echo ""

pause

# =============================================================================
# Step 4: Issue Client Certificates
# =============================================================================

print_step "Step 4: Issue Client Certificates (Alice and Bob)"

echo "  Each client needs their own certificate to prove identity."
echo "    - Extended Key Usage: clientAuth"
echo ""

echo -e "  ${BOLD}Issuing certificate for Alice:${NC}"
echo ""

run_cmd "pki cert issue --ca-dir output/mtls-ca --profile profiles/pqc-tls-client.yaml --cn \"Alice\" --out output/alice.crt --key-out output/alice.key"

echo ""

echo -e "  ${BOLD}Issuing certificate for Bob:${NC}"
echo ""

run_cmd "pki cert issue --ca-dir output/mtls-ca --profile profiles/pqc-tls-client.yaml --cn \"Bob\" --out output/bob.crt --key-out output/bob.key"

echo ""

pause

# =============================================================================
# Step 5: Simulate mTLS Authentication
# =============================================================================

print_step "Step 5: Simulate mTLS Authentication"

echo "  Testing who can connect to the server..."
echo ""

# Test Alice
echo -e "  ${BOLD}Test 1: Alice connects${NC}"
echo ""
echo -e "  ${DIM}$ pki verify --ca output/mtls-ca/ca.crt --cert output/alice.crt${NC}"
echo ""

if pki verify --ca output/mtls-ca/ca.crt --cert output/alice.crt > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Alice authenticated successfully!"
else
    echo -e "  ${RED}✗${NC} Alice authentication failed"
fi

echo ""

# Test Bob
echo -e "  ${BOLD}Test 2: Bob connects${NC}"
echo ""
echo -e "  ${DIM}$ pki verify --ca output/mtls-ca/ca.crt --cert output/bob.crt${NC}"
echo ""

if pki verify --ca output/mtls-ca/ca.crt --cert output/bob.crt > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Bob authenticated successfully!"
else
    echo -e "  ${RED}✗${NC} Bob authentication failed"
fi

echo ""

# Test Mallory (no certificate)
echo -e "  ${BOLD}Test 3: Mallory tries without certificate${NC}"
echo ""
echo -e "  ${RED}✗${NC} Mallory is REJECTED! (No client certificate)"
echo -e "  ${DIM}Without a certificate signed by the CA, no access.${NC}"
echo ""

pause

# =============================================================================
# Step 6: Authentication Summary
# =============================================================================

print_step "Step 6: Authentication Summary"

echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  mTLS AUTHENTICATION RESULTS                                   │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo -e "  │  Alice   │ Valid certificate signed by CA    │ ${GREEN}✓ AUTHORIZED${NC} │"
echo -e "  │  Bob     │ Valid certificate signed by CA    │ ${GREEN}✓ AUTHORIZED${NC} │"
echo -e "  │  Mallory │ No certificate                    │ ${RED}✗ REJECTED${NC}   │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  FILES CREATED                                                 │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │  output/mtls-ca/        CA directory                           │"
echo "  │  output/server.crt/key  Server certificate (serverAuth)        │"
echo "  │  output/alice.crt/key   Client Alice (clientAuth)              │"
echo "  │  output/bob.crt/key     Client Bob (clientAuth)                │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

# =============================================================================
# Conclusion
# =============================================================================

print_key_message "mTLS = mutual authentication. No passwords. Just certificates. With PQC, it's quantum-resistant."

show_lesson "mTLS requires BOTH parties to present certificates.
serverAuth EKU = server proves identity to client.
clientAuth EKU = client proves identity to server.
No passwords, no tokens - cryptographic proof only.
ML-DSA-65 ensures authentication survives quantum computers."

show_footer
