# UC-08: "Trust Now, Verify Forever"

## Post-Quantum Timestamping

> **Key Message:** Timestamps prove when documents existed. PQC ensures those proofs remain valid for decades.

> **Visual diagrams:** See [`diagram.txt`](diagram.txt) for ASCII diagrams of the timestamping workflow and long-term validation.

## The Scenario

*"We need to prove that this contract was signed on this exact date. The proof must be valid for 30+ years for legal compliance. What happens when quantum computers can forge classical timestamps?"*

Timestamps are the **longest-lived** cryptographic proofs. A timestamp from 2024 might need legal validation in 2054. If quantum computers can forge the timestamp authority's signature, the proof becomes worthless.

## The Threat Model

```
TODAY                           FUTURE (10-30 years)
─────                           ────────────────────

  Document signed                 Attacker with quantum computer
       │                                  │
       │ TSA timestamps with ECDSA        │ Breaks TSA private key
       │                                  │
       ▼                                  ▼
  Timestamp token ────────────────► Forges timestamp on
  (stored for legal)                BACKDATED document
                                          │
                                          ▼
                                  "Legitimate" proof
                                  of non-existent past
```

## What This Demo Shows

| Aspect | Classical (ECDSA) | Post-Quantum (ML-DSA) |
|--------|-------------------|----------------------|
| Signature algorithm | ECDSA P-384 | ML-DSA-65 |
| Token size | ~2-3 KB | ~6-8 KB |
| Valid for | Until quantum threat | Forever |
| Use case | Short-term | Long-term archival |

## Run the Demo

```bash
./demo.sh
```

**Prerequisites:**
- PKI tool installed (`../../tooling/install.sh`)
- ~2 minutes of your time

## The Commands

### Step 1: Create Timestamp Authority CA

```bash
# Create a PQC CA for timestamp authority
pki init-ca --name "PQC Timestamp Authority" \
    --algorithm ml-dsa-65 \
    --dir ./tsa-ca

# Inspect
pki info ./tsa-ca/ca.crt
```

### Step 2: Issue TSA Certificate

```bash
# Issue timestamp authority certificate
pki issue --ca-dir ./tsa-ca \
    --profile ml-dsa-kem/timestamping \
    --cn "ACME Timestamp Service" \
    --out tsa.crt \
    --key-out tsa.key

# Inspect
pki info tsa.crt
```

### Step 3: Create a Timestamp Token

```bash
# Create a test document
echo "Important contract content" > document.txt

# Timestamp the document with PQC
pki tsa sign --data document.txt \
    --cert tsa.crt --key tsa.key \
    -o document.tsr

# Inspect the token
pki info document.tsr
```

### Step 4: Verify the Timestamp

```bash
# Verify token against original document
pki tsa verify --token document.tsr \
    --data document.txt \
    --ca ./tsa-ca/ca.crt
```

> **Tip:** For classical TSA certificates, you can also verify with `openssl ts -verify`

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

## Size Comparison

| Component | Classical (ECDSA P-384) | Post-Quantum (ML-DSA-65) | Notes |
|-----------|-------------------------|--------------------------|-------|
| TSA public key | ~97 bytes | ~1,952 bytes | In certificate |
| Timestamp signature | ~96 bytes | ~3,293 bytes | Per document |
| Token overhead | ~2-3 KB | ~6-8 KB | Includes cert chain |

*For a 10 MB PDF, the timestamp overhead is negligible.*

## Certificate Extensions

TSA certificates have specific extensions:

| Extension | Value | Purpose |
|-----------|-------|---------|
| Extended Key Usage | `timeStamping` | Limits to TSA use only |
| Key Usage | `digitalSignature` | Signing operations |
| Basic Constraints | `CA: false` | End-entity certificate |

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

## What You Learned

1. **Ultra-long validity**: Timestamps may be verified 30+ years later
2. **Quantum threat**: Future quantum computers could forge timestamp signatures
3. **PQC solution**: ML-DSA signatures ensure timestamps remain unforgeable
4. **Compliance**: Legal, financial, and regulatory requirements demand PQC

## When to Adopt PQC Timestamping

| Scenario | Recommendation |
|----------|----------------|
| Legal/compliance | **Now** - 30+ year retention |
| Patents/IP | **Now** - Priority disputes |
| Financial audit | **Now** - Regulatory requirements |
| AI/ML training logs | **Now** - Emerging regulations |
| General archival | Plan for 2025-2026 |

## Related Use Cases

- **Code signing (similar long-term)**: [UC-06: Code Signing](../06-code-signing/)
- **Long-term encryption**: [UC-03: Store Now, Decrypt Later](../03-store-now-decrypt-later/)
- **Full PQC hierarchy**: [UC-05: Full PQC PKI](../05-full-pqc-pki/)

## References

- [RFC 3161: Time-Stamp Protocol (TSP)](https://datatracker.ietf.org/doc/html/rfc3161)
- [ETSI TS 101 861: Time stamping profile](https://www.etsi.org/deliver/etsi_ts/101800_101899/101861/)
- [NIST FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)

---

**Need help with compliant timestamping infrastructure?** Contact [QentriQ](https://qentriq.com)
