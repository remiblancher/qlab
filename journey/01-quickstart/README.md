# Quick Start: Classical vs Post-Quantum

## Same PKI, Different Crypto

> **Key Message:** Same workflow, new capabilities. The PKI must evolve to handle multiple algorithms — but your commands stay the same.

## The Scenario

*"I want to issue post-quantum certificates. Does it change my PKI workflow?"*

Short answer: **No.** The PKI workflow is identical. Only the algorithm name changes.

```
┌──────────────────────────────────────────────────────────────┐
│  CLASSICAL                      POST-QUANTUM                 │
│  ─────────                      ────────────                 │
│                                                              │
│   ROOT CA                        ROOT CA                     │
│   ECDSA P-384                    ML-DSA-65                   │
│       │                              │                       │
│       │ Signs                        │ Signs                 │
│       ▼                              ▼                       │
│   TLS CERT                       TLS CERT                    │
│   server.crt                     server.crt                  │
│                                                              │
│   Same workflow — different algorithm                        │
└──────────────────────────────────────────────────────────────┘
```

---

## What This Demo Shows

| Step | Classical | Post-Quantum |
|------|-----------|--------------|
| Create CA | ECDSA P-384 | ML-DSA-65 |
| Issue cert | Same workflow | Same workflow |
| Result | Vulnerable to quantum | Quantum-resistant |

## Run the Demo

```bash
./journey/01-quickstart/demo.sh
```

**Duration:** 10 minutes

## The Commands

After running the demo, artifacts are in `output/`.

> **Profiles:** See `profiles/` in this directory to customize algorithms or extensions.

### Step 1: Classical (ECDSA P-384)

```bash
# Create CA
qpki ca init --profile profiles/classic-root-ca.yaml \
    --var cn="Classic Root CA" --ca-dir ./classic-ca

# Generate key and CSR
qpki csr gen --algorithm ecdsa-p384 \
    --keyout classic-server.key \
    --cn classic.example.com \
    --out classic-server.csr

# Issue TLS certificate
qpki cert issue --ca-dir ./classic-ca \
    --profile profiles/classic-tls-server.yaml \
    --csr classic-server.csr \
    --out classic-server.crt

# Inspect
qpki inspect classic-server.crt
```

### Step 2: Post-Quantum (ML-DSA-65)

```bash
# Create CA
qpki ca init --profile profiles/pqc-root-ca.yaml \
    --var cn="PQ Root CA" --ca-dir ./pqc-ca

# Generate key and CSR
qpki csr gen --algorithm ml-dsa-65 \
    --keyout pq-server.key \
    --cn pq.example.com \
    --out pq-server.csr

# Issue TLS certificate
qpki cert issue --ca-dir ./pqc-ca \
    --profile profiles/pqc-tls-server.yaml \
    --csr pq-server.csr \
    --out pq-server.crt

# Inspect
qpki inspect pq-server.crt
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

### Performance Comparison (ML-DSA-65 vs ECDSA P-384)

| Operation | Ratio |
|-----------|-------|
| Key generation | **3x faster** |
| Signing | **~20% faster** |
| Verification | **2x faster** |

*Details: [Algorithm Reference](../../docs/ALGORITHM-REFERENCE.md#performance-benchmarks)*

**The trade-off:** Larger sizes, but faster operations and quantum resistance.

## Key Takeaway

**Switching to post-quantum is a profile change, not an architecture change.**

The workflow stays identical: `qpki ca init` → `qpki csr gen` → `qpki cert issue` → X.509 certificates.
Only the algorithm (and sizes) change.

> **Note:** While the workflow stays identical, your PKI infrastructure must evolve to support:
> - Multiple algorithms in parallel (hybrid certificates)
> - Crypto-agile enrollment (attestation for KEM keys)
> - CA versioning for reversible migration
>
> You'll explore these capabilities in [UC-03](../03-hybrid/), [UC-09](../09-cms-encryption/), and [UC-10](../10-crypto-agility/).

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

← [The Revelation](../00-revelation/) | [QLAB Home](../../README.md) | [Next: Full Chain →](../02-full-chain/)
