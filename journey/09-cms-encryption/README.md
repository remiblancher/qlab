# PQC CMS Encryption: For Your Eyes Only

## Post-Quantum Document Encryption with ML-KEM

> **Key Message:** Hybrid encryption (AES + ML-KEM) protects documents from both current and future quantum threats.

> **Note:** This is a conceptual demo. The `pki cms encrypt/decrypt` commands are being finalized. The demo explains the architecture and shows what the workflow will look like.

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

## The Problem

```
UNENCRYPTED DOCUMENT TRANSMISSION
─────────────────────────────────

   Sender                    Attacker                    Recipient
      │                          │                           │
      │  secret.doc              │                           │
      │  ─────────────────────────────────────────────────►  │
      │                          │                           │
      │                          │  ◄── Intercept & Copy     │
      │                          │                           │
      │                          ▼                           │
      │                    ┌──────────┐                      │
      │                    │  Attacker │                     │
      │                    │  has full │                     │
      │                    │  access!  │                     │
      │                    └──────────┘                      │
```

---

## The Threat

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  STORE NOW, DECRYPT LATER (SNDL)                                │
│                                                                  │
│                                                                  │
│    TODAY                         FUTURE (5-15 years?)           │
│      │                                    │                     │
│      │  Document encrypted                │  Quantum computer   │
│      │  with RSA/ECDH                     │  breaks RSA/ECDH    │
│      │                                    │                     │
│      ▼                                    ▼                     │
│  ┌──────────────┐                  ┌──────────────┐             │
│  │   Attacker   │                  │   Attacker   │             │
│  │   stores     │  ─────────────►  │   decrypts   │             │
│  │   encrypted  │                  │   everything │             │
│  │   traffic    │                  │              │             │
│  └──────────────┘                  └──────────────┘             │
│                                                                  │
│  Medical records, trade secrets, personal data                   │
│  → All exposed retroactively                                     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## The Solution: CMS Encryption with ML-KEM

CMS (Cryptographic Message Syntax) EnvelopedData provides hybrid encryption:

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  ENCRYPTION PROCESS                                              │
│                                                                  │
│    1. Generate random AES-256 key (Content Encryption Key)       │
│                                                                  │
│    2. Encrypt document with AES-256-GCM                          │
│       ┌────────────────┐    AES-256-GCM    ┌────────────────┐   │
│       │  secret.doc    │ ────────────────► │  encrypted     │   │
│       │  (plaintext)   │                   │  content       │   │
│       └────────────────┘                   └────────────────┘   │
│                                                                  │
│    3. Encapsulate AES key with ML-KEM (recipient's public key)   │
│       ┌────────────────┐    ML-KEM-768    ┌────────────────┐    │
│       │  AES-256 key   │ ────────────────► │  encapsulated  │   │
│       │  (32 bytes)    │                   │  key           │   │
│       └────────────────┘                   └────────────────┘   │
│                                                                  │
│    4. Package as CMS EnvelopedData (.p7m)                        │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
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

## What This Demo Shows

| Step | What Happens | Key Concept |
|------|--------------|-------------|
| 1 | Explain CMS envelope | Hybrid encryption architecture |
| 2 | Create Encryption CA | ML-DSA-65 for signing |
| 3 | Issue encryption certificate | ML-KEM-768 for key encapsulation |
| 4 | Encrypt document | AES-256-GCM + ML-KEM encapsulation |
| 5 | Decrypt document | ML-KEM decapsulation + AES decryption |

---

## Run the Demo

```bash
./demo.sh
```

---

## The Commands

### Step 1: Create Encryption CA

```bash
# Create a PQC CA for encryption certificates
pki init-ca --name "Encryption CA" \
    --algorithm ml-dsa-65 \
    --dir output/encryption-ca
```

### Step 2: Issue Encryption Certificate

```bash
# Issue certificate with ML-KEM encryption key
pki issue --ca-dir output/encryption-ca \
    --profile ml-dsa-kem/email \
    --cn "Alice" \
    --out output/alice.crt \
    --key-out output/alice.key
```

The `ml-dsa-kem/email` profile issues:
- **Signing certificate**: ML-DSA-65 (for authentication)
- **Encryption certificate**: ML-KEM-768 (for key encapsulation)

### Step 3: Encrypt Document

```bash
# Encrypt for Alice using her ML-KEM certificate
pki cms encrypt \
    --recipient output/alice.crt \
    --in secret-document.txt \
    --out secret-document.p7m
```

### Step 4: Decrypt Document

```bash
# Alice decrypts with her ML-KEM private key
pki cms decrypt \
    --key output/alice.key \
    --in secret-document.p7m \
    --out secret-decrypted.txt
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

## Size Comparison

| Component | Classical (RSA-2048) | Post-Quantum (ML-KEM-768) | Notes |
|-----------|---------------------|---------------------------|-------|
| Public key | ~256 bytes | ~1,184 bytes | In certificate |
| Encapsulated key | ~256 bytes | ~1,088 bytes | Per recipient |
| Overhead per file | ~300 bytes | ~1,200 bytes | Negligible for docs |

*For a 1 MB document, the overhead is < 0.1%*

---

## Algorithm Details

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

1. **CMS EnvelopedData** is the standard for document encryption (RFC 5652)
2. **Hybrid encryption** combines AES (fast) with ML-KEM (quantum-safe)
3. **ML-KEM-768** provides NIST Level 3 security for key encapsulation
4. **Only the recipient** with the ML-KEM private key can decrypt
5. **S/MIME** uses this exact pattern for secure email
6. **SNDL threat** makes PQC encryption essential today

---

## References

- [NIST FIPS 203: ML-KEM Standard](https://csrc.nist.gov/pubs/fips/203/final)
- [RFC 5652: Cryptographic Message Syntax (CMS)](https://datatracker.ietf.org/doc/html/rfc5652)
- [RFC 5751: S/MIME Version 3.2](https://datatracker.ietf.org/doc/html/rfc5751)

---

← [PQC LTV Signatures](../08-ltv-signatures/) | [Next: Crypto-Agility →](../10-crypto-agility/)
