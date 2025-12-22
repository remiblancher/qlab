# The Revelation: The Quantum Threat to Your Data Today

> **Key Message:** Encrypted data captured today can be decrypted tomorrow. PQC for encryption is urgent.

> **Visual diagrams:** See [`diagram.txt`](diagram.txt) for detailed ASCII diagrams of the SNDL attack, Mosca's inequality, and ML-KEM comparison.

## The Scenario

*"Our sensitive data is encrypted. Why should I worry about quantum computers that don't exist yet?"*

Because adversaries are **recording your encrypted traffic today**. When quantum computers arrive, they'll decrypt it all. This is called **Store Now, Decrypt Later (SNDL)** — also known as **Harvest Now, Decrypt Later (HNDL)**.

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

**Rule of thumb:** If your data needs to stay secret for more than 10 years, you need PQC encryption **now**.

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

## What This Demo Shows

1. **The SNDL threat** — Visual explanation of the attack
2. **Mosca's calculator** — Calculate YOUR urgency interactively

---

## Run the Demo

```bash
./demo.sh
```

The demo is an **interactive Mosca calculator** that helps you assess your PQC migration urgency based on your data's sensitivity lifetime.

---

## NIST Standards (August 2024)

NIST finalized 3 post-quantum algorithms:

| Algorithm | Standard | Usage | Replaces |
|-----------|----------|-------|----------|
| **ML-DSA** | FIPS 204 | Signatures | RSA, ECDSA, Ed25519 |
| **ML-KEM** | FIPS 203 | Key exchange | ECDH, RSA-KEM |
| **SLH-DSA** | FIPS 205 | Signatures (hash-based) | Alternative to ML-DSA |

### ML-DSA (formerly Dilithium)

- Based on **lattice** cryptography
- 3 security levels: ML-DSA-44, ML-DSA-65, ML-DSA-87
- Larger signatures (~2-4 KB) but very fast

### ML-KEM (formerly Kyber)

- Also based on **lattices**
- 3 levels: ML-KEM-512, ML-KEM-768, ML-KEM-1024
- For key exchange (TLS, VPN, etc.)

---

## What You Learned

1. **SNDL is real:** Adversaries record encrypted traffic today
2. **Timing matters:** Your data's sensitivity lifetime determines urgency
3. **ML-KEM is ready:** NIST FIPS 203 standard is finalized
4. **Hybrid is safe:** Use both classical and PQC during transition

---

## References

- [NIST FIPS 203: ML-KEM Standard](https://csrc.nist.gov/pubs/fips/203/final)
- [Mosca's Theorem](https://globalriskinstitute.org/publication/quantum-threat-timeline/)
- [NSA CNSA 2.0 Guidelines](https://media.defense.gov/2022/Sep/07/2003071834/-1/-1/0/CSA_CNSA_2.0_ALGORITHMS_.PDF)

---

## Next Step

→ **Level 1: Build Your Quantum-Safe Foundation**

You'll create your first post-quantum CA with ML-DSA.
