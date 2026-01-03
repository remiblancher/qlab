#!/bin/bash
# =============================================================================
#  UC-09: CMS Encryption - For Your Eyes Only
#
#  Post-quantum document encryption with ML-KEM
#  + CSR Attestation workflow (RFC 9883)
#
#  Key Message: You cannot prove possession of a KEM key by signing!
#               Use a signing certificate to attest for encryption keys.
#
#  This demo shows:
#    1. Why KEM keys need special treatment (can't sign CSR)
#    2. CSR attestation workflow with signing certificate
#    3. CMS EnvelopedData structure for document encryption
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

setup_demo "PQC CMS Encryption + CSR Attestation"

# =============================================================================
# Step 1: The KEM Key Problem
# =============================================================================

print_step "Step 1: The KEM Key Problem (RFC 9883)"

echo "  Traditional CSR workflow:"
echo "    1. Generate key pair"
echo "    2. Create CSR and SIGN it with the private key"
echo "    3. CA verifies signature = proof of possession"
echo ""
echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  THE PROBLEM WITH KEM KEYS                                      │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │                                                                 │"
echo "  │  ML-KEM keys can only:                                          │"
echo "  │    ✓ Encapsulate (encrypt a shared secret)                      │"
echo "  │    ✓ Decapsulate (decrypt a shared secret)                      │"
echo "  │                                                                 │"
echo "  │  ML-KEM keys CANNOT:                                            │"
echo "  │    ✗ Sign data                                                  │"
echo "  │    ✗ Create digital signatures                                  │"
echo "  │    ✗ Prove possession via CSR signature!                        │"
echo "  │                                                                 │"
echo "  │  Solution: Use a SIGNING certificate to attest for the KEM key  │"
echo "  │                                                                 │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

pause

# =============================================================================
# Step 2: Create Encryption CA
# =============================================================================

print_step "Step 2: Create Encryption CA"

echo "  The CA signs both signing and encryption certificates."
echo "  We use ML-DSA-65 for the CA (quantum-safe signatures)."
echo ""

run_cmd "qpki ca init --name \"Encryption CA\" --profile profiles/pqc-ca.yaml --dir output/encryption-ca"

echo ""

pause

# =============================================================================
# Step 3: Issue Signing Certificate (ML-DSA-65)
# =============================================================================

print_step "Step 3: Issue Signing Certificate for Alice (ML-DSA-65)"

echo "  First, Alice gets a SIGNING certificate."
echo "  This certificate will be used to attest for her encryption key."
echo ""
echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  SIGNING CERTIFICATE (ML-DSA-65)                                │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │                                                                 │"
echo "  │  Key Usage:                                                     │"
echo "  │    ✓ digitalSignature (sign messages, CSRs)                     │"
echo "  │    ✓ nonRepudiation (legal binding)                             │"
echo "  │                                                                 │"
echo "  │  Can be used to:                                                │"
echo "  │    • Sign CMS SignedData                                        │"
echo "  │    • Attest CSR for encryption certificates                     │"
echo "  │    • Authenticate identity in S/MIME                            │"
echo "  │                                                                 │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

run_cmd "qpki csr gen --algorithm ml-dsa-65 --keyout output/alice-sign.key --cn \"Alice\" -o output/alice-sign.csr"

echo ""

run_cmd "qpki cert issue --ca-dir output/encryption-ca --profile profiles/pqc-signing.yaml --csr output/alice-sign.csr --out output/alice-sign.crt"

echo ""

# Show certificate info
if [[ -f "output/alice-sign.crt" ]]; then
    cert_size=$(wc -c < "output/alice-sign.crt" | tr -d ' ')
    echo -e "  ${CYAN}Certificate size:${NC} $cert_size bytes"
    echo -e "  ${CYAN}Algorithm:${NC} ML-DSA-65 (FIPS 204)"
    echo -e "  ${CYAN}Key Usage:${NC} digitalSignature, nonRepudiation"
fi

echo ""

pause

# =============================================================================
# Step 4: Create CSR for Encryption Key (ML-KEM-768)
# =============================================================================

print_step "Step 4: Create CSR for Encryption Key (RFC 9883 Attestation)"

echo "  Now Alice creates a CSR for her ENCRYPTION key."
echo "  The CSR is signed by her SIGNING key (attestation)."
echo ""
echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  CSR ATTESTATION WORKFLOW (RFC 9883)                            │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │                                                                 │"
echo "  │    ┌──────────────┐                                             │"
echo "  │    │  Alice's     │                                             │"
echo "  │    │  ML-KEM key  │  ◄── Cannot sign!                           │"
echo "  │    └──────────────┘                                             │"
echo "  │           │                                                     │"
echo "  │           ▼                                                     │"
echo "  │    ┌──────────────┐    ┌──────────────┐                         │"
echo "  │    │     CSR      │◄───│  Alice's     │                         │"
echo "  │    │  (ML-KEM     │    │  ML-DSA key  │  ◄── Signs the CSR      │"
echo "  │    │   public key)│    └──────────────┘                         │"
echo "  │    └──────────────┘                                             │"
echo "  │           │                                                     │"
echo "  │           ▼                                                     │"
echo "  │    CA verifies:                                                 │"
echo "  │      1. CSR signature is valid                                  │"
echo "  │      2. Signing cert is trusted                                 │"
echo "  │      3. Issues encryption cert with RelatedCertificate          │"
echo "  │                                                                 │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

run_cmd "qpki csr gen --algorithm ml-kem-768 --keyout output/alice-enc.key --cn \"Alice\" --attest-cert output/alice-sign.crt --attest-key output/alice-sign.key -o output/alice-enc.csr"

echo ""

# Show CSR info
if [[ -f "output/alice-enc.csr" ]]; then
    csr_size=$(wc -c < "output/alice-enc.csr" | tr -d ' ')
    echo -e "  ${CYAN}CSR size:${NC} $csr_size bytes"
    echo -e "  ${CYAN}Key in CSR:${NC} ML-KEM-768 public key"
    echo -e "  ${CYAN}Signed by:${NC} Alice's ML-DSA-65 key (attestation)"
fi

echo ""

pause

# =============================================================================
# Step 5: CA Issues Encryption Certificate
# =============================================================================

print_step "Step 5: CA Issues Encryption Certificate"

echo "  The CA verifies the CSR attestation and issues the encryption cert."
echo "  The certificate includes RelatedCertificate extension pointing"
echo "  to Alice's signing certificate."
echo ""
echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  ENCRYPTION CERTIFICATE (ML-KEM-768)                            │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │                                                                 │"
echo "  │  Key Usage:                                                     │"
echo "  │    ✓ keyEncipherment (receive encrypted keys)                   │"
echo "  │                                                                 │"
echo "  │  Can be used to:                                                │"
echo "  │    • Receive encrypted documents (CMS EnvelopedData)            │"
echo "  │    • Key encapsulation in S/MIME                                │"
echo "  │                                                                 │"
echo "  │  RelatedCertificate extension:                                  │"
echo "  │    → Points to Alice's signing certificate                      │"
echo "  │    → Proves same entity controls both keys                      │"
echo "  │                                                                 │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

run_cmd "qpki cert issue --ca-dir output/encryption-ca --csr output/alice-enc.csr --profile profiles/pqc-encryption.yaml --attest-cert output/alice-sign.crt --out output/alice-enc.crt"

echo ""

# Show certificate info
if [[ -f "output/alice-enc.crt" ]]; then
    cert_size=$(wc -c < "output/alice-enc.crt" | tr -d ' ')
    echo -e "  ${CYAN}Certificate size:${NC} $cert_size bytes"
    echo -e "  ${CYAN}Algorithm:${NC} ML-KEM-768 (FIPS 203)"
    echo -e "  ${CYAN}Key Usage:${NC} keyEncipherment"
fi

echo ""

pause

# =============================================================================
# Step 6: Alice's Certificate Pair
# =============================================================================

print_step "Step 6: Alice's Certificate Pair"

echo "  Alice now has TWO linked certificates:"
echo ""
echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  ALICE'S CERTIFICATE PAIR                                       │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │                                                                 │"
echo "  │  ┌─────────────────────────┐   ┌─────────────────────────────┐ │"
echo "  │  │  SIGNING CERTIFICATE    │   │  ENCRYPTION CERTIFICATE     │ │"
echo "  │  ├─────────────────────────┤   ├─────────────────────────────┤ │"
echo "  │  │  Algorithm: ML-DSA-65   │   │  Algorithm: ML-KEM-768      │ │"
echo "  │  │  Key Usage: sign        │   │  Key Usage: keyEncipherment │ │"
echo "  │  │  File: alice-sign.crt   │   │  File: alice-enc.crt        │ │"
echo "  │  └─────────────────────────┘   └─────────────────────────────┘ │"
echo "  │            │                              ▲                     │"
echo "  │            │       RelatedCertificate     │                     │"
echo "  │            └──────────────────────────────┘                     │"
echo "  │                                                                 │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

if [[ -f "output/alice-sign.crt" && -f "output/alice-enc.crt" ]]; then
    sign_size=$(wc -c < "output/alice-sign.crt" | tr -d ' ')
    enc_size=$(wc -c < "output/alice-enc.crt" | tr -d ' ')
    echo -e "  ${CYAN}Signing cert:${NC}    $sign_size bytes (ML-DSA-65)"
    echo -e "  ${CYAN}Encryption cert:${NC} $enc_size bytes (ML-KEM-768)"
fi

echo ""

pause

# =============================================================================
# Step 7: CMS Encryption Flow
# =============================================================================

print_step "Step 7: How CMS Encryption Works"

echo "  Now that Alice has her certificates, she can receive encrypted documents."
echo ""

cat > output/secret-document.txt << 'EOF'
=== CONFIDENTIAL DOCUMENT ===
Project: Quantum Migration
Date: 2025-01-15
Budget: 50M EUR

Key milestones:
1. Inventory: Q1 2025
2. Pilot: Q2 2025
3. Production: Q4 2025

Classification: TOP SECRET
=============================
EOF

echo "  Document to encrypt:"
echo ""
cat output/secret-document.txt | sed 's/^/    /'
echo ""

orig_size=$(wc -c < "output/secret-document.txt" | tr -d ' ')
echo -e "  ${CYAN}Original size:${NC} $orig_size bytes"
echo ""

echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  CMS ENVELOPE (EnvelopedData per RFC 5652)                      │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │                                                                 │"
echo "  │  ┌─────────────────────────────────────────────────────────┐   │"
echo "  │  │  KEMRecipientInfo (for ML-KEM recipients)               │   │"
echo "  │  │  → Recipient identity (issuer + serial)                 │   │"
echo "  │  │  → KEM ciphertext (~1,088 bytes for ML-KEM-768)         │   │"
echo "  │  │  → Wrapped session key (AES Key Wrap)                   │   │"
echo "  │  └─────────────────────────────────────────────────────────┘   │"
echo "  │                                                                 │"
echo "  │  ┌─────────────────────────────────────────────────────────┐   │"
echo "  │  │  EncryptedContent                                       │   │"
echo "  │  │  → Document encrypted with AES-256-GCM                  │   │"
echo "  │  │  → Fast symmetric encryption (AEAD)                     │   │"
echo "  │  └─────────────────────────────────────────────────────────┘   │"
echo "  │                                                                 │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  ENCRYPTION COMMAND (coming soon)                               │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │                                                                 │"
echo -e "  │  ${DIM}pki cms encrypt \\\\${NC}                                           │"
echo -e "  │  ${DIM}  --recipient output/alice-enc.crt \\\\${NC}                        │"
echo -e "  │  ${DIM}  --in output/secret-document.txt \\\\${NC}                         │"
echo -e "  │  ${DIM}  --out output/secret-document.p7m${NC}                           │"
echo "  │                                                                 │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

pause

# =============================================================================
# Why Hybrid Encryption?
# =============================================================================

print_step "Step 8: Why Hybrid Encryption?"

echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  WHY AES + ML-KEM?                                              │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │                                                                 │"
echo "  │  ML-KEM alone:                                                  │"
echo "  │    ✗ Slow for large files (public-key operations)              │"
echo "  │    ✗ Large ciphertexts (~1 KB overhead per recipient)          │"
echo "  │    ✗ Not designed for bulk encryption                          │"
echo "  │                                                                 │"
echo "  │  AES alone:                                                     │"
echo "  │    ✓ Fast (hardware acceleration: AES-NI)                       │"
echo "  │    ✓ Small overhead (16 bytes + nonce)                          │"
echo "  │    ✗ Symmetric: how to share the key securely?                 │"
echo "  │                                                                 │"
echo "  │  Hybrid (AES + ML-KEM):                                         │"
echo "  │    ✓ AES for content (fast, efficient, authenticated)          │"
echo "  │    ✓ ML-KEM for key transport (quantum-safe)                   │"
echo "  │    ✓ Industry standard (CMS EnvelopedData)                     │"
echo "  │    ✓ Best of both worlds!                                       │"
echo "  │                                                                 │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

# =============================================================================
# Conclusion
# =============================================================================

print_key_message "You cannot prove possession of a KEM key by signing. Use CSR attestation (RFC 9883)."

show_lesson "ML-KEM keys can only encapsulate/decapsulate, not sign.
To get an encryption certificate, attest with a signing certificate.
The CA links certificates via RelatedCertificate extension.
CMS EnvelopedData uses hybrid encryption (AES + ML-KEM).
This is how S/MIME handles separate signing and encryption keys."

show_footer
