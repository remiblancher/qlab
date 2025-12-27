# PQC LTV: Sign Today, Verify in 30 Years

## Long-Term Validation for Document Signing

> **Key Message:** A signature is only as good as its proof chain. LTV bundles everything needed for offline verification decades from now.

---

## The Scenario

*"We signed a 30-year contract today. In 2055, how will anyone verify this signature if our CA no longer exists?"*

This is the **Long-Term Validation (LTV)** problem. A signature alone isn't enough — you need proof that the certificate was valid at the time of signing.

---

## The Problem

```
TODAY (2024)                         IN 30 YEARS (2054)
────────────                         ──────────────────

┌────────────────┐                   ┌────────────────┐
│  Contract.pdf  │                   │  Contract.pdf  │
│  + Signature   │                   │  + Signature   │
│                │                   │                │
│  Services:     │    ────────────►  │  Services:     │
│  ✓ CA online   │                   │  ❌ CA dissolved │
│  ✓ OCSP online │                   │  ❌ OCSP down    │
│  ✓ Cert valid  │                   │  ❌ Cert expired │
└────────────────┘                   └────────────────┘

                                     How to verify
                                     the signature?
```

---

## The Threat

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  "PERISHABLE" SIGNATURE: Dependency on external services        │
│                                                                  │
│                                                                  │
│    2024                2034                2054                  │
│      │                   │                   │                   │
│      │  Signature        │  Cert expired     │  Verification?   │
│      │  created          │                   │                   │
│      ▼                   ▼                   ▼                   │
│                                                                  │
│    ┌───────┐           ┌───────┐           ┌───────┐            │
│    │  OK   │           │  ???  │           │  ???  │            │
│    └───────┘           └───────┘           └───────┘            │
│                                                                  │
│    To verify in 2054, you would need:                           │
│    - The certificate (expired)                                   │
│    - The OCSP response (service down)                           │
│    - The CA chain (company dissolved)                           │
│    - The timestamp (TSA migrated)                               │
│                                                                  │
│    → IMPOSSIBLE without preparation                              │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## The Solution: LTV (Long-Term Validation)

Embed EVERYTHING needed in a self-sufficient bundle:

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  LTV BUNDLE: Self-sufficient verification package               │
│                                                                  │
│                                                                  │
│    ┌─────────────────────────────────────────────────────────┐  │
│    │  LTV Bundle                                              │  │
│    │  ──────────────                                          │  │
│    │                                                          │  │
│    │  1. Original document                                    │  │
│    │     └── contract.txt                                     │  │
│    │                                                          │  │
│    │  2. Signature                                            │  │
│    │     └── signature.p7s (ML-DSA CMS)                      │  │
│    │                                                          │  │
│    │  3. Timestamp                                            │  │
│    │     └── timestamp.tsr (proves WHEN it was signed)       │  │
│    │                                                          │  │
│    │  4. Certificate chain                                    │  │
│    │     └── chain.pem (signer + CA certs)                   │  │
│    │                                                          │  │
│    │  5. Manifest                                             │  │
│    │     └── manifest.json (metadata)                        │  │
│    │                                                          │  │
│    └─────────────────────────────────────────────────────────┘  │
│                                                                  │
│    VERIFICATION IN 2054:                                         │
│    ✓ Everything is embedded                                      │
│    ✓ No external dependencies                                    │
│    ✓ OFFLINE verification possible                               │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## LTV Components

| Component | Role | Why Needed |
|-----------|------|------------|
| **Signature** | Document authenticity | Proves WHO signed |
| **Timestamp** | Temporal proof | Proves WHEN it was signed |
| **Certificate chain** | Trust anchor | Allows tracing to root CA |
| **Manifest** | Metadata | Documents the bundle structure |

---

## What This Demo Shows

| Step | What Happens | Expected Result |
|------|--------------|-----------------|
| 1 | Create CA + Signing Certificate + TSA | ML-DSA-65 PKI ready |
| 2 | Sign document (CMS format) | `contract.p7s` created |
| 3 | Add timestamp (RFC 3161) | `contract.tsr` created |
| 4 | Create LTV bundle | All proofs packaged |
| 5 | Verify offline (simulating 2055) | Status: VALID |

---

## Run the Demo

```bash
./demo.sh
```

---

## The Commands

### Step 1: Create PKI Infrastructure

```bash
# Create PQC CA
pki ca init --name "LTV Demo CA" \
    --algorithm ml-dsa-65 \
    --dir output/ltv-ca

# Issue document signing certificate
pki cert issue --ca-dir output/ltv-ca \
    --profile ml-dsa-kem/code-signing \
    --cn "Alice (Legal Counsel)" \
    --out output/alice.crt \
    --key-out output/alice.key

# Issue TSA certificate
pki cert issue --ca-dir output/ltv-ca \
    --profile ml-dsa-kem/timestamping \
    --cn "LTV Timestamp Authority" \
    --out output/tsa.crt \
    --key-out output/tsa.key
```

### Step 2: Sign the Document

```bash
# Create a 30-year lease agreement
cat > output/contract.txt << 'EOF'
30-YEAR COMMERCIAL LEASE AGREEMENT
Signing Date: 2024-12-22
Expiration: 2054-12-22
Parties: ACME Properties / TechCorp Industries
EOF

# Sign with CMS (ML-DSA)
pki cms sign --data output/contract.txt \
    --cert output/alice.crt \
    --key output/alice.key \
    -o output/contract.p7s
```

### Step 3: Add Timestamp

```bash
# Timestamp the signature (proves WHEN it was signed)
pki tsa sign --data output/contract.p7s \
    --cert output/tsa.crt \
    --key output/tsa.key \
    -o output/contract.tsr
```

### Step 4: Create LTV Bundle

```bash
# Package everything for long-term verification
mkdir -p output/ltv-bundle
cp output/contract.txt output/ltv-bundle/document.txt
cp output/contract.p7s output/ltv-bundle/signature.p7s
cp output/contract.tsr output/ltv-bundle/timestamp.tsr
cat output/alice.crt output/ltv-ca/ca.crt > output/ltv-bundle/chain.pem
```

### Step 5: Verify Offline (Simulating 2055)

```bash
# Verify using only the bundle (no network)
pki cms verify --signature output/ltv-bundle/signature.p7s \
    --data output/ltv-bundle/document.txt
# Result: VALID - signature verified with bundled chain
```

---

## PAdES-LTV Format (PDF)

For PDF documents, LTV data is stored in a Document Security Store (DSS):

```
PDF Document with LTV
─────────────────────

┌─────────────────────────────────────────────────────────────┐
│  PDF Document                                               │
│  ├── Page 1, 2, 3...                                       │
│  │                                                          │
│  └── DSS (Document Security Store)                         │
│      ├── Certs[]                                           │
│      │   ├── signing-cert.der                              │
│      │   ├── issuing-ca.der                                │
│      │   ├── root-ca.der                                   │
│      │   └── tsa-cert.der                                  │
│      │                                                      │
│      ├── OCSPs[]                                           │
│      │   └── ocsp-response.der                             │
│      │                                                      │
│      └── CRLs[]                                            │
│          └── ca.crl (optional)                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Why PQC for LTV

### The 30-Year Timeline Problem

```
2024                    2035?                   2054
  │                       │                       │
  │  Sign document        │  Quantum computers    │  Verify signature
  │  with ML-DSA          │  break RSA/ECDSA      │
  │                       │                       │
  ▼                       ▼                       ▼

Classical signature:    FORGEABLE!              Cannot trust
ML-DSA signature:       Still secure            ✓ VERIFIED
```

### Long-Term Document Retention

| Document Type | Retention Period | PQC Required? |
|--------------|------------------|---------------|
| Legal contracts | 10-30 years | **Yes** |
| Medical records | 50+ years | **Yes** |
| Real estate deeds | Permanent | **Yes** |
| Notarial acts | 75 years | **Yes** |
| Financial audits | 7-10 years | Yes |
| Patents | 20+ years | **Yes** |

---

## What You Learned

1. **Signatures expire**: Without LTV, signatures become unverifiable
2. **LTV bundles proofs**: Document + signature + timestamp + chain
3. **Offline verification**: No network dependencies in 2055
4. **PQC is essential**: 30-year documents will face quantum computers

---

## References

- [RFC 5126: CMS Advanced Electronic Signatures (CAdES)](https://datatracker.ietf.org/doc/html/rfc5126)
- [ETSI TS 101 733: Electronic Signatures](https://www.etsi.org/deliver/etsi_ts/101700_101799/101733/)
- [PAdES: PDF Advanced Electronic Signatures](https://www.etsi.org/deliver/etsi_en/319100_319199/31914201/)
- [NIST FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)

---

← [PQC Timestamping](../07-timestamping/) | [Next: CMS Encryption →](../09-cms-encryption/)
