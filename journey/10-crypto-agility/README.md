# PQC Crypto-Agility: Migrate Without Breaking

## The 3-Phase Migration Strategy

> **Key Message:** Crypto-agility is the ability to change algorithms without breaking your system. Hybrid is the bridge.

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
  │  │  └───────────┘  └───────────┘  └───────────┘              │
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

## The Solution: 3-Phase Migration

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  PHASE 1: CLASSIC (today)                                       │
│  ────────────────────────                                       │
│                                                                  │
│  ┌─────────┐                                                    │
│  │  ECDSA  │  Status quo. Inventory your systems.              │
│  └─────────┘                                                    │
│                                                                  │
│  Actions:                                                        │
│  □ Inventory all certificates                                   │
│  □ Identify legacy vs modern clients                            │
│  □ Test PQC tools in lab                                        │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  PHASE 2: HYBRID (transition)                                   │
│  ─────────────────────────────                                  │
│                                                                  │
│  ┌─────────────────────┐                                        │
│  │  ECDSA + ML-DSA    │  Both algorithms in one cert.          │
│  └─────────────────────┘                                        │
│                                                                  │
│  Behavior:                                                       │
│  - Legacy client → Uses ECDSA (ignores ML-DSA)                  │
│  - Modern client → Verifies BOTH                                 │
│                                                                  │
│  ✓ 100% compatibility                                           │
│  ✓ PQC protection for modern clients                            │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  PHASE 3: FULL PQC (after client migration)                     │
│  ─────────────────────────────────────────────                  │
│                                                                  │
│  ┌─────────┐                                                    │
│  │  ML-DSA │  When ALL clients support PQC.                    │
│  └─────────┘                                                    │
│                                                                  │
│  Prerequisites:                                                  │
│  □ All clients updated                                          │
│  □ Regression tests passed                                      │
│  □ Rollback plan ready                                          │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

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

## Crypto-Agility Checklist

| Question | Crypto-Agile | Not Crypto-Agile |
|----------|--------------|------------------|
| Are algorithms configured or hardcoded? | Configured | Hardcoded |
| Can you change algo without rebuild? | Yes | No |
| Do certs support multiple algos? | Yes (hybrid) | No |
| Can you rollback in < 1h? | Yes | No |
| Is crypto inventory automated? | Yes | Manual |

---

## What This Demo Shows

| Step | What Happens | Key Concept |
|------|--------------|-------------|
| 1 | Explain crypto-agility | Definition and 3-phase strategy |
| 2 | Create Classic CA (ECDSA) | Phase 1: Current state |
| 3 | Create Hybrid CA (ECDSA + ML-DSA) | Phase 2: Transition |
| 4 | Create Full PQC CA (ML-DSA) | Phase 3: Target state |
| 5 | Test interoperability | OpenSSL vs pki verify |
| 6 | Compare certificate sizes | Size growth across phases |

---

## Run the Demo

```bash
./demo.sh
```

---

## The Commands

### Step 1: Create Classic CA (Phase 1)

```bash
# Create a classic ECDSA CA
pki ca init --name "Classic CA" \
    --algorithm ec-p256 \
    --dir output/classic-ca

# Issue ECDSA server certificate
pki cert issue --ca-dir output/classic-ca \
    --profile ec/tls-server \
    --cn "server.example.com" \
    --dns server.example.com \
    --out output/classic-server.crt \
    --key-out output/classic-server.key
```

### Step 2: Create Hybrid CA (Phase 2)

```bash
# Create hybrid CA (ECDSA + ML-DSA Catalyst)
pki ca init --name "Hybrid CA" \
    --algorithm ec-p256 \
    --hybrid-algorithm ml-dsa-65 \
    --dir output/hybrid-ca

# Issue hybrid server certificate
pki cert issue --ca-dir output/hybrid-ca \
    --profile hybrid/catalyst/tls-server \
    --cn "server.example.com" \
    --dns server.example.com \
    --out output/hybrid-server.crt \
    --key-out output/hybrid-server.key
```

### Step 3: Create Full PQC CA (Phase 3)

```bash
# Create full PQC CA
pki ca init --name "PQC CA" \
    --algorithm ml-dsa-65 \
    --dir output/pqc-ca

# Issue PQC server certificate
pki cert issue --ca-dir output/pqc-ca \
    --profile ml-dsa-kem/tls-server \
    --cn "server.example.com" \
    --dns server.example.com \
    --out output/pqc-server.crt \
    --key-out output/pqc-server.key
```

### Step 4: Test Interoperability

```bash
# Legacy client (OpenSSL) - only verifies classical signature
openssl verify -CAfile output/classic-ca/ca.crt output/classic-server.crt
openssl verify -CAfile output/hybrid-ca/ca.crt output/hybrid-server.crt

# PQC-aware client - verifies all signatures
pki verify --ca output/classic-ca/ca.crt --cert output/classic-server.crt
pki verify --ca output/hybrid-ca/ca.crt --cert output/hybrid-server.crt
pki verify --ca output/pqc-ca/ca.crt --cert output/pqc-server.crt
```

---

## Typical Migration Timeline

```
2024 Q4  Complete inventory
2025 Q1  Hybrid lab tests
2025 Q2  Hybrid deployment (5% traffic)
2025 Q3  Hybrid deployment (100%)
2026 Q1  Begin legacy client deprecation
2027     Full PQC (if all clients migrated)
```

---

## Size Comparison

| Phase | Algorithm | CA Cert | Server Cert | Notes |
|-------|-----------|---------|-------------|-------|
| Phase 1 | ECDSA P-256 | ~600 B | ~800 B | Compact |
| Phase 2 | ECDSA + ML-DSA | ~5 KB | ~6 KB | Hybrid |
| Phase 3 | ML-DSA-65 | ~4 KB | ~5 KB | Full PQC |

*Size increase is acceptable for the security benefits.*

---

## What You Learned

1. **Crypto-agility** is the ability to change algorithms without breaking your system
2. **Never do "big bang"** migration - it's too risky
3. **Hybrid certificates** provide 100% compatibility during transition
4. **Phase 2 (Hybrid)** is the critical bridge between classic and PQC
5. **Rollback capability** is essential for safe migration

---

## References

- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [NIST FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)
- [Catalyst Hybrid Certificates](https://www.ietf.org/archive/id/draft-ounsworth-pq-composite-sigs-13.html)

---

← [CMS Encryption](../09-cms-encryption/) | [Next: mTLS →](../11-mtls/)
