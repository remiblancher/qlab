# Mission 10: "Secure the Tunnel"

## ML-KEM: Post-Quantum Key Exchange

### The Problem

You want to establish a secure connection with Bob.
You need a **shared secret** to encrypt the communication.

But how do you share a secret over an insecure channel?

```
TODAY: ECDH (Diffie-Hellman on elliptic curves)
───────────────────────────────────────────────

Alice                                           Bob
  │                                               │
  │  g^a (Alice's public key)                     │
  │  ─────────────────────────────────────────►   │
  │                                               │
  │  g^b (Bob's public key)                       │
  │  ◄─────────────────────────────────────────   │
  │                                               │
  │                                               │
  ▼                                               ▼
g^(ab) = Shared secret                   g^(ab) = Shared secret


PROBLEM: A quantum computer can calculate 'a' from g^a
         → The secret is retroactively compromised (SNDL)
```

### The Threat

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  SNDL applied to key exchange                                   │
│                                                                  │
│                                                                  │
│    TODAY                              IN 15 YEARS               │
│                                                                  │
│    Alice ◄────────────► Bob            Quantum computer         │
│          ECDH                                │                   │
│           │                                  │                   │
│           │                                  ▼                   │
│           │                          Breaks ECDH                │
│           ▼                                  │                   │
│    Adversary captures                        │                   │
│    public keys                               ▼                   │
│    g^a and g^b                         Calculates shared        │
│           │                            secret g^(ab)            │
│           │                                  │                   │
│           └──────────────────────────────────┘                  │
│                                                                  │
│    → Decrypts ALL traffic captured 15 years ago                 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### The Solution: ML-KEM (Key Encapsulation Mechanism)

ML-KEM works differently: **encapsulation** instead of exchange.

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  ML-KEM: Key encapsulation                                      │
│                                                                  │
│                                                                  │
│  1. Bob has an ML-KEM key pair                                  │
│                                                                  │
│     ┌─────────────────┐                                         │
│     │  Bob            │                                         │
│     │  ───            │                                         │
│     │  pk (public)    │  ←── Published (certificate)           │
│     │  sk (private)   │  ←── Kept secret                       │
│     └─────────────────┘                                         │
│                                                                  │
│  2. Alice encapsulates a secret                                  │
│                                                                  │
│     Alice                                                        │
│       │                                                          │
│       │  Encaps(pk_bob)                                         │
│       │  ─────────────                                          │
│       ▼                                                          │
│     ┌─────────────────────────────────────────┐                 │
│     │  Result:                                 │                 │
│     │  - ciphertext (sent to Bob)             │                 │
│     │  - shared_secret (kept by Alice)        │                 │
│     └─────────────────────────────────────────┘                 │
│                                                                  │
│  3. Bob decapsulates                                             │
│                                                                  │
│     Bob                                                          │
│       │                                                          │
│       │  Decaps(sk_bob, ciphertext)                             │
│       │  ──────────────────────────                             │
│       ▼                                                          │
│     ┌─────────────────────────────────────────┐                 │
│     │  Result:                                 │                 │
│     │  - shared_secret (identical to Alice's) │                 │
│     └─────────────────────────────────────────┘                 │
│                                                                  │
│  ✓ Same shared secret                                           │
│  ✓ Resistant to quantum computers                               │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## ML-DSA vs ML-KEM

| Aspect | ML-DSA | ML-KEM |
|--------|--------|--------|
| **Usage** | Signatures | Key exchange |
| **Goal** | AUTHENTICITY | CONFIDENTIALITY |
| **Operations** | Sign / Verify | Encaps / Decaps |
| **TLS** | Server authentication | Session establishment |
| **Certificate** | keyUsage: digitalSignature | keyUsage: keyEncipherment |

---

## Hybrid in Practice: X25519 + ML-KEM-768

For transition, we combine both:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  HYBRID KEM = X25519 + ML-KEM-768                              │
│                                                                 │
│                                                                 │
│  1. X25519 exchange (classic)                                  │
│     └── secret_1 = ECDH(x25519_alice, x25519_bob)              │
│                                                                 │
│  2. ML-KEM-768 encapsulation (post-quantum)                    │
│     └── secret_2, ciphertext = Encaps(mlkem_bob_pk)            │
│                                                                 │
│  3. Combined derivation                                         │
│     └── final_secret = KDF(secret_1 || secret_2)               │
│                                                                 │
│                                                                 │
│  Security:                                                      │
│  - If X25519 is broken → ML-KEM protects                       │
│  - If ML-KEM is broken → X25519 protects                       │
│  - Both must be broken simultaneously                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## What You'll Do

1. **Generate an ML-KEM-768 pair** for Bob
2. **Create a KEM certificate** (keyUsage: keyEncipherment)
3. **Encapsulate a secret** with Bob's public key
4. **Decapsulate** and verify the secret is identical
5. **Compare sizes**: X25519 vs ML-KEM-768

---

## ML-KEM Sizes

| Level | Public key | Private key | Ciphertext | Secret |
|-------|------------|-------------|------------|--------|
| ML-KEM-512 | 800 bytes | 1632 bytes | 768 bytes | 32 bytes |
| ML-KEM-768 | 1184 bytes | 2400 bytes | 1088 bytes | 32 bytes |
| ML-KEM-1024 | 1568 bytes | 3168 bytes | 1568 bytes | 32 bytes |

**Comparison**: X25519 = 32 bytes public key, 32 bytes ciphertext

---

## What You'll Have at the End

- ML-KEM-768 key pair
- KEM certificate
- Successful encapsulation / decapsulation
- Quantum-safe shared secret

---

## Run the Mission

```bash
./demo.sh
```

---

← [LTV Signatures](../10-ltv-signatures/) | [Next: CMS Encryption →](../12-cms-encryption/)
