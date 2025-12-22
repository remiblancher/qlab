# Mission 8: "Rotate Without Breaking"

## Crypto-Agility: Migrate Without Breaking

### The Problem

You have 10,000 ECDSA certificates in production.
You need to migrate to ML-DSA.

But you can't break everything at once.

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

### The Threat

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

### The Solution: 3-Phase Migration

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  PHASE 1: PREPARATION (today)                                   │
│  ───────────────────────────                                    │
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

## Crypto-Agility: Definition

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

## What You'll Do

1. **Create a classic CA** (Phase 1: ECDSA)
2. **Create a hybrid CA** (Phase 2: ECDSA + ML-DSA)
3. **Create a full PQC CA** (Phase 3: ML-DSA)
4. **Test interoperability**: legacy vs modern client
5. **Simulate a rollback**: from hybrid to classic

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

## What You'll Have at the End

- 3 CAs (classic, hybrid, PQC)
- Interoperability proof
- Concrete migration plan
- Understanding of rollback

---

## Run the Mission

```bash
./demo.sh
```

---

← [OCSP](../08-ocsp/) | [Next: LTV Signatures →](../10-ltv-signatures/)
