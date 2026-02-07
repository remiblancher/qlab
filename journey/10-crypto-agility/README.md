---
title: "PQC Crypto-Agility: Migrate Without Breaking"
description: "Implement CA rotation and trust bundle migration to switch algorithms without downtime, enabling gradual client migration."
---

# PQC Crypto-Agility: Migrate Without Breaking

## CA Rotation and Trust Bundle Migration

> **Key Message:** Crypto-agility = your PKI can switch algorithms without downtime. This requires versioning, not just configuration.

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

## What We'll Do

1. Create Migration CA (ECDSA)
2. Issue ECDSA server certificate (v1)
3. Rotate to hybrid (ECDSA + ML-DSA)
4. Rotate to full PQC (ML-DSA)
5. Issue PQC server certificate (v3)
6. Create trust stores
7. Verify certificates against trust stores
8. Simulate rollback

---

## Run the Demo

```bash
./journey/10-crypto-agility/demo.sh
```

---

## The Commands

### Step 1: Create Migration CA (ECDSA)

```bash
# Create a Migration CA starting with ECDSA
qpki ca init --profile profiles/classic-ca.yaml \
    --var cn="Migration CA" \
    --ca-dir output/ca
```

### Step 2: Issue ECDSA Server Certificate (v1)

```bash
# Issue ECDSA server certificate
qpki credential enroll --ca-dir output/ca \
    --cred-dir output/credentials \
    --profile profiles/classic-tls-server.yaml \
    --var cn=server.example.com

qpki credential export <credential-id> \
    --ca-dir output/ca \
    --cred-dir output/credentials \
    --out output/server-v1.pem
```

### Step 3: Rotate to Hybrid CA

```bash
# Rotate to hybrid mode (ECDSA + ML-DSA)
qpki ca rotate --ca-dir output/ca \
    --profile profiles/hybrid-ca.yaml

qpki ca activate --ca-dir output/ca --version v2

qpki ca versions --ca-dir output/ca
# v1       archived  ecdsa-p256
```

### Step 4: Rotate to Full PQC CA

```bash
# Rotate to full post-quantum
qpki ca rotate --ca-dir output/ca \
    --profile profiles/pqc-ca.yaml

qpki ca activate --ca-dir output/ca --version v3

qpki ca versions --ca-dir output/ca
# v1       archived  ecdsa-p256
# v3       active    ml-dsa-65
```

### Step 5: Issue PQC Server Certificate (v3)

```bash
# Issue PQC server certificate
qpki credential enroll --ca-dir output/ca \
    --cred-dir output/credentials \
    --profile profiles/pqc-tls-server.yaml \
    --var cn=server.example.com

qpki credential export <credential-id> \
    --ca-dir output/ca \
    --cred-dir output/credentials \
    --out output/server-v3.pem
```

### Step 6: Create Trust Stores

```bash
# Trust store for legacy clients (v1 only)
qpki ca export --ca-dir output/ca --version v1 --out output/trust-legacy.pem

qpki ca export --ca-dir output/ca --version v3 --out output/trust-modern.pem

qpki ca export --ca-dir output/ca --all --out output/trust-transition.pem
```

### Step 7: Verify Certificates Against Trust Stores

```bash
# Old cert validates with legacy trust
qpki cert verify output/server-v1.pem --ca output/trust-legacy.pem

qpki cert verify output/server-v3.pem --ca output/trust-modern.pem

qpki cert verify output/server-v1.pem --ca output/trust-transition.pem
qpki cert verify output/server-v3.pem --ca output/trust-transition.pem
```

### Step 8: Simulate Rollback

```bash
# Scenario: A compatibility issue is detected on legacy appliances.

qpki ca activate --ca-dir output/ca --version v2

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

← [CMS Encryption](../09-cms-encryption/) | [QLAB Home](../../README.md)
