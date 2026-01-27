# PQC Code Signing: Signatures That Outlive the Threat

## Post-Quantum Code Signing with ML-DSA

> **Key Message:** Software signatures must remain valid for years. PQC ensures they can't be forged by future quantum computers.

---

## The Scenario

*"We sign our software releases. How long do those signatures need to be valid? And what happens when quantum computers can forge classical signatures?"*

Code signatures are **long-lived**. A signed binary from 2024 might still be verified in 2034. If quantum computers can forge ECDSA signatures by then, attackers could create malicious software that appears legitimately signed.

```
TODAY                           FUTURE (5-15 years?)
─────                           ────────────────────

  You sign software               Attacker with quantum computer
       │                                  │
       │ ECDSA signature                  │ Breaks ECDSA
       │                                  │
       ▼                                  ▼
  Signed binary ────────────────► Forges valid signature
  (still in use)                  on malicious binary
                                          │
                                          ▼
                                  "Legitimate" malware
                                  passes verification
```

---

## The Problem

```
WITHOUT CODE SIGNING
────────────────────

   Developer                    Attacker                    Client
       │                              │                           │
       │  firmware.bin                │                           │
       │  ────────────────────────────┼──────────────────────────►│
       │                              │                           │
       │                              │  firmware.bin (modified)  │
       │                              │  ──────────────────────►  │
       │                              │                           │
       │                              │                           ▼
       │                              │                    ┌──────────────┐
       │                              │                    │  Which one   │
       │                              │                    │  is real?    │
       │                              │                    └──────────────┘
```

---

## The Threat

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  SUPPLY CHAIN ATTACK: Modify code in transit                    │
│                                                                  │
│                                                                  │
│    Developer                                                     │
│        │                                                         │
│        │  firmware.bin (original)                                │
│        ▼                                                         │
│    ┌──────────┐                                                  │
│    │  Mirror  │ ◄──── Attacker injects malware                  │
│    │  Server  │                                                  │
│    └──────────┘                                                  │
│        │                                                         │
│        │  firmware.bin (compromised)                             │
│        ▼                                                         │
│    ┌──────────┐                                                  │
│    │  Client  │  Installs the firmware                          │
│    │          │  without knowing it's                           │
│    │          │  been modified                                  │
│    └──────────┘                                                  │
│                                                                  │
│  Real-world examples:                                            │
│  - SolarWinds (2020): malware injected in an update             │
│  - CodeCov (2021): build script compromised                     │
│  - 3CX (2023): supply chain of a supply chain                   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## The Solution: Code Signing

Sign the code BEFORE distributing it:

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  WITH CODE SIGNING                                               │
│                                                                  │
│    Developer                                                     │
│        │                                                         │
│        │  1. Signs firmware.bin with ML-DSA                      │
│        ▼                                                         │
│    ┌─────────────────────────────────┐                          │
│    │  firmware.bin                   │                          │
│    │  + firmware.bin.p7s (signature) │                          │
│    │  + signing.crt (certificate)    │                          │
│    └─────────────────────────────────┘                          │
│        │                                                         │
│        ▼                                                         │
│    ┌──────────┐                                                  │
│    │  Client  │  2. Verifies the signature                      │
│    │          │                                                  │
│    │          │  ✓ Hash matches                                 │
│    │          │  ✓ Signature valid                              │
│    │          │  ✓ Certificate in the chain                     │
│    │          │                                                  │
│    │          │  → Installation authorized                      │
│    └──────────┘                                                  │
│                                                                  │
│  If the firmware is modified:                                    │
│  ❌ Hash doesn't match → Signature invalid → REJECTED           │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## What a Signature Guarantees

| Property | Meaning |
|----------|---------|
| **Integrity** | The file hasn't been modified |
| **Authenticity** | It really comes from the publisher |
| **Non-repudiation** | The publisher can't deny signing it |

---

## What We'll Do

| Aspect | Classical (ECDSA) | Post-Quantum (ML-DSA) |
|--------|-------------------|----------------------|
| Signature algorithm | ECDSA P-384 | ML-DSA-65 |
| Signature size | ~96 bytes | ~3,309 bytes |
| Future-proof | No | Yes |
| Verification speed | Fast | Fast |

---

## Run the Demo

```bash
./journey/06-code-signing/demo.sh
```

---

## The Commands

### Step 1: Create Code Signing CA

```bash
# Create a PQC CA for code signing
qpki ca init --profile profiles/pqc-ca.yaml \
    --var cn="Code Signing CA" \
    --ca-dir output/code-ca
```

### Step 2: Issue Code Signing Certificate

```bash
# Generate key and CSR
qpki csr gen --algorithm ml-dsa-65 \
    --keyout output/code-signing.key \
    --cn "ACME Software" \
    --out output/code-signing.csr

# Issue certificate from CSR
qpki cert issue --ca-dir output/code-ca \
    --profile profiles/pqc-code-signing.yaml \
    --csr output/code-signing.csr \
    --out output/code-signing.crt
```

### Step 3: Sign a Binary

```bash
# Create a test firmware
dd if=/dev/urandom of=output/firmware.bin bs=1024 count=100

# Sign with PQC (CMS/PKCS#7 format)
qpki cms sign --data output/firmware.bin \
    --cert output/code-signing.crt \
    --key output/code-signing.key \
    --out output/firmware.p7s
```

### Step 4: Verify the Signature

```bash
# Verify signature against original binary
qpki cms verify output/firmware.p7s \
    --data output/firmware.bin
# Result: VALID
```

### Step 5: Tamper and Verify Again

```bash
# Modify the firmware (simulate tampering)
echo "MALWARE" >> output/firmware.bin

# Verify again
qpki cms verify output/firmware.p7s \
    --data output/firmware.bin
# Result: INVALID - signature verification failed
```

---

## Why Code Signing Needs PQC

### Long-Lived Signatures

| Software Type | Typical Lifespan | PQC Urgency |
|--------------|------------------|-------------|
| IoT firmware | 10-20 years | **Critical** |
| Industrial control | 15-30 years | **Critical** |
| Medical devices | 10-15 years | **Critical** |
| Desktop software | 5-10 years | High |
| Mobile apps | 2-5 years | Medium |

### Attack Scenarios

1. **Firmware tampering**: Attacker forges signature on malicious firmware update
2. **Supply chain attack**: Malicious package appears legitimately signed
3. **Historical verification**: Old signatures become untrustworthy

---

## Size Comparison

| Component | Classical (ECDSA P-384) | Post-Quantum (ML-DSA-65) | Notes |
|-----------|-------------------------|--------------------------|-------|
| Public key | ~97 bytes | ~1,952 bytes | In certificate |
| Signature | ~96 bytes | ~3,309 bytes | Per signed file |
| Certificate | ~1 KB | ~6 KB | One-time distribution |

*For a 100 MB binary, the signature overhead is negligible.*

---

## Certificate Extensions

Code signing certificates have specific extensions:

| Extension | Value | Purpose |
|-----------|-------|---------|
| Extended Key Usage | `codeSigning` | Limits certificate use |
| Key Usage | `digitalSignature` | Signing operations only |
| Basic Constraints | `CA: false` | End-entity certificate |

---

## When to Adopt PQC Code Signing

| Scenario | Recommendation |
|----------|----------------|
| IoT/embedded firmware | **Now** - Long device lifespan |
| Critical infrastructure | **Now** - High-value targets |
| Enterprise software | Plan for 2025-2026 |
| Consumer apps | Can wait, but plan ahead |

---

## What You Learned

1. **Long-lived signatures**: Code signatures may be verified for 10+ years
2. **Quantum threat**: Future quantum computers could forge classical signatures
3. **PQC solution**: ML-DSA signatures remain unforgeable
4. **Size trade-off**: ~3 KB signature vs ~100 bytes (negligible for binaries)
5. **Drop-in replacement**: Same workflow, different algorithm

---

## References

- [NIST FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)
- [RFC 5652: Cryptographic Message Syntax (CMS)](https://datatracker.ietf.org/doc/html/rfc5652)

---

## What's Next?

You've proven **WHO** signed the code and that it hasn't been tampered with.

But **WHEN** was it signed? If the certificate expires, how do you prove the signature existed before expiration?

← [PQC OCSP](../05-ocsp/) | [QLAB Home](../../README.md) | [Next: Timestamping →](../07-timestamping/) — Prove WHEN documents were signed.
