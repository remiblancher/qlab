# Full PQC Chain of Trust

## Build a Complete PQC PKI Hierarchy

> **Key Message:** End-to-end PQC chain = same architecture, quantum-safe. The hierarchy doesn't change — only the algorithms.

---

## The Scenario

*"I'm ready to go fully quantum-safe. How do I build a complete PQC PKI from root to end-entity?"*

This demo shows a production-ready 3-level PKI hierarchy using only post-quantum algorithms. No classical cryptography anywhere in the chain.

*This demo focuses on PKI design, not client interoperability. See [Hybrid PKI](../03-hybrid/) for legacy client support.*

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                    ROOT CA                                      │
│                    ════════                                     │
│                    ML-DSA-87                                    │
│                    (maximum security, 256 bits)                 │
│                           │                                     │
│                           │ Signs                               │
│                           ▼                                     │
│                    ISSUING CA                                   │
│                    ══════════                                   │
│                    ML-DSA-65                                    │
│                    (daily operations)                           │
│                           │                                     │
│                           │ Signs                               │
│                           ▼                                     │
│                    TLS CERTIFICATE                              │
│                    ═══════════════                              │
│                    ML-DSA-65                                    │
│                    server.example.com                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## What This Demo Shows

| Level | Algorithm | Security Level |
|-------|-----------|----------------|
| Root CA | ML-DSA-87 | NIST Level 5 (~256-bit) |
| Issuing CA | ML-DSA-65 | NIST Level 3 (~192-bit) |
| TLS Server | ML-DSA-65 | NIST Level 3 (~192-bit) |

---

## Run the Demo

```bash
./demo.sh
```

---

## The Commands

### Step 1: Create Root CA (ML-DSA-87)

```bash
# Initialize the root CA with highest security level
qpki ca init --profile profiles/pqc-root-ca.yaml \
    --var cn="PQC Root CA" \
    --ca-dir output/pqc-root-ca

# Inspect
qpki inspect output/pqc-root-ca/ca.crt
```

### Step 2: Create Issuing CA (ML-DSA-65)

```bash
# Create issuing CA signed by root
qpki ca init --profile profiles/pqc-issuing-ca.yaml \
    --var cn="PQC Issuing CA" \
    --parent output/pqc-root-ca \
    --ca-dir output/pqc-issuing-ca

# Inspect
qpki inspect output/pqc-issuing-ca/ca.crt
```

### Step 3: Generate Server Key and CSR

```bash
# Generate ML-DSA-65 key and CSR
qpki csr gen --algorithm ml-dsa-65 \
    --keyout output/server.key \
    --cn server.example.com \
    --out output/server.csr
```

### Step 4: Issue TLS Server Certificate

```bash
# Issue end-entity certificate from CSR
qpki cert issue --ca-dir output/pqc-issuing-ca \
    --profile profiles/pqc-tls-server.yaml \
    --csr output/server.csr \
    --out output/server.crt

# Inspect
qpki inspect output/server.crt
```

> **Tip:** For detailed ASN.1 output, use `openssl x509 -in <cert> -text -noout`

---

## Size Comparison

| Certificate | Classical (ECDSA) | Full PQC | Ratio |
|-------------|-------------------|----------|-------|
| Root CA | ~1 KB | ~7 KB | ~7x |
| Issuing CA | ~1 KB | ~6 KB | ~6x |
| TLS Server | ~1 KB | ~6 KB | ~6x |
| **Full chain** | ~3 KB | ~19 KB | ~6x |

*Approximate sizes. The trade-off: larger certificates for quantum resistance.*

*Bandwidth impact is usually negligible compared to application payloads.*

---

## Algorithm Selection Guide

| Use Case | Recommended Algorithm | Why |
|----------|----------------------|-----|
| Root CA | ML-DSA-87 | Maximum security, long-lived |
| Issuing CA | ML-DSA-65 | Balance security/performance |
| TLS Server | ML-DSA-65 | Server authentication |
| TLS Client | ML-DSA-44 | Constrained devices OK |
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

---

## What You Learned

1. **Same workflow:** Creating a PQC hierarchy uses identical PKI concepts
2. **Algorithm stacking:** Root uses highest level, decreasing down the chain
3. **Size trade-off:** ~6x larger certificates for quantum resistance

---

## When to Deploy Full PQC

| Scenario | Recommendation |
|----------|----------------|
| New internal PKI | **Full PQC** - Start quantum-safe |
| Public-facing servers | Hybrid (UC-03) - Legacy client support |
| Government/Military | **Full PQC** - Regulatory requirements |
| IoT (long-lived) | **Full PQC** - Future-proof devices |
| Short-lived tokens | Classical OK - Low SNDL risk |

---

## References

- [NIST FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)
- [NIST FIPS 205: SLH-DSA Standard](https://csrc.nist.gov/pubs/fips/205/final)
- [NSA CNSA 2.0 Guidelines (PDF)](https://media.defense.gov/2025/May/30/2003728741/-1/-1/0/CSA_CNSA_2.0_ALGORITHMS.PDF)
- [NSA CNSA 2.0 Announcement](https://www.nsa.gov/Press-Room/News-Highlights/Article/Article/3148990/nsa-releases-future-quantum-resistant-qr-algorithm-requirements-for-national-se/)

---

← [The Revelation](../01-revelation/) | [QLAB Home](../../README.md) | [Next: Hybrid →](../03-hybrid/)
