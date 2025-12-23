# Quick Start: Classical vs Post-Quantum

## Same PKI, Different Crypto

> **Key Message:** The PKI doesn't change. Only the algorithm changes.

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

> **Profiles:** See `profiles/` in this directory to customize algorithms or extensions.

### Step 1: Classical (ECDSA P-384)

```bash
# Create CA
pki init-ca --profile profiles/classic-root-ca.yaml \
    --name "Classic Root CA" --dir ./classic-ca

# Issue TLS certificate
pki issue --ca-dir ./classic-ca \
    --profile profiles/classic-tls-server.yaml \
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
pki init-ca --profile profiles/pqc-root-ca.yaml \
    --name "PQ Root CA" --dir ./pqc-ca

# Issue TLS certificate
pki issue --ca-dir ./pqc-ca \
    --profile profiles/pqc-tls-server.yaml \
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

---

## Security Timeline

```
         Today                2030              2040              2050
           │                   │                 │                 │
ECDSA      ├───────────────────┼─────────────────┼─────────────────┤
           │     SECURE        │   AT RISK       │   BROKEN        │
           │                   │                 │                 │
ML-DSA     ├───────────────────┼─────────────────┼─────────────────┤
           │     SECURE        │   SECURE        │   SECURE        │
           │                   │                 │                 │
```

---

## Migration Path

```
    TODAY                    TRANSITION                  FUTURE
      │                          │                         │
      ▼                          ▼                         ▼

┌──────────┐              ┌──────────────┐           ┌──────────┐
│ Classical│              │   Hybrid     │           │   PQC    │
│   PKI    │  ────────►   │    PKI       │  ──────►  │   PKI    │
│ (ECDSA)  │              │(ECDSA+ML-DSA)│           │ (ML-DSA) │
└──────────┘              └──────────────┘           └──────────┘

    100%                    Compatible                   100%
 Compatible                with both                  Quantum-Safe
```

---

## References

- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)

---

← [Home](../../README.md) | [Next: The Revelation →](../01-revelation/)
