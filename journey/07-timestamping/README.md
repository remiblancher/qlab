# PQC Timestamping: Trust Now, Verify Forever

## Post-Quantum Timestamping with ML-DSA

> **Key Message:** Timestamps prove when documents existed. PQC ensures those proofs remain valid for decades.

---

## The Scenario

*"We need to prove that this contract was signed on this exact date. The proof must be valid for 30+ years for legal compliance. What happens when quantum computers can forge classical timestamps?"*

Timestamps are the **longest-lived** cryptographic proofs. A timestamp from 2024 might need legal validation in 2054. If quantum computers can forge the timestamp authority's signature, the proof becomes worthless.

---

## The Problem

```
TODAY                                IN 5 YEARS
─────                                ──────────

  Contract.pdf                       Contract.pdf
  + Signature                        + Signature
  ✓ Certificate valid                ❌ Certificate expired

  "This contract was                 "Was this contract
   signed on 12/15/2024"              really signed
                                      BEFORE expiration?"
```

---

## The Threat

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  PROBLEM: The signature date is not proven                      │
│                                                                  │
│                                                                  │
│    2024                              2029                        │
│      │                                 │                         │
│      │  Signature created              │  Certificate expired   │
│      │                                 │                         │
│      ▼                                 ▼                         │
│    ┌─────────┐                      ┌─────────┐                 │
│    │ Contract│                      │ Contract│                 │
│    │ signed  │                      │ signed  │                 │
│    │         │                      │         │                 │
│    │ ✓ Valid │  ────────────────►   │ ? Valid │                 │
│    └─────────┘                      └─────────┘                 │
│                                                                  │
│    Without timestamping, impossible to prove that the signature │
│    was created BEFORE the certificate expiration.               │
│                                                                  │
│    An attacker could:                                            │
│    - Backdate a signature (fraud)                               │
│    - Contest the validity of a contract                         │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## The Solution: Cryptographic Timestamping (TSA)

A trusted authority (TSA) proves when the signature was created:

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  WITH TSA TIMESTAMPING                                           │
│                                                                  │
│    1. You sign the document                                      │
│                                                                  │
│       Contract.pdf                                               │
│       + Your signature                                           │
│           │                                                      │
│           │  2. You request a timestamp                          │
│           ▼                                                      │
│       ┌───────────────────────────────────────────┐             │
│       │  TSA (Timestamp Authority)                │             │
│       │  ─────────────────────────                │             │
│       │                                           │             │
│       │  "I certify that this hash existed       │             │
│       │   on 12/15/2024 at 14:32:05 UTC"         │             │
│       │                                           │             │
│       │  + TSA Signature (ML-DSA-65)             │             │
│       │  + Certified clock                       │             │
│       └───────────────────────────────────────────┘             │
│           │                                                      │
│           ▼                                                      │
│    3. The timestamp is added to the document                    │
│                                                                  │
│       Contract.pdf                                               │
│       + Your signature                                           │
│       + TSA timestamp                                            │
│                                                                  │
│    VERIFICATION IN 2029:                                         │
│    ✓ The signature existed on 12/15/2024                        │
│    ✓ It was BEFORE the certificate expiration                   │
│    ✓ The document is still valid                                │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## What This Demo Shows

| Step | What Happens | Expected Result |
|------|--------------|-----------------|
| 1 | Create TSA CA and certificate | TSA with ML-DSA-65 |
| 2 | Timestamp a document | Timestamp token (.tsr) |
| 3 | Verify the timestamp | Status: VALID |
| 4 | Tamper and verify again | Status: INVALID |

---

## Run the Demo

```bash
./demo.sh
```

---

## The Commands

### Step 1: Create TSA CA and Certificate

```bash
# Create a PQC CA for timestamp authority
pki ca init --name "TSA Root CA" \
    --profile profiles/pqc-ca.yaml \
    --dir output/tsa-ca

# Issue TSA certificate (EKU: timeStamping)
pki cert issue --ca-dir output/tsa-ca \
    --profile profiles/tsa.yaml \
    --cn "PQC Timestamp Authority" \
    --out output/tsa.crt \
    --key-out output/tsa.key
```

### Step 2: Timestamp a Document

```bash
# Create a test document
echo "Contract content - signed on $(date)" > output/document.txt

# Timestamp with PQC (RFC 3161)
pki tsa sign --data output/document.txt \
    --cert output/tsa.crt \
    --key output/tsa.key \
    -o output/document.tsr
```

### Step 3: Verify the Timestamp

```bash
# Verify token against original document
pki tsa verify --token output/document.tsr \
    --data output/document.txt \
    --ca output/tsa-ca/ca.crt
# Result: VALID
```

### Step 4: Tamper and Verify Again

```bash
# Modify the document (simulate fraud)
echo "FRAUDULENT MODIFICATION" >> output/document.txt

# Verify again
pki tsa verify --token output/document.tsr \
    --data output/document.txt \
    --ca output/tsa-ca/ca.crt
# Result: INVALID - document modified after timestamping
```

---

## How It Works Technically

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  TIMESTAMPING WORKFLOW (RFC 3161)                              │
│                                                                 │
│  1. CLIENT                                                      │
│     ────────                                                    │
│     hash = SHA-512(document)                                    │
│     request = TimeStampReq(hash)                                │
│                                                                 │
│  2. TSA                                                         │
│     ────                                                        │
│     clock = certified_time()                                    │
│     token = {                                                   │
│       hash: received_hash,                                      │
│       time: "2024-12-15T14:32:05Z",                            │
│       tsa: "PQC Timestamp Authority",                           │
│       serial: 123456                                            │
│     }                                                           │
│     signature = ML-DSA.Sign(token, tsa_key)                     │
│                                                                 │
│  3. RESULT                                                      │
│     ─────────                                                   │
│     TimeStampResp = token + signature                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Why Timestamping Needs PQC

### Ultra-Long Validation Periods

| Document Type | Retention Period | PQC Urgency |
|--------------|------------------|-------------|
| Legal contracts | 30+ years | **Critical** |
| Patents | 20+ years | **Critical** |
| Medical records | Lifetime + 7 years | **Critical** |
| Financial audits | 10-15 years | High |
| Tax records | 7-10 years | High |
| AI model training logs | 10+ years | **Critical** |

### Attack Scenarios

1. **Contract backdating**: Attacker creates forged timestamp proving contract existed before it did
2. **Patent priority fraud**: Fake timestamps to claim earlier invention date
3. **Audit manipulation**: Forge timestamps on financial records
4. **AI training data**: Prove training data existed before certain dates (regulatory compliance)

---

## Size Comparison

| Component | Classical (ECDSA P-384) | Post-Quantum (ML-DSA-65) | Notes |
|-----------|-------------------------|--------------------------|-------|
| TSA public key | ~97 bytes | ~1,952 bytes | In certificate |
| Timestamp signature | ~96 bytes | ~3,293 bytes | Per document |
| Token overhead | ~2-3 KB | ~6-8 KB | Includes cert chain |

*For a 10 MB PDF, the timestamp overhead is negligible.*

---

## Certificate Extensions

TSA certificates have specific extensions:

| Extension | Value | Purpose |
|-----------|-------|---------|
| Extended Key Usage | `timeStamping` | Limits to TSA use only |
| Key Usage | `digitalSignature` | Signing operations |
| Basic Constraints | `CA: false` | End-entity certificate |

---

## Long-Term Validation (LTV)

For timestamps to remain valid for decades:

```
┌─────────────────────────────────────────────────────────────────┐
│  LONG-TERM VALIDATION CHAIN                                     │
│                                                                 │
│  Document → Timestamp Token → TSA Certificate → CA Certificate  │
│                   │                  │                │         │
│                   │                  │                │         │
│                   ▼                  ▼                ▼         │
│              PQC Signature      PQC Signature    PQC Signature  │
│              (ML-DSA-65)        (ML-DSA-65)      (ML-DSA-65)    │
│                                                                 │
│  ALL signatures must be quantum-resistant for LTV!              │
└─────────────────────────────────────────────────────────────────┘
```

---

## What You Learned

1. **Ultra-long validity**: Timestamps may be verified 30+ years later
2. **Quantum threat**: Future quantum computers could forge timestamp signatures
3. **PQC solution**: ML-DSA signatures ensure timestamps remain unforgeable
4. **Compliance**: Legal, financial, and regulatory requirements demand PQC

---

## When to Adopt PQC Timestamping

| Scenario | Recommendation |
|----------|----------------|
| Legal/compliance | **Now** - 30+ year retention |
| Patents/IP | **Now** - Priority disputes |
| Financial audit | **Now** - Regulatory requirements |
| AI/ML training logs | **Now** - Emerging regulations |
| General archival | Plan for 2025-2026 |

---

## References

- [RFC 3161: Time-Stamp Protocol (TSP)](https://datatracker.ietf.org/doc/html/rfc3161)
- [ETSI TS 101 861: Time stamping profile](https://www.etsi.org/deliver/etsi_ts/101800_101899/101861/)
- [NIST FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)

---

← [PQC Code Signing](../06-code-signing/) | [Next: LTV Signatures →](../08-ltv-signatures/)
