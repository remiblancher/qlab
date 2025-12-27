# PKI-02: "Classic vs PQC: Nothing Changes"

## Classical vs Post-Quantum: Same PKI, Different Crypto

> **Key Message:** The PKI doesn't change. Only the algorithm changes.

> **Visual diagrams:** See [`diagram.txt`](diagram.txt) for ASCII diagrams comparing classical and PQC certificate workflows.

## The Scenario

*"I want to issue post-quantum certificates. Does it change my PKI workflow?"*

Short answer: **No.** The PKI workflow is identical. Only the algorithm name changes. This demo proves it.

## What This Demo Shows

| Step | Classical | Post-Quantum |
|------|-----------|--------------|
| Create CA | ECDSA P-384 | ML-DSA-65 |
| Issue cert | Same workflow | Same workflow |
| Result | Vulnerable to quantum | Quantum-resistant |

## Run the Demo

```bash
./demo.sh
```

## The Commands

### Step 1: Classical (ECDSA P-384)

```bash
# Create CA
pki ca init --profile ec/root-ca --name "Classic Root CA" --dir ./classic-ca

# Inspect CA certificate
pki inspect ./classic-ca/ca.crt

# Issue TLS certificate
pki cert issue --ca-dir ./classic-ca \
    --profile ec/tls-server \
    --cn classic.example.com \
    --dns classic.example.com \
    --out classic-server.crt \
    --key-out classic-server.key

# Inspect
pki inspect classic-server.crt
```

### Step 2: Post-Quantum (ML-DSA-65)

```bash
# Create CA
pki ca init --profile ml-dsa-kem/root-ca --name "PQ Root CA" --dir ./pqc-ca

# Inspect CA certificate
pki inspect ./pqc-ca/ca.crt

# Issue TLS certificate
pki cert issue --ca-dir ./pqc-ca \
    --profile ml-dsa-kem/tls-server \
    --cn pq.example.com \
    --dns pq.example.com \
    --out pq-server.crt \
    --key-out pq-server.key

# Inspect
pki inspect pq-server.crt
```

**Notice anything?** The workflow is identical. Only the algorithm name changes.

> **Tip:** For detailed ASN.1 output, use `openssl x509 -in <cert> -text -noout`

## Expected Results

### Size Comparison

| Metric | Classical (ECDSA P-384) | Post-Quantum (ML-DSA-65) | Ratio |
|--------|-------------------------|--------------------------|-------|
| Public key | ~97 bytes | ~1,952 bytes | ~20x |
| Signature | ~96 bytes | ~3,309 bytes | ~34x |
| Certificate | ~1 KB | ~6 KB | ~6x |

*Approximate ratios. Actual sizes depend on certificate extensions and metadata.*

### Performance Comparison*

| Operation | Classical | Post-Quantum | Notes |
|-----------|-----------|--------------|-------|
| Key generation | fast | slower | ML-DSA slower by design |
| Sign | fast | ~2x faster | ML-DSA outperforms ECDSA |
| Verify | fast | faster | ML-DSA significantly faster |

*\* Source: [ML-DSA Benchmark](https://medium.com/@moeghifar/post-quantum-digital-signatures-the-benchmark-of-ml-dsa-against-ecdsa-and-eddsa-d4406a5918d9). Performance varies by hardware.*

**The trade-off:** Larger sizes, but faster operations and quantum resistance.

## What You Learned

### What stayed the same:
- Certificate structure (X.509)
- CA hierarchy concept
- Issuance workflow
- Revocation mechanism
- Trust model
- Your PKI knowledge

### What changed:
- Signature algorithm identifier
- Key and signature sizes
- OIDs (Object Identifiers)

## Why This Matters

Post-quantum cryptography prepares your infrastructure for the future. The key insight from this demo:

**Your PKI skills transfer 100%.** Learning PQC doesn't mean relearning PKI.

### Want to go deeper?

- **Why PQC for encryption?** → [UC-03: Store Now, Decrypt Later](../03-store-now-decrypt-later/)
- **Why PQC for long-lived signatures?** → [UC-06: Code Signing](../06-code-signing/)
- **How to migrate safely?** → [UC-02: Hybrid Certificates](../02-hybrid-cert/)

## Algorithms Used

### ECDSA P-384 (Classical)
- Elliptic Curve Digital Signature Algorithm
- NIST P-384 curve
- ~192-bit security level
- Vulnerable to Shor's algorithm on quantum computers

### ML-DSA-65 (Post-Quantum)
- Module-Lattice Digital Signature Algorithm
- NIST FIPS 204 standard (2024)
- Security Level 3 (~192-bit equivalent)
- Resistant to known quantum attacks
- Based on the hardness of Module-LWE problem

## References

- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)
- [Cloudflare CIRCL Library](https://github.com/cloudflare/circl)

---

**Need help with your PQC transition?** Contact [QentriQ](https://qentriq.com)
