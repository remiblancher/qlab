#!/bin/bash
# =============================================================================
#  UC-09: CMS Encryption - For Your Eyes Only
#
#  Post-quantum document encryption with ML-KEM
#  Encrypt confidential documents using CMS EnvelopedData
#
#  Key Message: Hybrid encryption (AES + ML-KEM) protects documents
#               from both current and future quantum threats.
#
#  Note: This is a conceptual demo. The pki cms encrypt/decrypt commands
#        are being finalized. This demo explains the architecture and shows
#        what the workflow will look like.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

setup_demo "PQC CMS Encryption"

# =============================================================================
# Step 1: Understand CMS Envelope Structure
# =============================================================================

print_step "Step 1: Understand CMS Envelope Structure"

echo "  CMS EnvelopedData is the standard for encrypting documents."
echo "  Used by S/MIME (secure email), document encryption, and more."
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
echo "  How it works:"
echo "    1. Generate random AES-256 session key (CEK)"
echo "    2. Encrypt document with AES-256-GCM (fast, authenticated)"
echo "    3. Encapsulate CEK with ML-KEM (quantum-safe key transport)"
echo "    4. Wrap encapsulated key with HKDF + AES Key Wrap"
echo "    5. Package as CMS EnvelopedData (.p7m)"
echo ""

pause

# =============================================================================
# Step 2: Create Encryption CA
# =============================================================================

print_step "Step 2: Create Encryption CA"

echo "  The CA signs encryption certificates."
echo "  We use ML-DSA-65 for the CA (quantum-safe signatures)."
echo ""

run_cmd "pki init-ca --name \"Encryption CA\" --algorithm ml-dsa-65 --dir output/encryption-ca"

echo ""

pause

# =============================================================================
# Step 3: Issue Signing Certificate
# =============================================================================

print_step "Step 3: Issue Certificate for Alice"

echo "  Alice needs a certificate to authenticate encrypted documents."
echo ""
echo "  In production, encryption profiles issue TWO linked certificates:"
echo "    - Signing: ML-DSA-65 (for authentication, non-repudiation)"
echo "    - Encryption: ML-KEM-768 (for key encapsulation)"
echo ""
echo "  The certificates are linked via RelatedCertificate extension."
echo ""

run_cmd "pki issue --ca-dir output/encryption-ca --profile profiles/encryption.yaml --cn \"Alice\" --out output/alice.crt --key-out output/alice.key"

echo ""

# Show certificate info
if [[ -f "output/alice.crt" ]]; then
    cert_size=$(wc -c < "output/alice.crt" | tr -d ' ')
    echo -e "  ${CYAN}Certificate size:${NC} $cert_size bytes"
    echo -e "  ${DIM}(ML-DSA-65 public key: ~1,952 bytes)${NC}"
fi

echo ""

pause

# =============================================================================
# Step 4: Encryption Flow (Conceptual)
# =============================================================================

print_step "Step 4: How CMS Encryption Works"

echo "  Creating a confidential document..."
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

echo "  Document contents:"
echo ""
cat output/secret-document.txt | sed 's/^/    /'
echo ""

orig_size=$(wc -c < "output/secret-document.txt" | tr -d ' ')
echo -e "  ${CYAN}Original size:${NC} $orig_size bytes"
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

echo "  What happens internally:"
echo ""
echo "    1. Generate random 32-byte AES-256 key (CEK)"
echo "    2. Encrypt document with AES-256-GCM:"
echo "       - 12-byte random nonce"
echo "       - 16-byte authentication tag"
echo "    3. ML-KEM encapsulation with Alice's public key:"
echo "       - Produces ~1,088 byte ciphertext"
echo "       - Produces 32-byte shared secret"
echo "    4. Derive KEK from shared secret using HKDF-SHA256"
echo "    5. Wrap CEK with AES Key Wrap (RFC 3394)"
echo "    6. Package as CMS EnvelopedData"
echo ""

pause

# =============================================================================
# Step 5: Decryption Flow (Conceptual)
# =============================================================================

print_step "Step 5: How CMS Decryption Works"

echo "  Only Alice can decrypt (she has the ML-KEM private key)."
echo ""

echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  DECRYPTION COMMAND (coming soon)                               │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │                                                                 │"
echo -e "  │  ${DIM}pki cms decrypt \\\\${NC}                                           │"
echo -e "  │  ${DIM}  --key output/alice-enc.key \\\\${NC}                              │"
echo -e "  │  ${DIM}  --in output/secret-document.p7m \\\\${NC}                         │"
echo -e "  │  ${DIM}  --out output/secret-decrypted.txt${NC}                          │"
echo "  │                                                                 │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

echo "  Decryption flow:"
echo ""
echo "    1. Parse CMS EnvelopedData structure"
echo "    2. Find KEMRecipientInfo matching Alice's certificate"
echo "    3. ML-KEM decapsulation with Alice's private key:"
echo "       - Input: KEM ciphertext"
echo "       - Output: 32-byte shared secret"
echo "    4. Derive KEK from shared secret using HKDF-SHA256"
echo "    5. Unwrap CEK with AES Key Unwrap"
echo "    6. Decrypt content with AES-256-GCM"
echo "    7. Verify authentication tag (integrity check)"
echo ""

pause

# =============================================================================
# Why Hybrid Encryption?
# =============================================================================

print_step "Step 6: Why Hybrid Encryption?"

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

echo "  Size comparison for a 1 MB document:"
echo ""
echo "  ┌──────────────────────────────────────────────────────────────────┐"
echo "  │  Component           │  RSA-2048  │  ML-KEM-768  │  Notes       │"
echo "  ├──────────────────────┼────────────┼──────────────┼──────────────┤"
echo "  │  Encapsulated key    │  ~256 B    │  ~1,088 B    │  Per recip.  │"
echo "  │  AES-GCM overhead    │  ~28 B     │  ~28 B       │  Same        │"
echo "  │  Total overhead      │  ~284 B    │  ~1,116 B    │  < 0.1%      │"
echo "  └──────────────────────────────────────────────────────────────────┘"
echo ""

# =============================================================================
# Conclusion
# =============================================================================

print_key_message "Hybrid encryption (AES + ML-KEM) protects documents from both current and future quantum threats."

show_lesson "CMS EnvelopedData is the standard for document encryption (RFC 5652).
ML-KEM-768 provides quantum-safe key encapsulation (FIPS 203).
AES-256-GCM encrypts the content with authenticated encryption.
The KEMRecipientInfo structure is defined in draft-ietf-lamps-cms-kemri.
This is the same pattern used by S/MIME for secure email."

show_footer
