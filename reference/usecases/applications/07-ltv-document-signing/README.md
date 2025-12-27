# APP-07: "LTV: Sign Today, Verify in 30 Years"

## Long-Term Validation for Document Signing

> **Key Message:** A signature is only as good as its proof chain. LTV packages everything needed to verify a signature decades from now, even if the CA is gone.

> **Visual diagrams:** See [`diagram.txt`](diagram.txt) for ASCII diagrams of the LTV proof structure.

## The Scenario

*"We signed a 30-year contract today. In 2055, how will anyone verify this signature if our CA no longer exists?"*

This is the **Long-Term Validation (LTV)** problem. A signature alone isn't enough — you need:
1. The signature itself
2. Proof of **when** it was signed (timestamp from a TSA)
3. Proof the certificate was **valid** at signing time (OCSP snapshot)
4. The full **certificate chain** (including CA certs)

## What You'll See

| Step | What Happens | What You See |
|------|--------------|--------------|
| 1. Setup PKI | CA + OCSP + TSA infrastructure | Services ready |
| 2. Sign document | CMS signature with ML-DSA | `contract.txt.p7s` created |
| 3. Timestamp | RFC 3161 proof from TSA | Timestamp from trusted TSA |
| 4. OCSP snapshot | Certificate status query | "Status: good" captured |
| 5. Create LTV proof | All proofs packaged | `contract-ltv-proof/` |
| 6. Offline verify | Verify without network | "Valid as of 2024-XX-XX" |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           LTV INFRASTRUCTURE                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐               │
│   │     CA      │     │    OCSP     │     │     TSA     │               │
│   │  (ML-DSA)   │────>│  Responder  │     │   Server    │               │
│   │             │     │   :8080     │     │   :8081     │               │
│   └─────────────┘     └─────────────┘     └─────────────┘               │
│          │                   │                   │                       │
│          │ issues            │ status            │ timestamp             │
│          ▼                   ▼                   ▼                       │
│   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐               │
│   │   Alice     │     │    OCSP     │     │  Timestamp  │               │
│   │   (signer)  │     │  Response   │     │   Token     │               │
│   └─────────────┘     └─────────────┘     └─────────────┘               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## The LTV Proof

```
contract-ltv-proof/
├── document.txt           # Original document
├── signature.p7s          # CMS signature (ML-DSA)
├── timestamp.tsr          # RFC 3161 timestamp (from TSA)
├── ocsp-response.der      # OCSP status snapshot
├── chain.pem              # Full certificate chain
└── manifest.json          # Proof metadata
```

## Why LTV Matters

### Without LTV (Fragile)

```
2024: Sign document
      ├── Signature: ✓ Valid
      └── Certificate: ✓ Valid (OCSP says so)

2055: Verify document
      ├── Signature: ✓ Still valid
      └── Certificate: ???
          ├── CA server: GONE
          ├── OCSP responder: GONE
          └── CRL distribution point: GONE

      Result: CANNOT VERIFY
```

### With LTV (Durable)

```
2024: Sign document + Create LTV proof
      ├── Signature: ✓ Valid
      ├── Timestamp: ✓ Proves signing time (from TSA)
      ├── OCSP snapshot: ✓ Certificate was valid
      └── Chain: ✓ All CA certs included

2055: Verify document (offline!)
      ├── Signature: ✓ Still valid
      ├── Timestamp: ✓ Signed on 2024-XX-XX
      ├── OCSP snapshot: ✓ Cert was valid at signing
      └── Chain: ✓ Verification succeeds

      Result: VERIFIED (no network needed)
```

## Personas

- **Alice** - Legal counsel signing a 30-year lease agreement
- **Bob** - Archivist verifying the document in 2055
- **TSA-01** - Timestamp Authority providing time proof
- **OCSP-01** - OCSP Responder providing certificate status

## Quick Start

```bash
./demo.sh
```

## The Commands

### Step 1: Setup PKI Infrastructure

```bash
# Create CA for document signing
pki ca init --name "LTV Demo CA" \
    --algorithm ml-dsa-65 \
    --dir ./ltv-ca

# Issue Alice's document signing certificate
pki cert issue --ca-dir ./ltv-ca \
    --profile ml-dsa-kem/document-signing \
    --cn "Alice (Legal)" \
    --out alice.crt --key-out alice.key

# Issue OCSP responder certificate
pki cert issue --ca-dir ./ltv-ca \
    --profile ml-dsa-kem/ocsp-responder \
    --cn "OCSP Responder" \
    --out ocsp.crt --key-out ocsp.key

# Issue TSA certificate
pki cert issue --ca-dir ./ltv-ca \
    --profile ml-dsa-kem/tsa \
    --cn "Timestamp Authority" \
    --out tsa.crt --key-out tsa.key
```

### Step 2: Start Services

```bash
# Start OCSP responder (background)
pki ocsp serve --ca-dir ./ltv-ca \
    --cert ocsp.crt --key ocsp.key \
    --listen :8080 &
OCSP_PID=$!

# Start TSA server (background)
pki tsa serve --cert tsa.crt --key tsa.key \
    --listen :8081 &
TSA_PID=$!

echo "OCSP responder running on :8080"
echo "TSA server running on :8081"
```

### Step 3: Sign the Document

```bash
# Create a test document
echo "30-YEAR LEASE AGREEMENT - Signed $(date)" > contract.txt

# Sign with CMS (Alice's signature)
pki cms sign --data contract.txt \
    --cert alice.crt --key alice.key \
    -o contract.txt.p7s
```

### Step 4: Request Timestamp (from TSA)

```bash
# Request timestamp from TSA server (proves WHEN it was signed)
pki tsa request --data contract.txt.p7s \
    --server http://localhost:8081 \
    -o contract.txt.tsr
```

### Step 5: Capture OCSP Status

```bash
# Get OCSP response (proves certificate was VALID at signing)
pki ocsp query --cert alice.crt \
    --issuer ./ltv-ca/ca.crt \
    --responder http://localhost:8080 \
    -o ocsp-response.der
```

### Step 6: Create LTV Proof

```bash
# Package everything for long-term verification
mkdir contract-ltv-proof
cp contract.txt contract-ltv-proof/document.txt
cp contract.txt.p7s contract-ltv-proof/signature.p7s
cp contract.txt.tsr contract-ltv-proof/timestamp.tsr
cp ocsp-response.der contract-ltv-proof/
cat alice.crt ./ltv-ca/ca.crt > contract-ltv-proof/chain.pem

# Create manifest
cat > contract-ltv-proof/manifest.json << EOF
{
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "document": "document.txt",
  "signature": "signature.p7s",
  "timestamp": "timestamp.tsr",
  "ocsp": "ocsp-response.der",
  "chain": "chain.pem"
}
EOF
```

### Step 7: Verify Offline (Simulating 2055)

```bash
# Stop services to simulate offline verification
kill $OCSP_PID $TSA_PID 2>/dev/null

# Verify using only the LTV proof (no network)
pki cms verify --signature contract-ltv-proof/signature.p7s \
    --data contract-ltv-proof/document.txt \
    --ca contract-ltv-proof/chain.pem

# Verify timestamp
pki tsa verify --token contract-ltv-proof/timestamp.tsr \
    --data contract-ltv-proof/signature.p7s \
    --ca contract-ltv-proof/chain.pem

echo "✓ Document verified offline - valid as of signing date"
```

## Use Cases for LTV

| Document Type | Retention Period | LTV Required? |
|--------------|------------------|---------------|
| Legal contracts | 10-30 years | **Yes** |
| Medical records | 50+ years | **Yes** |
| Real estate deeds | Permanent | **Yes** |
| Financial audits | 7-10 years | Yes |
| Software licenses | 5-15 years | Yes |
| Email archives | 3-7 years | Optional |

## Learning Outcomes

After this demo, you'll understand:
- Why signatures alone aren't enough for long-term validity
- What components make up an LTV proof
- How TSA and OCSP work together
- How to create verifiable proof packages
- Why PQC is essential for 30+ year documents

## Duration

~10 minutes

## Related Use Cases

- [APP-01: PQC Code Signing](../01-pqc-code-signing/) - Basic CMS signatures
- [APP-02: PQC Timestamping](../02-pqc-timestamping/) - RFC 3161 timestamps
- [APP-04: OCSP Responder](../04-ocsp-responder/) - Certificate status checking

## References

- [RFC 5126: CMS Advanced Electronic Signatures (CAdES)](https://datatracker.ietf.org/doc/html/rfc5126)
- [ETSI TS 101 733: Electronic Signatures and Infrastructures](https://www.etsi.org/deliver/etsi_ts/101700_101799/101733/)
- [PAdES: PDF Advanced Electronic Signatures](https://www.etsi.org/deliver/etsi_en/319100_319199/31914201/)

---

**Need help with long-term document signing?** Contact [QentriQ](https://qentriq.com)
