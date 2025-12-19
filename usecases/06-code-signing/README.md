# UC-06: "Signatures that outlive the threat"

## Post-Quantum Code Signing

> **Key Message:** Software signatures must remain valid for years. PQC ensures they can't be forged by future quantum computers.

> **Visual diagrams:** See [`diagram.txt`](diagram.txt) for ASCII diagrams of the code signing workflow and threat model.

## The Scenario

*"We sign our software releases. How long do those signatures need to be valid? And what happens when quantum computers can forge classical signatures?"*

Code signatures are **long-lived**. A signed binary from 2024 might still be verified in 2034. If quantum computers can forge ECDSA signatures by then, attackers could create malicious software that appears legitimately signed.

## The Threat Model

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

## What This Demo Shows

| Aspect | Classical (ECDSA) | Post-Quantum (ML-DSA) |
|--------|-------------------|----------------------|
| Signature algorithm | ECDSA P-384 | ML-DSA-65 |
| Signature size | ~96 bytes | ~3,293 bytes |
| Future-proof | No | Yes |
| Verification speed | Fast | Fast |

## Run the Demo

```bash
./demo.sh
```

**Prerequisites:**
- PKI tool installed (`../../tooling/install.sh`)
- ~2 minutes of your time

## The Commands

### Step 1: Create Code Signing CA

```bash
# Create a PQC CA for code signing
pki init-ca --name "PQC Code Signing CA" \
    --algorithm ml-dsa-65 \
    --dir ./code-signing-ca

# Inspect
pki info ./code-signing-ca/ca.crt
```

### Step 2: Issue Code Signing Certificate

```bash
# Issue code signing certificate
pki issue --ca-dir ./code-signing-ca \
    --profile ml-dsa-kem/code-signing \
    --cn "ACME Software Signing" \
    --out code-signing.crt \
    --key-out code-signing.key

# Inspect
pki info code-signing.crt
```

### Step 3: Sign a Binary

```bash
# Create a test binary
echo '#!/bin/bash
echo "Hello World"' > myapp.sh

# Sign with PQC (CMS/PKCS#7 format)
pki cms sign --data myapp.sh \
    --cert code-signing.crt --key code-signing.key \
    -o myapp.sh.p7s

# Inspect the signature
pki info myapp.sh.p7s
```

### Step 4: Verify the Signature

```bash
# Verify signature against original binary
pki cms verify --signature myapp.sh.p7s \
    --data myapp.sh \
    --ca ./code-signing-ca/ca.crt
```

### Step 5: Add a Timestamp (Optional)

```bash
# Add PQC timestamp to prove when the signature was made
pki tsa sign --data myapp.sh.p7s \
    --cert code-signing.crt --key code-signing.key \
    -o myapp.sh.tsr

# Verify the timestamp
pki tsa verify --token myapp.sh.tsr \
    --data myapp.sh.p7s \
    --ca ./code-signing-ca/ca.crt
```

> **Tip:** For classical certificates, you can verify with `openssl cms -verify`

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

## Size Comparison

| Component | Classical (ECDSA P-384) | Post-Quantum (ML-DSA-65) | Notes |
|-----------|-------------------------|--------------------------|-------|
| Public key | ~97 bytes | ~1,952 bytes | In certificate |
| Signature | ~96 bytes | ~3,293 bytes | Per signed file |
| Certificate | ~1 KB | ~6 KB | One-time distribution |

*For a 100 MB binary, the signature overhead is negligible.*

## Certificate Extensions

Code signing certificates have specific extensions:

| Extension | Value | Purpose |
|-----------|-------|---------|
| Extended Key Usage | `codeSigning` | Limits certificate use |
| Key Usage | `digitalSignature` | Signing operations only |
| Basic Constraints | `CA: false` | End-entity certificate |

## What You Learned

1. **Long-lived signatures**: Code signatures may be verified for 10+ years
2. **Quantum threat**: Future quantum computers could forge classical signatures
3. **PQC solution**: ML-DSA signatures remain unforgeable
4. **Size trade-off**: ~3 KB signature vs ~100 bytes (negligible for binaries)

## When to Adopt PQC Code Signing

| Scenario | Recommendation |
|----------|----------------|
| IoT/embedded firmware | **Now** - Long device lifespan |
| Critical infrastructure | **Now** - High-value targets |
| Enterprise software | Plan for 2025-2026 |
| Consumer apps | Can wait, but plan ahead |

## Related Use Cases

- **Basic PKI comparison**: [UC-01: Classical vs PQC TLS](../01-classic-vs-pqc-tls/)
- **Long-term encryption**: [UC-03: Store Now, Decrypt Later](../03-store-now-decrypt-later/)
- **Full PQC hierarchy**: [UC-05: Full PQC PKI](../05-full-pqc-pki/)

## References

- [NIST FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)
- [RFC 5652: Cryptographic Message Syntax (CMS)](https://datatracker.ietf.org/doc/html/rfc5652)
- [Microsoft Authenticode](https://docs.microsoft.com/en-us/windows-hardware/drivers/install/authenticode)

---

**Need help securing your software supply chain?** Contact [QentriQ](https://qentriq.com)
