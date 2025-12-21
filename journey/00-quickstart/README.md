# Quick Start: Classical vs Post-Quantum

## Same PKI, Different Crypto

> **Key Message:** The PKI doesn't change. Only the algorithm changes.

> **Visual diagrams:** See [`diagram.txt`](diagram.txt) for ASCII diagrams.

## The Scenario

*"I want to issue post-quantum certificates. Does it change my PKI workflow?"*

Short answer: **No.** The PKI workflow is identical. Only the algorithm name changes.

## What This Demo Shows

| Step | Classical | Post-Quantum |
|------|-----------|--------------|
| Create CA | ECDSA P-384 | ML-DSA-65 |
| Issue cert | Same workflow | Same workflow |
| Result | Vulnerable to quantum | Quantum-resistant |

## Run the Demo

```bash
./journey/00-quickstart/demo.sh
```

**Duration:** 10 minutes

## The Commands

After running the demo, artifacts are in `output/`.

> **Profiles:** See `profiles/` at project root to customize validity, extensions, or subject DN

### Step 1: Classical (ECDSA P-384)

```bash
# Create CA
pki init-ca --profile ec/root-ca --name "Classic Root CA" --dir ./classic-ca

# Issue TLS certificate
pki issue --ca-dir ./classic-ca \
    --profile ec/tls-server \
    --cn classic.example.com \
    --dns classic.example.com \
    --out classic-server.crt \
    --key-out classic-server.key

# Inspect
pki info classic-server.crt
```

### Step 2: Post-Quantum (ML-DSA-65)

```bash
# Create CA
pki init-ca --profile ml-dsa-kem/root-ca --name "PQ Root CA" --dir ./pqc-ca

# Issue TLS certificate
pki issue --ca-dir ./pqc-ca \
    --profile ml-dsa-kem/tls-server \
    --cn pq.example.com \
    --dns pq.example.com \
    --out pq-server.crt \
    --key-out pq-server.key

# Inspect
pki info pq-server.crt
```

**Notice anything?** The workflow is identical. Only the algorithm name changes.

> **Tip:** For detailed ASN.1 output, use `openssl x509 -in <cert> -text -noout`

## Expected Results

### Size Comparison*

| Metric | Classical (ECDSA P-384) | Post-Quantum (ML-DSA-65) | Ratio |
|--------|-------------------------|--------------------------|-------|
| Public key | 97 bytes | 1,952 bytes | 20x |
| Signature | 96 bytes | 3,309 bytes | 34x |
| Certificate | ~1 KB | ~6 KB | ~6x |

*\* Source: [NIST FIPS 204](https://csrc.nist.gov/pubs/fips/204/final), Table 2. Certificate sizes depend on extensions.*

### Performance Comparison**

| Operation | Classical | Post-Quantum | Notes |
|-----------|-----------|--------------|-------|
| Key generation | fast | slower | ML-DSA slower by design |
| Sign | fast | ~2x faster | ML-DSA outperforms ECDSA |
| Verify | fast | faster | ML-DSA significantly faster |

*\*\* Source: [ML-DSA Benchmark](https://medium.com/@moeghifar/post-quantum-digital-signatures-the-benchmark-of-ml-dsa-against-ecdsa-and-eddsa-d4406a5918d9). Performance varies by hardware.*

**The trade-off:** Larger sizes, but faster operations and quantum resistance.

## Key Takeaway

**Switching to post-quantum is a profile change, not an architecture change.**

The workflow stays identical: `init-ca` → `issue` → X.509 certificates.
Only the algorithm (and sizes) change.

## References

- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)
- [Cloudflare CIRCL Library](https://github.com/cloudflare/circl)

---

← [Home](../../README.md) | [Next: The Revelation →](../01-revelation/)
