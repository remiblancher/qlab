# The Revelation: The Quantum Threat to Your Data Today

> **Key Message:** Your data is already being recorded. The clock is ticking.

## Why Change Algorithms?

Classical PKI with ECDSA works. So why change?

A classical PKI is structurally correct — but cryptographically fragile in the long term.

Because **quantum computers will break everything**.

---

## The Scenario

*"Our sensitive data is encrypted. Why should I worry about quantum computers that don't exist yet?"*

## The Twin Threats

Quantum computers will break both **encryption** and **signatures**:

### SNDL: Store Now, Decrypt Later

Adversaries are **recording your encrypted traffic today**. When quantum computers arrive, they'll decrypt it all. This is called **Store Now, Decrypt Later (SNDL)** — also known as **Harvest Now, Decrypt Later (HNDL)**.

**The attack does not require breaking encryption today — only recording traffic.**

```
TODAY                           FUTURE (5-15 years?)
─────                           ────────────────────

  You                              Adversary
   │                                  │
   │ Encrypted data ──────────────►   │ Stored encrypted data
   │ (ECDH key exchange)              │
   │                                  │
   │                                  ▼
   │                              Quantum
   │                              Computer
   │                                  │
   │                                  ▼
   │                              Decrypted!
   │                              All your secrets
```

→ **Solution:** ML-KEM (quantum-resistant key exchange)

### TNFL: Trust Now, Forge Later

Signatures you trust today can be **forged** once quantum computers arrive. This is called **Trust Now, Forge Later (TNFL)** — also known as **Sign Today, Forge Tomorrow (STFT)**. A forged signature is instant and undetectable — malicious firmware signed with a forged key installs without question.

**Forged signatures are indistinguishable from legitimate ones.**

```
TODAY                           FUTURE (5-15 years?)
─────                           ────────────────────

  Your PKI                         Attacker
   │                                  │
   │ Certificates signed ─────────►   │ Captured certificates
   │ with ECDSA                       │ and public keys
   │                                  │
   │                                  ▼
   │                              Quantum
   │                              Computer
   │                                  │
   │                                  ▼
   │                              Forged certificates!
   │                              Impersonation possible
```

→ **Solution:** ML-DSA (quantum-resistant signatures) — *what this lab teaches*

---

## Who Should Worry?

| Data Type | Sensitivity Lifetime | SNDL Risk |
|-----------|---------------------|-----------|
| TLS session keys* | Minutes | Low |
| Personal health records | Decades | **Critical** |
| Government secrets | 25-50 years | **Critical** |
| Financial records | 7-10 years | High |
| Trade secrets | Variable | High |
| Military communications | 50+ years | **Critical** |

*\*But what about the content? User actions, exchanged data, and browsing patterns may remain sensitive long after the session ends.*

**If your data must remain secret for more than 10 years, you're already late.**

---

## When to Act

| Data Sensitivity Lifetime | Action Required |
|--------------------------|-----------------|
| < 5 years | Monitor, plan migration |
| 5-10 years | Begin hybrid deployment |
| 10-25 years | Urgent: Deploy PQC now |
| > 25 years | Critical: Should already have PQC |

---

## Mosca's Inequality

Michele Mosca formalized the urgency of migration:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   If  X + Y > Z  →  You have time (but start planning)         │
│   If  X + Y ≤ Z  →  ACT NOW                                    │
│                                                                 │
│   X = Years until quantum computer (10-15 years estimate)      │
│   Y = Time to migrate your systems (2-5 years)                 │
│   Z = Required confidentiality duration of your data           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Example: Medical Records

```
X = 10 years  (quantum computer estimate)
Y = 5 years   (infrastructure migration)
Z = 50 years  (patient records - HIPAA)

X + Y = 15 years

15 < 50  →  YOU'RE 35 YEARS LATE!
```

---

## Run the Demo

```bash
./demo.sh
```

The demo is an **interactive Mosca calculator** that helps you assess your PQC migration urgency based on your data's sensitivity lifetime.

---

## The Solution: Post-Quantum Algorithms

NIST finalized 3 post-quantum algorithms (August 2024).

*You don't need to memorize these numbers. The important takeaway is the order of magnitude and the trade-off: larger keys and signatures in exchange for quantum resistance.*

| Algorithm | Standard | Family | Purpose | Replaces | Protects Against |
|-----------|----------|--------|---------|----------|------------------|
| ML-KEM | FIPS 203 | Module Lattice | Key exchange | ECDH, RSA-KEM | SNDL |
| ML-DSA | FIPS 204 | Module Lattice | Signatures | ECDSA, RSA | TNFL |
| SLH-DSA | FIPS 205 | Stateless Hash | Signatures (conservative) | — | TNFL |

### Classical vs Post-Quantum: At a Glance

*Before diving into variants, here's what changes:*

**Signatures (protects against TNFL)**

| | ECDSA P-384 | ML-DSA-65 | Change |
|--|-------------|-----------|--------|
| Public Key | 97 B | 1,952 B | 20x larger |
| Signature | 96 B | 3,309 B | 34x larger |
| Signing | 0.9 ms | 0.7 ms | **~20% faster** |
| Verification | 0.3 ms | 0.15 ms | **2x faster** |

**Key Exchange (protects against SNDL)**

| | X25519 | ML-KEM-768 | Change |
|--|--------|------------|--------|
| Public Key | 32 B | 1,184 B | 37x larger |
| Ciphertext | 32 B | 1,088 B | 34x larger |
| Speed | ~0.05 ms | ~0.1 ms | ~2x slower (still sub-ms) |

**Bottom line:** Larger sizes, but signing/verification is faster. The trade-off is worth it for quantum resistance.

*For detailed sizes, variants, and benchmarks, see [Algorithm Reference](../../docs/ALGORITHM-REFERENCE.md#performance-benchmarks).*

---

## What You Learned

1. **SNDL is real:** Adversaries record encrypted traffic today → ML-KEM protects
2. **TNFL is real:** Signatures trusted today can be forged tomorrow → ML-DSA protects
3. **Timing matters:** Your data's sensitivity lifetime determines urgency
4. **NIST standards are ready:** ML-KEM (FIPS 203) and ML-DSA (FIPS 204) are finalized

---

## References

- [FIPS 203: ML-KEM Standard](https://csrc.nist.gov/pubs/fips/203/final)
- [FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)
- [FIPS 205: SLH-DSA Standard](https://csrc.nist.gov/pubs/fips/205/final)
- [Mosca's Theorem](https://globalriskinstitute.org/publication/quantum-threat-timeline/)

---

← [Quick Start](../01-quickstart/) | [QLAB Home](../../README.md) | [Next: Full Chain →](../02-full-chain/)
