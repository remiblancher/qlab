# Mission 1: "Build Your Quantum-Safe Foundation"

## Full PQC Chain with ML-DSA

### The Problem

Your classic CA (ECDSA) will be breakable by a quantum computer.
All the certificates it signed will become untrustworthy.

```
TODAY                                IN 10-15 YEARS
─────                                ──────────────

   Your ECDSA CA                        Quantum Computer
       │                                       │
       │ Signs                                 │ Breaks ECDSA
       ▼                                       ▼
  [Certificate]  ───────────────────────►  [FORGED Certificate]

  "This server is                        "Anyone can forge
   authentic"                             this certificate"
```

### The Solution

Create a new CA hierarchy with **ML-DSA** (post-quantum).

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                    ROOT CA                                      │
│                    ════════                                     │
│                    ML-DSA-87                                    │
│                    (maximum security, 256 bits)                 │
│                           │                                     │
│                           │ Signs                               │
│                           ▼                                     │
│                    ISSUING CA                                   │
│                    ══════════                                   │
│                    ML-DSA-65                                    │
│                    (daily operations)                           │
│                           │                                     │
│                           │ Signs                               │
│                           ▼                                     │
│                    TLS CERTIFICATE                              │
│                    ═══════════════                              │
│                    ML-DSA-65                                    │
│                    server.example.com                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## What You'll Do

1. **Create the Root CA** with ML-DSA-87 (maximum security level)
2. **Create the Issuing CA** with ML-DSA-65 (signed by Root)
3. **Issue a TLS certificate** for a server
4. **Verify the chain of trust**

---

## ML-DSA Security Levels

| Level | Algorithm | Security | Usage |
|-------|-----------|----------|-------|
| 2 | ML-DSA-44 | 128 bits | Lightweight applications |
| 3 | ML-DSA-65 | 192 bits | **General use** |
| 5 | ML-DSA-87 | 256 bits | **Root CA, high security** |

**Recommendation**: ML-DSA-87 for Root, ML-DSA-65 for everything else.

---

## What You'll Have at the End

- Post-quantum Root CA (ML-DSA-87)
- Post-quantum Issuing CA (ML-DSA-65)
- Post-quantum TLS certificate
- Verified chain of trust

---

## Run the Mission

```bash
./demo.sh
```

---

← [The Revelation](../01-revelation/) | [Next: Hybrid →](../03-hybrid/)
