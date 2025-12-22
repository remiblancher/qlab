# The Revelation: The Quantum Threat to Your Data Today

> **Key Message:** Encrypted data captured today can be decrypted tomorrow. Signatures trusted today can be forged tomorrow. PQC is urgent.

> **Visual diagrams:** See [`diagram.txt`](diagram.txt) for detailed ASCII diagrams of SNDL, TNFL, Mosca's inequality, and algorithm comparisons.

## Why Change Algorithms?

You just created a classical PKI with ECDSA. It works. So why change?

Because **quantum computers will break everything**.

---

## The Scenario

*"Our sensitive data is encrypted. Why should I worry about quantum computers that don't exist yet?"*

## The Twin Threats

Quantum computers will break both **encryption** and **signatures**:

### SNDL: Store Now, Decrypt Later

Adversaries are **recording your encrypted traffic today**. When quantum computers arrive, they'll decrypt it all. This is called **Store Now, Decrypt Later (SNDL)** — also known as **Harvest Now, Decrypt Later (HNDL)**.

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

NIST finalized 3 post-quantum algorithms (August 2024):

| Algorithm | Standard | Family | Protects Against | Replaces |
|-----------|----------|--------|------------------|----------|
| ML-KEM | FIPS 203 | Module Lattice | SNDL (encryption) | ECDH, RSA-KEM |
| ML-DSA | FIPS 204 | Module Lattice | TNFL (signatures) | ECDSA, RSA |
| SLH-DSA | FIPS 205 | Stateless Hash | TNFL (signatures) | Alternative to ML-DSA |

### ML-KEM Variants (Key Encapsulation) — *used in this lab*

ML-KEM (Module Lattice Key Encapsulation Mechanism) enables secure key exchange resistant to quantum attacks. Unlike traditional Diffie-Hellman where both parties contribute to the shared secret, ML-KEM uses **encapsulation**: one party generates a random secret and "wraps" it with the recipient's public key. Only the recipient can "unwrap" it with their private key.

| Variant | Security | Public Key | Ciphertext |
|---------|----------|------------|------------|
| ML-KEM-512 | Level 1 (~128-bit) | 800 bytes | 768 bytes |
| ML-KEM-768 | Level 3 (~192-bit) | 1,184 bytes | 1,088 bytes |
| ML-KEM-1024 | Level 5 (~256-bit) | 1,568 bytes | 1,568 bytes |

### ML-DSA Variants (Signatures) — *used in this lab*

ML-DSA (Module Lattice Digital Signature Algorithm) provides quantum-resistant digital signatures. It replaces ECDSA and RSA signatures in certificates, code signing, and document authentication. The security is based on the hardness of lattice problems that quantum computers cannot efficiently solve.

| Variant | Security | Public Key | Signature |
|---------|----------|------------|-----------|
| ML-DSA-44 | Level 2 (~128-bit) | 1,312 bytes | 2,420 bytes |
| ML-DSA-65 | Level 3 (~192-bit) | 1,952 bytes | 3,293 bytes |
| ML-DSA-87 | Level 5 (~256-bit) | 2,592 bytes | 4,595 bytes |

### SLH-DSA Variants (Stateless Hash-Based Signatures)

SLH-DSA (Stateless Hash-Based Digital Signature Algorithm) is a conservative alternative to ML-DSA. Its security relies solely on hash functions — well-understood primitives with decades of cryptanalysis. The trade-off: significantly larger signatures. Use SLH-DSA when you need maximum confidence in long-term security assumptions.

| Variant | Security | Public Key | Signature |
|---------|----------|------------|-----------|
| SLH-DSA-128s | Level 1 (~128-bit) | 32 bytes | 7,856 bytes |
| SLH-DSA-128f | Level 1 (~128-bit) | 32 bytes | 17,088 bytes |
| SLH-DSA-192s | Level 3 (~192-bit) | 48 bytes | 16,224 bytes |
| SLH-DSA-192f | Level 3 (~192-bit) | 48 bytes | 35,664 bytes |
| SLH-DSA-256s | Level 5 (~256-bit) | 64 bytes | 29,792 bytes |
| SLH-DSA-256f | Level 5 (~256-bit) | 64 bytes | 49,856 bytes |

*s = small (slower, smaller signatures), f = fast (faster, larger signatures)*

### Why Hybrid?

During the transition period, the recommended approach is to combine **classical + PQC** algorithms. This is the "belt and suspenders" strategy:

```
Hybrid Key Exchange:  X25519 + ML-KEM-768
Hybrid Signature:     ECDSA + ML-DSA-65
```

**Why not pure PQC right now?**

PQC algorithms are mathematically sound, but they're new. Classical algorithms like ECDSA have decades of cryptanalysis — researchers worldwide have tried (and failed) to break them. PQC algorithms don't have this track record yet. A hybrid approach hedges against the unknown.

**The security guarantee:**

| Scenario | Classical | PQC | Hybrid Result |
|----------|-----------|-----|---------------|
| No quantum computer | ✓ Secure | ✓ Secure | ✓ Secure |
| Quantum computer exists | ✗ Broken | ✓ Secure | ✓ Secure |
| PQC weakness discovered | ✓ Secure | ✗ Broken | ✓ Secure |
| Both fail | ✗ Broken | ✗ Broken | ✗ Broken |

**Result:** Hybrid fails only if BOTH algorithms fail simultaneously — an extremely unlikely scenario.

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

← [Quick Start](../00-quickstart/) | [Next: Full Chain →](../02-full-chain/)
