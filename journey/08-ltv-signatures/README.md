# Mission 9: "Sign Today, Verify in 30 Years"

## LTV Signatures with Hybrid

### The Problem

You sign a contract today. In 30 years, you need to prove it was valid.

But:
- The certificate has expired
- The OCSP responder no longer exists
- The CA may have been dissolved

How do you verify?

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

### The Threat

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

### The Solution: LTV (Long-Term Validation)

Embed EVERYTHING needed in the document:

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  LTV: Self-sufficient signature                                 │
│                                                                  │
│                                                                  │
│    ┌─────────────────────────────────────────────────────────┐  │
│    │  Document with LTV                                       │  │
│    │  ─────────────────────                                   │  │
│    │                                                          │  │
│    │  1. Original document                                    │  │
│    │     └── Contract.pdf                                     │  │
│    │                                                          │  │
│    │  2. Signature                                            │  │
│    │     └── ML-DSA + ECDSA (hybrid)                         │  │
│    │                                                          │  │
│    │  3. TSA Timestamp                                        │  │
│    │     └── Proof that signature existed in 2024            │  │
│    │                                                          │  │
│    │  4. OCSP Response                                        │  │
│    │     └── "Cert was valid at time of signing"             │  │
│    │                                                          │  │
│    │  5. Complete chain                                       │  │
│    │     └── Root CA → Issuing CA → Signing cert             │  │
│    │     └── TSA cert + chain                                │  │
│    │     └── OCSP cert + chain                               │  │
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

| Component | Role | Why needed |
|-----------|------|-----------|
| **Signature** | Document authenticity | Proves who signed |
| **Timestamp** | Temporal proof | Proves WHEN |
| **OCSP Response** | Status at time T | Proves cert was valid |
| **Cert chain** | Trust anchor | Allows tracing to root |

---

## Use Cases

| Domain | Retention period | Constraint |
|--------|-----------------|------------|
| Commercial contracts | 10 years | Commercial code |
| Notarial acts | 75 years | Legal obligation |
| Medical records | 50+ years | Medical confidentiality |
| Tax documents | 10 years | Tax administration |
| Patents | 20+ years | Intellectual property |

---

## What You'll Do

1. **Create a signed document** with your hybrid CA
2. **Add a timestamp** via TSA
3. **Capture the OCSP response** at signing time
4. **Embed the complete chain** (all certificates)
5. **Simulate 2054**: verify OFFLINE without any service

---

## PAdES-LTV Format

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

## What You'll Have at the End

- Document with complete LTV signature
- Proof of offline verification
- Understanding of legal archiving
- Trust until 2054+

---

## Run the Mission

```bash
./demo.sh
```

---

← [Crypto-Agility](../09-crypto-agility/) | [Next: PQC Tunnel →](../11-pqc-tunnel/)
