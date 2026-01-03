# Hybrid PQC: Best of Both Worlds

## Hybrid Certificates: Classical + Post-Quantum

> **Key Message:** You don't choose between classical and PQC. You stack them.

---

## The Scenario

*"I need to stay compatible with legacy clients, while being quantum-ready for modern ones."*

This is the reality of PQC migration. You can't flip a switch and move everything to post-quantum overnight. Hybrid certificates solve this by combining **both** classical and PQC cryptography in a single certificate.

**You cannot upgrade all clients at once — but certificates can.**

```
┌──────────────────┐                    ┌──────────────────┐
│  LEGACY Client   │                    │  MODERN Client   │
│  ──────────────  │                    │  ─────────────   │
│  OpenSSL 1.x     │                    │  OpenSSL 3.x     │
│  Java 8          │                    │  Go 1.23+        │
│  Old browsers    │                    │  Chrome 2024+    │
│                  │                    │                  │
│  Understands:    │                    │  Understands:    │
│  ✓ RSA           │                    │  ✓ RSA           │
│  ✓ ECDSA         │                    │  ✓ ECDSA         │
│  ✗ ML-DSA        │                    │  ✓ ML-DSA        │
└──────────────────┘                    └──────────────────┘
         │                                       │
         │                                       │
         └───────────────┬───────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  HYBRID CERTIFICATE  │
              │  ══════════════════  │
              │  ECDSA P-384         │
              │  + ML-DSA-65         │
              │                      │
              │  Works for BOTH!     │
              └──────────────────────┘
```

---

## What This Demo Shows

| Component | Classical | Hybrid (Catalyst) |
|-----------|-----------|-------------------|
| Public Key | ECDSA P-384 only | ECDSA P-384 + ML-DSA-65 |
| Signature | ECDSA only | ECDSA + ML-DSA |
| Legacy support | Yes | Yes |
| Quantum-safe | No | Yes |

---

## Run the Demo

```bash
./demo.sh
```

---

## The Commands

### Step 1: Create Hybrid Root CA

```bash
# Initialize hybrid CA with both classical and PQC keys
qpki ca init --profile profiles/hybrid-root-ca.yaml \
    --name "Hybrid Root CA" \
    --dir output/hybrid-ca

# Inspect
qpki inspect output/hybrid-ca/ca.crt
```

### Step 2: Issue Hybrid TLS Certificate

```bash
# Issue hybrid certificate for TLS server
qpki cert issue --ca-dir output/hybrid-ca \
    --profile profiles/hybrid-tls-server.yaml \
    --var cn=hybrid.example.com \
    --out output/hybrid-server.crt \
    --keyout output/hybrid-server.key

# Inspect
qpki inspect output/hybrid-server.crt
```

### Step 3: Test Interoperability

```bash
# Legacy client (OpenSSL - classical only)
openssl verify -CAfile output/hybrid-ca/ca.crt output/hybrid-server.crt
# → OK (uses ECDSA, ignores PQC extensions)

# PQC-aware client (qpki tool)
qpki cert verify output/hybrid-server.crt --ca output/hybrid-ca/ca.crt
# → OK (verifies BOTH ECDSA and ML-DSA signatures)
```

> **Tip:** For detailed ASN.1 output, use `openssl x509 -in output/hybrid-server.crt -text -noout`

---

## Hybrid Certificate Structure

A Catalyst certificate (ITU-T X.509 Section 9.8) contains dual keys:

```
┌─────────────────────────────────────────────────────────────────┐
│  HYBRID CERTIFICATE (Catalyst)                                  │
├─────────────────────────────────────────────────────────────────┤
│  Subject: CN=hybrid.example.com                                 │
│  Public Key: ECDSA P-384 (classical)                            │
│  Signature: ECDSA P-384 (classical)                             │
├─────────────────────────────────────────────────────────────────┤
│  Extension: Alternative Public Key                              │
│    Algorithm: ML-DSA-65 (post-quantum)                          │
│    Key: [1952 bytes]                                            │
├─────────────────────────────────────────────────────────────────┤
│  Extension: Alternative Signature                               │
│    Algorithm: ML-DSA-65 (post-quantum)                          │
│    Signature: [3293 bytes]                                      │
└─────────────────────────────────────────────────────────────────┘
```

**Standard**: ITU-T X.509 Section 9.8 (Catalyst)

---

## How It Works

| Client Type | What It Does | Result |
|-------------|--------------|--------|
| Legacy (OpenSSL) | Uses ECDSA, ignores PQC extensions | ✓ OK |
| PQC-Aware (qpki) | Verifies BOTH signatures | ✓ OK |

**This is the power of hybrid: zero breaking changes for legacy clients.**

**Note:** Hybrid provides quantum resistance only for PQC-aware clients. Legacy clients remain protected by classical cryptography only.

---

## Size Comparison

| Metric | Classical (ECDSA) | Hybrid (Catalyst) | Overhead |
|--------|-------------------|-------------------|----------|
| CA Certificate | ~1 KB | ~6 KB | ~5 KB |
| TLS Certificate | ~1 KB | ~6 KB | ~5 KB |
| Private Key | ~300 B | ~2.5 KB | ~2.2 KB |

*The overhead comes from the additional ML-DSA key (~1952 B) and signature (~3293 B).*

*In most TLS deployments, this size increase is negligible compared to application payloads.*

---

## Catalyst vs Composite

Two approaches to implement hybrid certificates:

| Approach | Description | Standard |
|----------|-------------|----------|
| **Catalyst** | Single cert, dual keys in extensions (separate) | ITU-T X.509 9.8 |
| **Composite** | Single cert, fused algorithm (combined OID) | IETF draft |

```
CATALYST                              COMPOSITE
────────                              ─────────
PublicKey: ECDSA (primary)            PublicKey: ECDSA-ML-DSA (composite)
Extension: AltKey (ML-DSA)              └─ both keys fused
Signature: ECDSA (primary)            Signature: composite
Extension: AltSig (ML-DSA)              └─ both sigs fused
```

This demo uses **Catalyst** because:
- Clear separation of classical and PQC
- Better backwards compatibility (legacy ignores extensions)
- Works with existing certificate management

---

## What You Learned

1. **Hybrid:** The capability to combine classical + PQC cryptography
2. **Zero breaking changes:** Legacy clients work unchanged
3. **Defense in depth:** If one algorithm fails, the other protects
4. **Smooth migration:** No "flag day" required
5. **Next step:** What happens when certificates are compromised? See [Revocation](../04-revocation/)

---

## When to Use Hybrid

| Scenario | Recommendation |
|----------|----------------|
| Public-facing web servers | **Hybrid** - you don't control all clients |
| Internal APIs (controlled) | Pure PQC or Hybrid |
| IoT devices (long-lived) | **Hybrid** - future-proof |
| Regulatory environments | **Hybrid** - satisfies both requirements |
| Testing/Development | Pure PQC (to validate full stack) |

---

## References

- [ITU-T X.509 (2019) Section 9.8](https://www.itu.int/rec/T-REC-X.509) — Catalyst certificates
- [IETF draft-ounsworth-pq-composite-keys](https://datatracker.ietf.org/doc/draft-ounsworth-pq-composite-keys/) — Composite approach
- [NIST SP 800-131A Rev 2](https://csrc.nist.gov/publications/detail/sp/800-131a/rev-2/final) — Transition guidance

---

← [Full PQC Chain](../02-full-chain/) | [Next: Revocation →](../04-revocation/)
