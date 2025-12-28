# PKI-04: "Hybrid PQC: Best of Both Worlds"

## Hybrid Certificates (Catalyst): Classical + Post-Quantum

> **Key Message:** You don't choose between classical and PQC. You stack them.

> **Visual diagrams:** See [`diagram.txt`](diagram.txt) for ASCII diagrams of hybrid certificate structure, client behavior, and migration timeline.

## The Scenario

*"I need to stay compatible with legacy clients, while being quantum-ready for modern ones."*

This is the reality of PQC migration. You can't flip a switch and move everything to post-quantum overnight. Hybrid certificates solve this by combining **both** classical and PQC cryptography in a single certificate.

## What This Demo Shows

| Component | Classical | Hybrid (Catalyst) |
|-----------|-----------|-------------------|
| Public Key | ECDSA P-384 only | ECDSA P-384 + ML-DSA-65 |
| Signature | ECDSA only | ECDSA + ML-DSA |
| Legacy support | Yes | Yes |
| Quantum-safe | No | Yes |

## Run the Demo

```bash
./demo.sh
```

## The Commands

### Step 1: Create Hybrid CA

```bash
pki ca init --name "Hybrid Root CA" \
    --algorithm ecdsa-p384 \
    --dir ./hybrid-ca

# Inspect
pki inspect ./hybrid-ca/ca.crt
```

### Step 2: Issue Hybrid TLS Certificate

```bash
pki cert issue --ca-dir ./hybrid-ca \
    --profile hybrid/catalyst/tls-server \
    --cn hybrid.example.com \
    --dns hybrid.example.com \
    --out hybrid-server.crt \
    --key-out hybrid-server.key

# Inspect
pki inspect hybrid-server.crt
```

> **Tip:** For detailed ASN.1 output, use `openssl x509 -in hybrid-server.crt -text -noout`

## Hybrid Certificate Structure

A Catalyst certificate (ITU-T X.509 Section 9.8) looks like this:

```
+------------------------------------------+
| X.509 Certificate                        |
|------------------------------------------|
| Subject: CN=hybrid.example.com           |
| Public Key: ECDSA P-384 (classical)      |
| Signature: ECDSA P-384 (classical)       |
|------------------------------------------|
| Extension: Alternative Public Key        |
|   Algorithm: ML-DSA-65 (post-quantum)    |
|   Key: [1952 bytes]                      |
|------------------------------------------|
| Extension: Alternative Signature         |
|   Algorithm: ML-DSA-65 (post-quantum)    |
|   Signature: [3293 bytes]                |
+------------------------------------------+
```

## How It Works

### For Legacy Clients
- Parse the certificate normally
- Use the classical ECDSA public key
- Verify the classical ECDSA signature
- **Ignore** the PQC extensions (unknown extensions are ignored per X.509)

### For PQC-Aware Clients
- Parse the certificate and recognize the Catalyst extensions
- Verify **both** signatures (classical AND post-quantum)
- Use the appropriate key based on negotiated protocol

## Interoperability Test

This demo includes an interoperability test showing how both legacy and modern clients handle the same hybrid certificate:

```bash
# Legacy client (OpenSSL - classical only)
openssl verify -CAfile hybrid-ca/ca.crt hybrid-server.crt
# → OK (uses ECDSA, ignores PQC extensions)

# PQC-aware client (pki tool)
pki verify --cert hybrid-server.crt --ca hybrid-ca/ca.crt
# → OK (verifies BOTH ECDSA and ML-DSA signatures)
```

| Client Type | What It Does | Result |
|-------------|--------------|--------|
| Legacy (OpenSSL) | Uses ECDSA, ignores PQC extensions | ✓ OK |
| PQC-Aware (pki) | Verifies BOTH signatures | ✓ OK |

**This is the power of hybrid: zero breaking changes for legacy clients.**

## Size Comparison

| Metric | Classical (ECDSA) | Hybrid (Catalyst) | Overhead |
|--------|-------------------|-------------------|----------|
| Certificate | ~1 KB | ~6 KB | ~5 KB |
| Private Key | ~300 B | ~2.5 KB | ~2.2 KB |

*The overhead comes from the additional ML-DSA key (~1952 B) and signature (~3293 B).*

## Why Hybrid Certificates?

### 1. Backwards Compatibility
Legacy clients that don't understand PQC continue to work. They simply use the classical key and ignore the PQC extensions.

### 2. Defense in Depth
If one algorithm is broken, the other still provides protection. This is the "belt and suspenders" approach to cryptography.

### 3. Regulatory Compliance
Some regulations still require classical algorithms. Hybrid certificates satisfy both classical requirements and provide quantum protection.

### 4. Smooth Migration
No "flag day" required. You can deploy hybrid certificates today and let clients upgrade to PQC-aware implementations at their own pace.

## When to Use Hybrid

| Use Case | Recommendation |
|----------|----------------|
| Public-facing web servers | **Hybrid** - you don't control all clients |
| Internal APIs (controlled clients) | Pure PQC or Hybrid |
| IoT devices (long-lived) | **Hybrid** - future-proof |
| Regulatory environments | **Hybrid** - satisfies both requirements |
| Testing/Development | Pure PQC (to validate full stack) |

## Catalyst vs Composite

There are two approaches to hybrid certificates:

| Approach | Description | Standard |
|----------|-------------|----------|
| **Catalyst** | Single cert, dual keys in extensions | ITU-T X.509 9.8 |
| **Composite** | Two separate certs, linked by extension | IETF draft |

This demo uses the **Catalyst** approach because:
- Single certificate simplifies deployment
- Works with existing certificate management
- Better backwards compatibility

## What You Learned

### The hybrid approach gives you:
- Classical security for legacy clients
- Quantum security for modern clients
- No forced upgrade timeline
- Defense in depth
- **Interoperability**: Same cert works with OpenSSL AND PQC-aware tools

### The trade-off:
- Larger certificates (~5x)
- Larger keys
- Two signatures to verify (for PQC clients)

## Next Steps

- [PKI-01: Store Now, Decrypt Later](../01-store-now-decrypt-later/) — Why encryption needs PQC now
- [PKI-03: Full PQC Chain](../03-full-pqc-chain/) — When you're ready for pure PQC

## References

- [ITU-T X.509 (2019) Section 9.8](https://www.itu.int/rec/T-REC-X.509) — Catalyst certificates
- [IETF draft-ounsworth-pq-composite-keys](https://datatracker.ietf.org/doc/draft-ounsworth-pq-composite-keys/) — Composite approach
- [NIST SP 800-131A Rev 2](https://csrc.nist.gov/publications/detail/sp/800-131a/rev-2/final) — Transition guidance

---

**Need help with your PQC transition?** Contact [QentriQ](https://qentriq.com)
