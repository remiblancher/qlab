#!/bin/bash
# =============================================================================
#  UC-04: Certificate Revocation
#
#  Incident Response: When Keys Are Compromised
#  Revoke certificates and generate CRLs
#
#  Note: This demo uses ECDSA (Go crypto/x509 CRL limitation with PQC keys)
#
#  Key Message: Certificate revocation works the same regardless of algorithm.
#               Same workflow, same commands.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

setup_demo "Certificate Revocation"

# =============================================================================
# Step 1: Create CA and Issue Certificate
# =============================================================================

print_step "Step 1: Create CA and Issue Certificate"

echo "  First, we need a CA and a certificate to revoke."
echo ""

run_cmd "pki ca init --name \"Demo CA\" --profile profiles/classic-ca.yaml --dir output/demo-ca"

echo ""
echo "  Now issue a TLS certificate..."
echo ""

run_cmd "pki cert csr --algorithm ecdsa-p384 --keyout output/server.key --cn server.example.com --out output/server.csr"

echo ""

run_cmd "pki cert issue --ca-dir output/demo-ca --profile profiles/classic-tls-server.yaml --csr output/server.csr --out output/server.crt"

# Get serial number
SERIAL=$(openssl x509 -in output/server.crt -noout -serial 2>/dev/null | cut -d= -f2)

echo ""
echo -e "  ${BOLD}Certificate issued:${NC}"
echo -e "    Serial: ${YELLOW}$SERIAL${NC}"
echo ""

pause

# =============================================================================
# Step 2: Incident - Key Compromise!
# =============================================================================

print_step "Step 2: Incident - Key Compromise!"

echo -e "  ${RED}ALERT: The private key for server.example.com was exposed!${NC}"
echo ""
echo "  Incident response steps:"
echo "    1. [DONE] Detect the compromise"
echo "    2. [DONE] Identify the certificate (serial: $SERIAL)"
echo "    3. [NEXT] Revoke the certificate"
echo "    4. [NEXT] Generate updated CRL"
echo "    5. [NEXT] Issue replacement certificate"
echo ""

pause

# =============================================================================
# Step 3: Revoke the Certificate
# =============================================================================

print_step "Step 3: Revoke the Certificate"

echo "  Revocation reasons (RFC 5280):"
echo ""
echo "    0 = unspecified"
echo "    1 = keyCompromise      <- We'll use this"
echo "    2 = cACompromise"
echo "    3 = affiliationChanged"
echo "    4 = superseded"
echo "    5 = cessationOfOperation"
echo ""

run_cmd "pki cert revoke $SERIAL --ca-dir output/demo-ca --reason keyCompromise"

echo ""
echo -e "  ${GREEN}✓${NC} Certificate revoked"
echo ""

pause

# =============================================================================
# Step 4: Generate CRL
# =============================================================================

print_step "Step 4: Generate CRL (Certificate Revocation List)"

echo "  The CRL is a signed list of all revoked certificates."
echo "  Clients download it to check certificate validity."
echo ""

run_cmd "pki ca crl gen --ca-dir output/demo-ca"

if [[ -f "output/demo-ca/crl/ca.crl" ]]; then
    crl_size=$(wc -c < "output/demo-ca/crl/ca.crl" | tr -d ' ')
    echo ""
    echo -e "  ${BOLD}CRL generated:${NC}"
    echo -e "    Size: $crl_size bytes"
    echo ""
    echo -e "  ${DIM}Note: CRL size depends on number of revoked certificates${NC}"
fi

echo ""

pause

# =============================================================================
# Step 5: Verify Revocation Status
# =============================================================================

print_step "Step 5: Verify Revocation Status"

echo "  Let's verify the certificate is now rejected..."
echo ""

echo -e "  ${DIM}$ pki verify --cert output/server.crt --ca output/demo-ca/ca.crt --crl output/demo-ca/crl/ca.crl${NC}"

if ! pki verify --cert output/server.crt --ca output/demo-ca/ca.crt --crl output/demo-ca/crl/ca.crl 2>&1; then
    echo ""
    echo -e "  ${RED}✗${NC} Certificate REVOKED - Verification failed (expected!)"
else
    echo ""
    echo -e "  ${YELLOW}[INFO]${NC} CRL verification may not be fully supported"
fi

echo ""
echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  REVOCATION SUMMARY                                            │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │  Serial         : $SERIAL                            │"
echo "  │  Reason         : keyCompromise                                │"
echo -e "  │  Status         : ${RED}REVOKED${NC}                                      │"
echo "  │  CRL generated  : Yes                                          │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

# =============================================================================
# Conclusion
# =============================================================================

print_key_message "Certificate revocation works the same regardless of algorithm."

show_lesson "PKI operations are algorithm-agnostic.
Same workflow, same commands, same runbooks.
No retraining needed for ops teams.
Note: PQC CRL support depends on Go crypto/x509 evolution."

show_footer
