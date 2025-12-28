#!/bin/bash
# =============================================================================
#  UC-12: PQC Tunnel - Secure the Tunnel
#
#  Post-quantum key exchange with ML-KEM
#  Key encapsulation for establishing shared secrets
#
#  Key Message: ML-KEM provides quantum-resistant key exchange.
#               Combined with ML-DSA, you get full PQC tunnel protection.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

setup_demo "PQC Tunnel: ML-KEM Key Exchange"

# =============================================================================
# Step 1: ML-DSA vs ML-KEM
# =============================================================================

print_step "Step 1: ML-DSA vs ML-KEM - Two Different Purposes"

echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  ML-DSA vs ML-KEM                                              │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │                                                                 │"
echo "  │  ML-DSA (FIPS 204)                                             │"
echo "  │  ─────────────────                                             │"
echo "  │  Purpose : Digital Signatures                                  │"
echo "  │  Goal    : AUTHENTICITY (who signed this?)                     │"
echo "  │  Ops     : Sign / Verify                                       │"
echo "  │  Example : Sign certificates, code, documents                  │"
echo "  │                                                                 │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │                                                                 │"
echo "  │  ML-KEM (FIPS 203)                                             │"
echo "  │  ─────────────────                                             │"
echo "  │  Purpose : Key Encapsulation                                   │"
echo "  │  Goal    : CONFIDENTIALITY (establish shared secret)           │"
echo "  │  Ops     : Encapsulate / Decapsulate                           │"
echo "  │  Example : TLS handshake, VPN tunnel, hybrid encryption        │"
echo "  │                                                                 │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""
echo "  For a secure tunnel, you need BOTH:"
echo "    - ML-DSA for authentication (who am I talking to?)"
echo "    - ML-KEM for confidentiality (session key)"
echo ""

pause

# =============================================================================
# Step 2: KEM Workflow
# =============================================================================

print_step "Step 2: Key Encapsulation Workflow"

echo "  How ML-KEM works:"
echo ""
echo "  ┌─────────────┐                         ┌─────────────┐"
echo "  │   ALICE     │                         │    BOB      │"
echo "  │  (client)   │                         │  (server)   │"
echo "  └──────┬──────┘                         └──────┬──────┘"
echo "         │                                       │"
echo "         │  1. Bob generates ML-KEM key pair     │"
echo "         │     pk_bob, sk_bob                    │"
echo "         │                                       │"
echo "         │◄─────── 2. Bob sends pk_bob ──────────│"
echo "         │         (in certificate)              │"
echo "         │                                       │"
echo "         │  3. Alice encapsulates:               │"
echo "         │     (ciphertext, shared_key)          │"
echo "         │     = Encaps(pk_bob)                  │"
echo "         │                                       │"
echo "         │──────── 4. Alice sends ciphertext ───►│"
echo "         │                                       │"
echo "         │  5. Bob decapsulates:                 │"
echo "         │     shared_key = Decaps(sk_bob, ct)   │"
echo "         │                                       │"
echo "         │  ═══ SAME shared_key ═══              │"
echo "         │                                       │"
echo "  └──────┴───────────────────────────────────────┘"
echo ""
echo "  → Alice and Bob now have an identical shared secret"
echo "  → This secret is used to encrypt the rest of the communication"
echo ""

pause

# =============================================================================
# Step 3: Create KEM CA
# =============================================================================

print_step "Step 3: Create KEM Demo CA"

echo "  Creating a CA for tunnel endpoint certificates..."
echo "  CA uses ML-DSA-65 to sign endpoint certificates."
echo ""

run_cmd "pki ca init --name \"KEM Demo CA\" --profile profiles/pqc-ca.yaml --dir output/kem-ca"

echo ""

pause

# =============================================================================
# Step 4: Create Tunnel Endpoint Certificate
# =============================================================================

print_step "Step 4: Create Tunnel Endpoint Certificate"

echo "  The tunnel endpoint certificate includes:"
echo "    - ML-DSA-65 key for authentication (digitalSignature)"
echo "    - ML-KEM-768 key for key exchange (keyEncipherment)"
echo ""

run_cmd "pki cert issue --ca-dir output/kem-ca --profile profiles/pqc-tunnel-endpoint.yaml --cn \"tunnel.example.com\" --dns tunnel.example.com --out output/tunnel.crt --key-out output/tunnel.key"

echo ""

if [[ -f "output/tunnel.crt" ]]; then
    cert_size=$(wc -c < "output/tunnel.crt" | tr -d ' ')
    echo -e "  ${CYAN}Certificate size:${NC} $cert_size bytes"
    echo -e "  ${DIM}(Contains both ML-DSA and ML-KEM public keys)${NC}"
fi

echo ""

pause

# =============================================================================
# Step 5: Hybrid KEM for Transition
# =============================================================================

print_step "Step 5: Hybrid KEM for Transition"

echo "  For the transition period, we combine classical and PQC:"
echo ""
echo "  ┌─────────────────────────────────────────────────────────────────┐"
echo "  │  HYBRID KEM = X25519 + ML-KEM-768                              │"
echo "  ├─────────────────────────────────────────────────────────────────┤"
echo "  │                                                                 │"
echo "  │  1. X25519 exchange (classical ECDH)                           │"
echo "  │     └── secret_1 = ECDH(x25519_alice, x25519_bob)              │"
echo "  │                                                                 │"
echo "  │  2. ML-KEM-768 encapsulation (post-quantum)                    │"
echo "  │     └── secret_2, ciphertext = Encaps(mlkem_bob_pk)            │"
echo "  │                                                                 │"
echo "  │  3. Combined derivation                                         │"
echo "  │     └── final_secret = KDF(secret_1 || secret_2)               │"
echo "  │                                                                 │"
echo "  │  Security:                                                      │"
echo "  │  - If X25519 is broken → ML-KEM protects                       │"
echo "  │  - If ML-KEM is broken → X25519 protects                       │"
echo "  │  - Both must be broken simultaneously to compromise             │"
echo "  │                                                                 │"
echo "  └─────────────────────────────────────────────────────────────────┘"
echo ""

echo "  Already supported by:"
echo "    - Chrome/Firefox (TLS 1.3 with hybrid KEM)"
echo "    - OpenSSH 9.0+ (sntrup761x25519-sha512)"
echo "    - Signal Protocol"
echo "    - Cloudflare, AWS, Google"
echo ""

pause

# =============================================================================
# Step 6: Size Comparison
# =============================================================================

print_step "Step 6: Size Comparison"

echo "  ML-KEM Key Sizes:"
echo ""
echo "  ┌──────────────────────────────────────────────────────────────────┐"
echo "  │  Level       │  Public Key  │  Private Key  │  Ciphertext       │"
echo "  ├──────────────────────────────────────────────────────────────────┤"
echo "  │  ML-KEM-512  │  800 bytes   │  1,632 bytes  │  768 bytes        │"
echo "  │  ML-KEM-768  │  1,184 bytes │  2,400 bytes  │  1,088 bytes      │"
echo "  │  ML-KEM-1024 │  1,568 bytes │  3,168 bytes  │  1,568 bytes      │"
echo "  ├──────────────────────────────────────────────────────────────────┤"
echo "  │  X25519      │  32 bytes    │  32 bytes     │  32 bytes         │"
echo "  └──────────────────────────────────────────────────────────────────┘"
echo ""
echo "  Size increase is significant but acceptable:"
echo "    - TLS handshake adds ~2 KB (one-time per connection)"
echo "    - Session key is still 32 bytes (AES-256)"
echo "    - After handshake, performance is identical"
echo ""

# =============================================================================
# Conclusion
# =============================================================================

print_key_message "ML-KEM provides quantum-resistant key exchange. Combined with ML-DSA, you get full PQC tunnel protection."

show_lesson "ML-KEM protects CONFIDENTIALITY (key exchange).
ML-DSA protects AUTHENTICITY (signatures).
For a secure tunnel, you need BOTH algorithms.
Hybrid KEM (X25519 + ML-KEM) provides defense in depth.
Already deployed in major browsers and protocols."

show_footer
