# UC-05: "Full post-quantum chain of trust"

## Complete PQC PKI Hierarchy

> **Key Message:** Build a complete quantum-resistant PKI from root to end-entity.

> **Visual diagrams:** See [`diagram.txt`](diagram.txt) for ASCII diagrams of the full PQC hierarchy.

## The Scenario

*"I'm ready to go fully quantum-safe. How do I build a complete PQC PKI from root to end-entity?"*

This demo shows a production-ready 3-level PKI hierarchy using only post-quantum algorithms. No classical cryptography anywhere in the chain.

## What This Demo Shows

| Level | Algorithm | Security Level |
|-------|-----------|----------------|
| Root CA | ML-DSA-87 | NIST Level 5 (~256-bit) |
| Issuing CA | ML-DSA-65 | NIST Level 3 (~192-bit) |
| TLS Server | ML-DSA-65 + ML-KEM-768 | NIST Level 3 |

## Run the Demo

```bash
./demo.sh
```

**Prerequisites:**
- PKI tool installed (`../tooling/install.sh`)
- ~3 minutes of your time

## The Commands

### Step 1: Create Root CA (ML-DSA-87)

```bash
# Initialize the root CA with highest security level
pki init-ca --name "PQC Root CA" \
    --org "Demo Organization" \
    --algorithm ml-dsa-87 \
    --dir ./pqc-root-ca

# Inspect
pki info ./pqc-root-ca/ca.crt
```

### Step 2: Create Issuing CA (ML-DSA-65)

```bash
# Create issuing CA signed by root
pki init-ca --name "PQC Issuing CA" \
    --org "Demo Organization" \
    --algorithm ml-dsa-65 \
    --parent ./pqc-root-ca \
    --dir ./pqc-issuing-ca

# Inspect
pki info ./pqc-issuing-ca/ca.crt
```

### Step 3: Issue TLS Server Certificate

```bash
# Issue end-entity certificate for TLS server
pki issue --ca-dir ./pqc-issuing-ca \
    --profile ml-dsa-kem/tls-server \
    --cn server.example.com \
    --dns server.example.com \
    --out server.crt \
    --key-out server.key

# Inspect
pki info server.crt
```

> **Tip:** For detailed ASN.1 output, use `openssl x509 -in <cert> -text -noout`

## PKI Hierarchy

```
┌─────────────────────────────────────┐
│           PQC Root CA               │
│           ML-DSA-87                 │
│       (NIST Level 5 - highest)      │
└─────────────────┬───────────────────┘
                  │ signs
                  ▼
┌─────────────────────────────────────┐
│         PQC Issuing CA              │
│           ML-DSA-65                 │
│          (NIST Level 3)             │
└─────────────────┬───────────────────┘
                  │ signs
                  ▼
┌─────────────────────────────────────┐
│       TLS Server Certificate        │
│   ML-DSA-65 (sig) + ML-KEM-768 (enc)│
│          (NIST Level 3)             │
└─────────────────────────────────────┘
```

## Size Comparison

| Certificate | Classical (ECDSA) | Full PQC | Ratio |
|-------------|-------------------|----------|-------|
| Root CA | ~1 KB | ~7 KB | ~7x |
| Issuing CA | ~1 KB | ~6 KB | ~6x |
| TLS Server | ~1 KB | ~6 KB | ~6x |
| **Full chain** | ~3 KB | ~19 KB | ~6x |

*Approximate sizes. The trade-off: larger certificates for quantum resistance.*

## Algorithm Selection Guide

| Use Case | Recommended Algorithm | Why |
|----------|----------------------|-----|
| Root CA | ML-DSA-87 | Maximum security, long-lived |
| Issuing CA | ML-DSA-65 | Balance security/performance |
| TLS Server | ML-DSA-65 + ML-KEM-768 | Signature + key exchange |
| TLS Client | ML-DSA-44 + ML-KEM-768 | Constrained devices OK |
| Code Signing | ML-DSA-65 | Long-lived signatures |

### When to Use SLH-DSA Instead

SLH-DSA (hash-based signatures) is a conservative alternative:

| Algorithm | Pros | Cons |
|-----------|------|------|
| **ML-DSA** | Small keys, fast verify | Newer, lattice-based |
| **SLH-DSA** | Well-understood math | Large signatures (~17-49 KB) |

Use SLH-DSA when:
- Maximum cryptographic conservatism is required
- Signature size is not a constraint
- You want hash-based (no lattice assumptions)

## What You Learned

1. **Same workflow:** Creating a PQC hierarchy uses identical PKI concepts
2. **Algorithm stacking:** Root uses highest level, decreasing down the chain
3. **Dual algorithms:** TLS certs need both ML-DSA (signatures) and ML-KEM (encryption)
4. **Size trade-off:** ~6x larger certificates for quantum resistance

## When to Deploy Full PQC

| Scenario | Recommendation |
|----------|----------------|
| New internal PKI | **Full PQC** - Start quantum-safe |
| Public-facing servers | Hybrid (UC-02) - Legacy client support |
| Government/Military | **Full PQC** - Regulatory requirements |
| IoT (long-lived) | **Full PQC** - Future-proof devices |
| Short-lived tokens | Classical OK - Low SNDL risk |

## Related Use Cases

- **Comparing classical:** [UC-01: Classical vs PQC TLS](../01-classic-vs-pqc-tls/)
- **Legacy compatibility:** [UC-02: Hybrid Certificates](../02-hybrid-cert/)
- **Why encryption needs PQC now:** [UC-03: Store Now, Decrypt Later](../03-store-now-decrypt-later/)
- **Long-lived signatures:** [UC-06: Code Signing](../06-code-signing/)

## References

- [NIST FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)
- [NIST FIPS 203: ML-KEM Standard](https://csrc.nist.gov/pubs/fips/203/final)
- [NIST FIPS 205: SLH-DSA Standard](https://csrc.nist.gov/pubs/fips/205/final)
- [NSA CNSA 2.0 Guidelines](https://media.defense.gov/2022/Sep/07/2003071834/-1/-1/0/CSA_CNSA_2.0_ALGORITHMS_.PDF)

---

**Need help deploying a full PQC PKI?** Contact [QentriQ](https://qentriq.com)
