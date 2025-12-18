# UC-03: "The real problem: Store Now, Decrypt Later"

## Long-Term Encryption and the SNDL Threat

> **Key Message:** Encrypted data captured today can be decrypted tomorrow. PQC for encryption is urgent.

## The Scenario

*"Our sensitive data is encrypted. Why should I worry about quantum computers that don't exist yet?"*

Because adversaries are **recording your encrypted traffic today**. When quantum computers arrive, they'll decrypt it all. This is called **Store Now, Decrypt Later (SNDL)** — also known as **Harvest Now, Decrypt Later (HNDL)**.

## The SNDL Threat

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

## Who Should Worry?

| Data Type | Sensitivity Lifetime | SNDL Risk |
|-----------|---------------------|-----------|
| TLS session keys | Minutes | Low |
| Personal health records | Decades | **Critical** |
| Government secrets | 25-50 years | **Critical** |
| Financial records | 7-10 years | High |
| Trade secrets | Variable | High |
| Military communications | 50+ years | **Critical** |

**Rule of thumb:** If your data needs to stay secret for more than 10 years, you need PQC encryption **now**.

## What This Demo Shows

1. **Classical key exchange** (ECDH) — Vulnerable to quantum attack
2. **PQC key encapsulation** (ML-KEM) — Quantum-resistant
3. **Hybrid key exchange** — Best of both worlds during transition
4. **Timeline analysis** — When to act based on data sensitivity

## The Solution: ML-KEM

ML-KEM (Module Lattice Key Encapsulation Mechanism) is NIST's standard for post-quantum key exchange:

| Variant | Security Level | Ciphertext | Public Key |
|---------|---------------|------------|------------|
| ML-KEM-512 | 1 (~128-bit) | 768 bytes | 800 bytes |
| ML-KEM-768 | 3 (~192-bit) | 1,088 bytes | 1,184 bytes |
| ML-KEM-1024 | 5 (~256-bit) | 1,568 bytes | 1,568 bytes |

## Running the Demo

```bash
./demo.sh
```

The demo will:
1. Show SNDL attack timeline
2. Demonstrate classical ECDH key exchange
3. Demonstrate ML-KEM key encapsulation
4. Compare sizes and explain tradeoffs
5. Show hybrid approach for migration

## Technical Details

### Classical Key Exchange (ECDH)

```
Alice                              Bob
  │                                  │
  │──── Public Key (ECDSA) ────────►│
  │◄─── Public Key (ECDSA) ─────────│
  │                                  │
  │  Shared Secret = ECDH(A, B)      │
  │                                  │
```

**Problem:** A quantum computer can solve the discrete log problem and recover the shared secret from the public keys.

### PQC Key Encapsulation (ML-KEM)

```
Alice                              Bob
  │                                  │
  │──── Public Key (ML-KEM) ───────►│
  │                                  │
  │       Bob encapsulates:          │
  │       (ciphertext, shared_key)   │
  │       = Encaps(Alice_PK)         │
  │                                  │
  │◄─── Ciphertext ─────────────────│
  │                                  │
  │  Alice decapsulates:             │
  │  shared_key = Decaps(ciphertext) │
```

**Solution:** ML-KEM is based on lattice problems that quantum computers cannot efficiently solve.

### Hybrid Key Exchange

During the transition, use **both** classical and PQC:

```
Final Key = KDF(ECDH_shared || ML-KEM_shared)
```

**Benefits:**
- If ECDH breaks → ML-KEM protects
- If ML-KEM has unknown weakness → ECDH protects
- Maintains backwards compatibility

## Size Comparison

| Component | ECDH (P-256) | ML-KEM-768 | Ratio |
|-----------|--------------|------------|-------|
| Public key | 65 bytes | 1,184 bytes | ~18x |
| Ciphertext | 65 bytes | 1,088 bytes | ~17x |
| Shared secret | 32 bytes | 32 bytes | 1x |

*The shared secret size is the same — only the exchange is larger.*

## When to Act

```
Data Sensitivity Lifetime    Action Required
─────────────────────────    ───────────────
< 5 years                    Monitor, plan migration
5-10 years                   Begin hybrid deployment
10-25 years                  Urgent: Deploy PQC now
> 25 years                   Critical: Should already have PQC
```

## What You Learned

1. **SNDL is real:** Adversaries record encrypted traffic today
2. **Timing matters:** Your data's sensitivity lifetime determines urgency
3. **ML-KEM is ready:** NIST FIPS 203 standard is finalized
4. **Hybrid is safe:** Use both classical and PQC during transition

## The Mosca Inequality

Michele Mosca's formula helps determine urgency:

```
If X + Y > Z, then worry now.

Where:
  X = Years until cryptanalytically relevant quantum computer exists
  Y = Time to migrate your systems to PQC
  Z = How long your data needs to stay secret
```

**Example:**
- Quantum computers in 10-15 years (X = 10)
- Migration takes 5-7 years (Y = 5)
- Medical records need 50 years of secrecy (Z = 50)

X + Y = 15 < 50 = Z → **Act now!**

## Related Use Cases

- **Certificate comparison:** [UC-01: Classical vs PQC TLS](../01-classic-vs-pqc-tls/)
- **Hybrid approach:** [UC-02: Hybrid Certificates](../02-hybrid-cert/)
- **Long-term signatures:** [UC-06: Code Signing](../06-code-signing/)

## References

- [NIST FIPS 203: ML-KEM Standard](https://csrc.nist.gov/pubs/fips/203/final)
- [Mosca's Theorem](https://globalriskinstitute.org/publication/quantum-threat-timeline/)
- [NSA CNSA 2.0 Guidelines](https://media.defense.gov/2022/Sep/07/2003071834/-1/-1/0/CSA_CNSA_2.0_ALGORITHMS_.PDF)

---

**Need help assessing your SNDL risk?** Contact [QentriQ](https://qentriq.com)
