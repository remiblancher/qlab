# PQC CMS Encryption: For Your Eyes Only

## Post-Quantum Document Encryption with ML-KEM + CSR Attestation

> **Key Message:** You cannot prove possession of a KEM key by signing! Use a signing certificate to attest for encryption keys (RFC 9883).

---

## The Scenario

*"We need to send confidential documents to partners. How do we ensure only they can read them, even if quantum computers become available?"*

Document encryption is essential for:
- **Confidential emails** (S/MIME)
- **HR documents** (salaries, evaluations)
- **Medical records** (patient data)
- **Legal contracts** (pre-signature)
- **Encrypted backups** (offline protection)

Classical encryption (RSA, ECDH) will be broken by quantum computers. We need quantum-safe encryption today for documents that must remain confidential for years.

---

## The KEM Key Problem (RFC 9883)

Traditional CSR workflow:
1. Generate key pair
2. Create CSR and **sign it** with the private key
3. CA verifies signature = proof of possession

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  THE PROBLEM WITH KEM KEYS                                       │
│                                                                  │
│  ML-KEM keys can only:                                           │
│    ✓ Encapsulate (encrypt a shared secret)                       │
│    ✓ Decapsulate (decrypt a shared secret)                       │
│                                                                  │
│  ML-KEM keys CANNOT:                                             │
│    ✗ Sign data                                                   │
│    ✗ Create digital signatures                                   │
│    ✗ Prove possession via CSR signature!                         │
│                                                                  │
│  Solution: Use a SIGNING certificate to attest for the KEM key   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## The Solution: CSR Attestation (RFC 9883)

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  CSR ATTESTATION WORKFLOW                                        │
│                                                                  │
│    Step 1: Alice gets SIGNING certificate (ML-DSA-65)            │
│                                                                  │
│    Step 2: Alice generates ML-KEM key pair locally               │
│                                                                  │
│    Step 3: Alice creates CSR for encryption key                  │
│            → CSR is signed by her SIGNING key (attestation)      │
│                                                                  │
│    Step 4: CA verifies:                                          │
│            → CSR signature is valid                              │
│            → Signing certificate is trusted                      │
│            → Issues encryption cert with RelatedCertificate      │
│                                                                  │
│    Result: Alice has TWO linked certificates                     │
│            → Signing: ML-DSA-65 (for authentication)             │
│            → Encryption: ML-KEM-768 (for key encapsulation)      │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## What This Demo Shows

| Step | What Happens | Key Concept |
|------|--------------|-------------|
| 1 | Explain KEM key problem | Why KEM keys can't sign CSRs |
| 2 | Create Encryption CA | ML-DSA-65 for signing |
| 3 | Generate signing CSR | ML-DSA can sign its own CSR |
| 4 | Issue signing certificate | ML-DSA-65 for attestation |
| 5 | Create CSR for encryption key | Signed by signing key (RFC 9883) |
| 6 | CA issues encryption certificate | ML-KEM-768 + RelatedCertificate |
| 7 | Show certificate pair | Two linked certificates |
| 8 | CMS encryption flow | Hybrid encryption (AES + ML-KEM) |
| 9 | Why hybrid encryption? | AES speed + ML-KEM quantum safety |

---

## Run the Demo

```bash
./demo.sh
```

---

## The Commands

### Step 1: Create Encryption CA

```bash
qpki ca init --profile profiles/pqc-ca.yaml \
    --var cn="Encryption CA" \
    --ca-dir output/encryption-ca
```

### Step 2: Generate Signing CSR (ML-DSA-65)

```bash
# Generate ML-DSA-65 key pair and CSR
# CSR is self-signed (proof of possession)
qpki csr gen --algorithm ml-dsa-65 \
    --keyout output/alice-sign.key \
    --cn "Alice" \
    -o output/alice-sign.csr
```

### Step 3: Issue Signing Certificate

```bash
# CA verifies CSR signature and issues certificate
qpki cert issue --ca-dir output/encryption-ca \
    --profile profiles/pqc-signing.yaml \
    --csr output/alice-sign.csr \
    --out output/alice-sign.crt
```

### Step 4: Create CSR for Encryption Key (RFC 9883 Attestation)

```bash
# Generate ML-KEM key and create CSR
# CSR is signed by Alice's SIGNING key (attestation)
qpki csr gen --algorithm ml-kem-768 \
    --keyout output/alice-enc.key \
    --cn "Alice" \
    --attest-cert output/alice-sign.crt \
    --attest-key output/alice-sign.key \
    -o output/alice-enc.csr
```

### Step 5: CA Issues Encryption Certificate

```bash
# CA verifies attestation and issues certificate
# Certificate includes RelatedCertificate extension
qpki cert issue --ca-dir output/encryption-ca \
    --csr output/alice-enc.csr \
    --profile profiles/pqc-encryption.yaml \
    --attest-cert output/alice-sign.crt \
    --out output/alice-enc.crt
```

---

## Alice's Certificate Pair

```
┌─────────────────────────────────────────────────────────────────────┐
│  ALICE'S CERTIFICATE PAIR                                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────┐   ┌─────────────────────────────┐ │
│  │  SIGNING CERTIFICATE        │   │  ENCRYPTION CERTIFICATE     │ │
│  ├─────────────────────────────┤   ├─────────────────────────────┤ │
│  │  Algorithm: ML-DSA-65       │   │  Algorithm: ML-KEM-768      │ │
│  │  Key Usage: digitalSignature│   │  Key Usage: keyEncipherment │ │
│  │  File: alice-sign.crt       │   │  File: alice-enc.crt        │ │
│  │  Purpose: Sign, Attest      │   │  Purpose: Receive encrypted │ │
│  └─────────────────────────────┘   └─────────────────────────────┘ │
│            │                                      ▲                 │
│            │         RelatedCertificate           │                 │
│            └──────────────────────────────────────┘                 │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## CMS EnvelopedData Structure

```
┌─────────────────────────────────────────────────────────────────────┐
│  CMS EnvelopedData (RFC 5652)                                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  KEMRecipientInfo (for ML-KEM)                                │ │
│  ├───────────────────────────────────────────────────────────────┤ │
│  │  • Recipient ID (issuer + serial)                             │ │
│  │  • KEM Algorithm: ML-KEM-768                                  │ │
│  │  • KEM Ciphertext: ~1,088 bytes                               │ │
│  │  • KDF: HKDF-SHA256                                           │ │
│  │  • Key Wrap: AES-256-WRAP                                     │ │
│  │  • Wrapped Key: 40 bytes                                      │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  EncryptedContentInfo                                         │ │
│  ├───────────────────────────────────────────────────────────────┤ │
│  │  • Content Type: id-data                                      │ │
│  │  • Algorithm: AES-256-GCM                                     │ │
│  │  • Encrypted Content: [ciphertext + GCM tag]                  │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Why Hybrid Encryption?

| Approach | Speed | Ciphertext Size | Quantum-Safe | Verdict |
|----------|-------|-----------------|--------------|---------|
| ML-KEM only | Slow | Large | Yes | Not practical for large files |
| AES only | Fast | Small | Yes* | Can't share key securely |
| **AES + ML-KEM** | Fast | Small + ~1KB | Yes | **Best of both worlds** |

*AES is quantum-resistant but requires secure key exchange.

---

## Use Cases

| Scenario | Application | Why PQC? |
|----------|------------|----------|
| **Secure Email** | S/MIME (Outlook, Thunderbird) | Emails may be archived for years |
| **HR Documents** | Salaries, performance reviews | Employee data is sensitive |
| **Medical Records** | HIPAA compliance | 50+ year retention requirements |
| **Legal Contracts** | Pre-signature confidentiality | Business secrets |
| **Encrypted Backups** | Offline archives | Long-term protection |

---

## Algorithm Details

### ML-DSA-65 (Signing)

| Property | Value |
|----------|-------|
| NIST Standard | FIPS 204 |
| Security Level | NIST Level 3 (~192-bit classical) |
| Public Key | ~1,952 bytes |
| Signature | ~3,309 bytes |
| Purpose | CSR attestation, message signing |

### ML-KEM-768 (Key Encapsulation)

| Property | Value |
|----------|-------|
| NIST Standard | FIPS 203 |
| Security Level | NIST Level 3 (~192-bit classical) |
| Public Key | 1,184 bytes |
| Ciphertext | 1,088 bytes |
| Shared Secret | 32 bytes |

### AES-256-GCM (Content Encryption)

| Property | Value |
|----------|-------|
| Key Size | 256 bits |
| Mode | Galois/Counter Mode (GCM) |
| Authentication | Built-in (AEAD) |
| IV Size | 12 bytes |
| Tag Size | 16 bytes |

---

## What You Learned

1. **KEM keys cannot sign** - ML-KEM can only encapsulate/decapsulate
2. **CSR attestation** - Use a signing certificate to attest for KEM keys (RFC 9883)
3. **RelatedCertificate** - Links encryption and signing certificates
4. **Hybrid encryption** - AES (fast) + ML-KEM (quantum-safe)
5. **CMS EnvelopedData** - Industry standard for document encryption
6. **S/MIME pattern** - Separate signing and encryption certificates
7. **Next step:** You now have signing and encryption certificates. How do you migrate them to new algorithms over time? See [Crypto-Agility](../10-crypto-agility/)

---

## References

- [RFC 9883: Use of Post-Quantum KEM in CMS](https://datatracker.ietf.org/doc/html/rfc9883)
- [NIST FIPS 203: ML-KEM Standard](https://csrc.nist.gov/pubs/fips/203/final)
- [NIST FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)
- [RFC 5652: Cryptographic Message Syntax (CMS)](https://datatracker.ietf.org/doc/html/rfc5652)
- [RFC 5751: S/MIME Version 3.2](https://datatracker.ietf.org/doc/html/rfc5751)

---

← [PQC LTV Signatures](../08-ltv-signatures/) | [Next: Crypto-Agility →](../10-crypto-agility/)
