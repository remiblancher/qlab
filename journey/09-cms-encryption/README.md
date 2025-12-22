# Mission 11: "Encrypt for Their Eyes Only"

## CMS Encryption with ML-KEM

### The Problem

You want to send a confidential document to Bob.
Only Bob should be able to read it.

```
SITUATION
─────────

  Alice                                           Bob
    │                                               │
    │  secret-document.pdf                          │
    │  ─────────────────────────────────────────►   │
    │                                               │
    │                                               │
    ▼                                               ▼
  How to ensure that                         How to read it
  ONLY Bob can read it?                      securely?
```

### The Threat

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  INTERCEPTION: The document is readable by everyone             │
│                                                                  │
│                                                                  │
│    Alice                    Attacker                  Bob        │
│      │                          │                        │       │
│      │  document.pdf            │                        │       │
│      │  ───────────────────────►│                        │       │
│      │                          │                        │       │
│      │                          ▼                        │       │
│      │                    ┌──────────┐                   │       │
│      │                    │  Copies  │                   │       │
│      │                    │  the doc │                   │       │
│      │                    └──────────┘                   │       │
│      │                          │                        │       │
│      │                          │  document.pdf          │       │
│      │                          │────────────────────────│       │
│      │                                                   ▼       │
│                                                                  │
│    The attacker has a copy of the document.                     │
│    They can read it, modify it, redistribute it.                │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### The Solution: CMS Encryption

Encrypt the document with Bob's public key:

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  CMS ENCRYPTION: Only Bob can decrypt                           │
│                                                                  │
│                                                                  │
│  1. ALICE ENCRYPTS                                               │
│                                                                  │
│     document.pdf                                                 │
│          │                                                       │
│          ▼                                                       │
│     ┌──────────────────────────────────────────────────────┐    │
│     │  Generate random AES-256 key                         │    │
│     │       │                                               │    │
│     │       ├────────────────────────┐                     │    │
│     │       ▼                        ▼                     │    │
│     │  Encrypt document         Encapsulate AES key        │    │
│     │  with AES-256-GCM         with ML-KEM (Bob)          │    │
│     │       │                        │                     │    │
│     │       ▼                        ▼                     │    │
│     │  Encrypted document       Encapsulated key           │    │
│     └──────────────────────────────────────────────────────┘    │
│          │                           │                           │
│          └─────────┬─────────────────┘                          │
│                    ▼                                             │
│          ┌──────────────────┐                                   │
│          │  document.p7m    │  ←── CMS file                     │
│          └──────────────────┘                                   │
│                                                                  │
│  2. BOB DECRYPTS                                                 │
│                                                                  │
│     document.p7m                                                 │
│          │                                                       │
│          ▼                                                       │
│     ┌──────────────────────────────────────────────────────┐    │
│     │  Decapsulate AES key with sk_bob (ML-KEM)            │    │
│     │       │                                               │    │
│     │       ▼                                               │    │
│     │  Decrypt document with AES-256-GCM                   │    │
│     │       │                                               │    │
│     │       ▼                                               │    │
│     │  document.pdf (original)                              │    │
│     └──────────────────────────────────────────────────────┘    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Why AES + ML-KEM?

We don't encrypt directly with ML-KEM because:
- ML-KEM is **slow** for large files
- ML-KEM produces **large ciphertexts**

We use the **hybrid scheme**:
1. AES-256 for content (fast)
2. ML-KEM to protect the AES key (quantum-safe)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  "Envelope" encryption                                         │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐     │
│  │  CMS file (.p7m)                                       │     │
│  │  ──────────────────                                    │     │
│  │                                                        │     │
│  │  ┌─────────────────────────────────────────────────┐  │     │
│  │  │  EnvelopedData                                   │  │     │
│  │  │  ─────────────                                   │  │     │
│  │  │                                                  │  │     │
│  │  │  RecipientInfo:                                  │  │     │
│  │  │    - Algo: ML-KEM-768                           │  │     │
│  │  │    - EncryptedKey: (encapsulated AES key)       │  │     │
│  │  │                                                  │  │     │
│  │  │  EncryptedContent:                               │  │     │
│  │  │    - Algo: AES-256-GCM                          │  │     │
│  │  │    - Data: (encrypted document)                 │  │     │
│  │  │                                                  │  │     │
│  │  └─────────────────────────────────────────────────┘  │     │
│  │                                                        │     │
│  └───────────────────────────────────────────────────────┘     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## CMS: S/MIME Standard

CMS (RFC 5652) is the format used by:
- **S/MIME**: Encrypted emails (Outlook, Apple Mail, Thunderbird)
- **PKCS#7**: Signatures and encryption
- **Archiving**: Confidential documents

---

## What You'll Do

1. **Create an encryption certificate** for Bob (ML-KEM-768)
2. **Prepare a document** secret.txt
3. **Encrypt** the document in CMS with Bob's public key
4. **Decrypt** with Bob's private key
5. **Verify** the content is identical

---

## Use Cases

| Scenario | Why CMS? |
|----------|----------|
| Confidential emails | S/MIME standard |
| HR documents | Salaries, evaluations |
| Medical data | Medical confidentiality |
| Contracts | Before signing |
| Encrypted backup | Offline protection |

---

## What You'll Have at the End

- Encryption certificate ML-KEM-768
- Encrypted document (secret.txt.p7m)
- Decrypted document (identical to original)
- Understanding of CMS workflow

---

## Run the Mission

```bash
./demo.sh
```

---

← [PQC Tunnel](../11-pqc-tunnel/) | [Home →](../../README.md)

---

## Congratulations!

You've completed the Post-Quantum PKI Lab!

You now master:
- Classic and post-quantum PKI
- ML-DSA signatures
- Hybrid certificates
- mTLS, Code Signing, Timestamping
- Revocation, OCSP, Crypto-Agility
- LTV, ML-KEM, CMS Encryption
