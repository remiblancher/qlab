# PQC Tunnel: Secure the Tunnel

## ML-KEM: Post-Quantum Key Exchange

> **Key Message:** ML-KEM provides quantum-resistant key exchange. Combined with ML-DSA, you get full PQC tunnel protection.

---

## The Problem

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

---

## The Threat

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

---

## The Solution: ML-KEM (Key Encapsulation Mechanism)

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
| **Standard** | FIPS 204 | FIPS 203 |
| **Usage** | Signatures | Key exchange |
| **Goal** | AUTHENTICITY | CONFIDENTIALITY |
| **Operations** | Sign / Verify | Encaps / Decaps |
| **TLS** | Server authentication | Session establishment |
| **Certificate** | keyUsage: digitalSignature | keyUsage: keyEncipherment |

---

## What This Demo Shows

| Step | What Happens | Key Concept |
|------|--------------|-------------|
| 1 | Explain ML-DSA vs ML-KEM | Different purposes |
| 2 | KEM workflow | Encapsulate / Decapsulate |
| 3 | Create KEM CA | ML-DSA-65 for signing |
| 4 | Create tunnel endpoint certificate | ML-DSA + ML-KEM |
| 5 | Explain hybrid KEM | X25519 + ML-KEM-768 |
| 6 | Size comparison | Key and ciphertext sizes |

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

## Run the Demo

```bash
./demo.sh
```

---

## The Commands

### Step 1: Create KEM Demo CA

```bash
# Create CA with ML-DSA-65 for signing
pki ca init --name "KEM Demo CA" \
    --profile profiles/pqc-ca.yaml \
    --dir output/kem-ca
```

### Step 2: Create Tunnel Endpoint Certificate

```bash
# Certificate with ML-DSA + ML-KEM
pki cert issue --ca-dir output/kem-ca \
    --profile profiles/pqc-tunnel-endpoint.yaml \
    --cn "tunnel.example.com" \
    --dns tunnel.example.com \
    --out output/tunnel.crt \
    --key-out output/tunnel.key
```

---

## ML-KEM Sizes

| Level | Public key | Private key | Ciphertext | Secret |
|-------|------------|-------------|------------|--------|
| ML-KEM-512 | 800 bytes | 1,632 bytes | 768 bytes | 32 bytes |
| ML-KEM-768 | 1,184 bytes | 2,400 bytes | 1,088 bytes | 32 bytes |
| ML-KEM-1024 | 1,568 bytes | 3,168 bytes | 1,568 bytes | 32 bytes |

**Comparison**: X25519 = 32 bytes public key, 32 bytes ciphertext

---

## Real-World Deployments

| Platform | Status |
|----------|--------|
| Chrome/Firefox | Hybrid KEM in TLS 1.3 |
| OpenSSH 9.0+ | sntrup761x25519-sha512 |
| Signal Protocol | PQXDH with ML-KEM |
| Cloudflare | Hybrid KEM enabled |
| AWS/Google Cloud | PQC key exchange available |

---

## What You Learned

1. **ML-KEM** protects confidentiality (key exchange)
2. **ML-DSA** protects authenticity (signatures)
3. For a secure tunnel, you need **BOTH** algorithms
4. **Hybrid KEM** (X25519 + ML-KEM) provides defense in depth
5. Already deployed in major browsers and protocols

---

## References

- [NIST FIPS 203: ML-KEM Standard](https://csrc.nist.gov/pubs/fips/203/final)
- [NIST FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)
- [RFC 9180: Hybrid Public Key Encryption](https://tools.ietf.org/html/rfc9180)
- [Cloudflare Post-Quantum](https://blog.cloudflare.com/post-quantum-for-all/)

---

← [mTLS](../11-mtls/) | Journey Complete!
