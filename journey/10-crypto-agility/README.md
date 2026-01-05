# PQC Crypto-Agility: Migrate Without Breaking

## CA Rotation and Trust Bundle Migration

> **Key Message:** Crypto-agility is the ability to change algorithms without breaking your system. Use CA versioning and trust bundles.

---

## The Scenario

*"We have 10,000 ECDSA certificates in production. We need to migrate to ML-DSA. But we can't break everything at once."*

```
CURRENT SITUATION
─────────────────

  ┌─────────────────────────────────────────────────────────────┐
  │                                                             │
  │  Production                                                 │
  │  ──────────                                                 │
  │                                                             │
  │  ┌───────────┐  ┌───────────┐  ┌───────────┐              │
  │  │  Server   │  │  Server   │  │  Server   │  ... x 500   │
  │  │  ECDSA    │  │  ECDSA    │  │  ECDSA    │              │
  │  └───────────┘  └───────────┘  └───────────┘              │
  │                                                             │
  │  ┌───────────┐  ┌───────────┐  ┌───────────┐              │
  │  │  Client   │  │  Client   │  │  Client   │  ... x 9500  │
  │  │  Legacy   │  │  Legacy   │  │  Modern   │              │
  │  │  (ECDSA)  │  │  (ECDSA)  │  │  (PQC OK) │              │
  │  └───────────┘  └───────────┘  └───────────┘              │
  │                                                             │
  └─────────────────────────────────────────────────────────────┘

  How to migrate without cutting service?
```

---

## The Problem

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  "BIG BANG" MIGRATION: Risk of massive outage                   │
│                                                                  │
│                                                                  │
│    Day D: Migration to ML-DSA                                   │
│                                                                  │
│       ┌─────────┐         ┌─────────┐                           │
│       │ Server  │  ❌───► │ Client  │  Doesn't understand ML-DSA│
│       │ ML-DSA  │         │ Legacy  │                           │
│       └─────────┘         └─────────┘                           │
│                                                                  │
│    Result:                                                       │
│    - 80% of clients can't connect anymore                       │
│    - Massive outage                                              │
│    - Rollback required                                           │
│    - Migration delayed 6 months                                 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## The Solution: CA Rotation with Trust Bundles

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  CA VERSIONING                                                  │
│  ─────────────                                                  │
│                                                                  │
│  Migration CA                                                    │
│  ├── v1 (ECDSA)     ──► archived                                │
│  ├── v2 (Hybrid)    ──► archived                                │
│  └── v3 (ML-DSA)    ──► active                                  │
│                                                                  │
│  Key Insight:                                                    │
│  - ONE logical CA with MULTIPLE cryptographic versions          │
│  - Old certificates remain valid after rotation                  │
│  - Trust bundles allow gradual client migration                  │
│                                                                  │
│  PKI reality: Each version has its own key. "Versioning" is     │
│  an operational abstraction over distinct trust anchors.        │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Trust Store Strategy

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  TRUST STORE DEPLOYMENT                                         │
│                                                                  │
│  Clients Legacy ── trust-legacy.pem ──► CA v1 ──► Cert v1       │
│  Clients Modern ── trust-modern.pem ──► CA v3 ──► Cert v3       │
│                                                                  │
│  Transition :                                                    │
│  Clients ── trust-transition.pem ──► CA v1 / v2 / v3            │
│                                                                  │
│  During migration:                                               │
│  - Publish trust-transition.pem (contains ALL CA versions)      │
│  - ALL certificates validate correctly                          │
│  - Clients upgrade at their own pace                            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

> **Important:** The trust bundle is a *temporary migration artifact*.
> It should be removed once all clients have migrated to PQC.

---

## What is Crypto-Agility?

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  CRYPTO-AGILITY                                                │
│  ──────────────                                                │
│                                                                 │
│  The ability of a system to:                                   │
│                                                                 │
│  1. CHANGE algorithm                                           │
│     → Without redesigning the architecture                     │
│                                                                 │
│  2. SUPPORT multiple algorithms                                │
│     → During transition                                        │
│                                                                 │
│  3. ROLLBACK quickly                                           │
│     → If a problem occurs                                      │
│                                                                 │
│  It's an ARCHITECTURAL PROPERTY, not a tool.                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## What This Demo Shows

| Step | What Happens | Key Concept |
|------|--------------|-------------|
| 1 | Explain crypto-agility | Definition and 3-phase strategy |
| 2 | Create Migration CA (ECDSA) | Phase 1: Current state |
| 3 | Rotate to Hybrid CA | Phase 2: Transition |
| 4 | Rotate to Full PQC CA | Phase 3: Target state |
| 5 | Issue PQC certificate | New certificates use active CA |
| 6 | Create trust stores | Legacy, modern, transition bundles |
| 7 | Prove interoperability | Old certs remain valid |
| 8 | Incident simulation | Rollback to previous version |
| 9 | Inspect certificates | Compare ECDSA vs ML-DSA |

---

## Run the Demo

```bash
./demo.sh
```

---

## The Commands

### Step 1: Create Migration CA (Phase 1)

```bash
# Create a Migration CA starting with ECDSA
qpki ca init --profile profiles/classic-ca.yaml \
    --var cn="Migration CA" \
    --dir output/ca

# Issue ECDSA server certificate
qpki credential enroll --ca-dir output/ca \
    --profile profiles/classic-tls-server.yaml \
    --var cn=server.example.com

# Export the credential
qpki credential export <credential-id> \
    --ca-dir output/ca \
    -o output/server-v1.pem
```

### Step 2: Rotate to Hybrid CA (Phase 2)

```bash
# Rotate to hybrid mode (ECDSA + ML-DSA)
qpki ca rotate --ca-dir output/ca \
    --profile profiles/hybrid-ca.yaml

# Check versions
qpki ca versions --ca-dir output/ca
# VERSION  STATUS    ALGORITHM
# v1       archived  ecdsa-p256
# v2       active    hybrid-catalyst
```

### Step 3: Rotate to Full PQC CA (Phase 3)

```bash
# Rotate to full post-quantum
qpki ca rotate --ca-dir output/ca \
    --profile profiles/pqc-ca.yaml

# Check versions
qpki ca versions --ca-dir output/ca
# VERSION  STATUS    ALGORITHM
# v1       archived  ecdsa-p256
# v2       archived  hybrid-catalyst
# v3       active    ml-dsa-65
```

### Step 4: Issue PQC Certificate

```bash
# Issue PQC server certificate
qpki credential enroll --ca-dir output/ca \
    --profile profiles/pqc-tls-server.yaml \
    --var cn=server.example.com

# Export the credential
qpki credential export <credential-id> \
    --ca-dir output/ca \
    -o output/server-v3.pem
```

### Step 5: Create Trust Stores

```bash
# Trust store for legacy clients (v1 only)
qpki ca export --ca-dir output/ca --version v1 -o output/trust-legacy.pem

# Trust store for modern clients (v3 only)
qpki ca export --ca-dir output/ca --version v3 -o output/trust-modern.pem

# Trust store for transition (all versions)
qpki ca export --ca-dir output/ca --all -o output/trust-transition.pem
```

### Step 6: Verify Interoperability

```bash
# Old cert validates with legacy trust
qpki cert verify output/server-v1.pem --ca output/trust-legacy.pem

# New cert validates with modern trust
qpki cert verify output/server-v3.pem --ca output/trust-modern.pem

# ALL certs validate with transition bundle
qpki cert verify output/server-v1.pem --ca output/trust-transition.pem
qpki cert verify output/server-v3.pem --ca output/trust-transition.pem
```

### Step 7: Incident Simulation (Rollback)

```bash
# Scenario: A compatibility issue is detected on legacy appliances.
# Action: Rollback to Hybrid CA (v2) to restore service.

qpki ca activate --ca-dir output/ca --version v2

# Verify rollback succeeded
qpki ca versions --ca-dir output/ca
```

---

## Crypto-Agility Checklist

| Question | Crypto-Agile | Not Crypto-Agile |
|----------|--------------|------------------|
| Are algorithms configured or hardcoded? | Configured | Hardcoded |
| Can you change algo without rebuild? | Yes | No |
| Do certs support multiple algos? | Yes (hybrid) | No |
| Can you rollback in < 1h? | Yes | No |
| Is crypto inventory automated? | Yes | Manual |

---

## Size Comparison

| Phase | Algorithm | CA Cert | Server Cert | Notes |
|-------|-----------|---------|-------------|-------|
| Phase 1 | ECDSA P-256 | ~600 B | ~800 B | Compact |
| Phase 2 | ECDSA + ML-DSA | ~5 KB | ~6 KB | Hybrid |
| Phase 3 | ML-DSA-65 | ~4 KB | ~5 KB | Full PQC |

*Size increase is usually negligible compared to TLS records, HTTP payloads, or firmware images.*

---

## What You Learned

1. **Crypto-agility** is the ability to change algorithms without breaking your system
2. **CA rotation** allows evolving cryptographic algorithms over time
3. **Trust bundles** enable gradual client migration
4. **Old certificates remain valid** after CA rotation
5. **Rollback is always possible** - reactivate older versions
6. **Never do "big bang"** migration - it's too risky
7. **You're ready:** You now have the knowledge to plan and execute a PQC migration.

---

## References

- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [NIST FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)
- [Catalyst Hybrid Certificates](https://www.ietf.org/archive/id/draft-ounsworth-pq-composite-sigs-13.html)

---

← [CMS Encryption](../09-cms-encryption/)
