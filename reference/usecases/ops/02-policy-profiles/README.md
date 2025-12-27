# OPS-02: "Policy, Not Refactor"

## Algorithm Changes Through Policy Configuration

> **Key Message:** Migrating to PQC is a policy change, not a code refactor. Same workflow, different algorithm.

> **Visual diagrams:** See [`diagram.txt`](diagram.txt) for ASCII diagrams of the policy-driven approach.

## The Scenario

*"Our security team mandates post-quantum cryptography for all new certificates. Do we need to change our issuance workflows?"*

No! With a well-designed PKI, changing algorithms is just a policy configuration change. The same commands, the same workflows — only the profile changes.

## What You'll See

| Step | What Happens | What You See |
|------|--------------|--------------|
| 1. Issue with classic profile | ECDSA certificate | Standard TLS cert |
| 2. Change to PQC profile | Same command | ML-DSA certificate |
| 3. Compare | Side by side | Same workflow, different algo |

## Personas

- **Bob** - PKI Admin implementing new security policy
- **Policy** - Security requirement driving the change

## Quick Start

```bash
./demo.sh
```

## What This Demo Creates

```
workspace/
├── ca/                    # Hybrid CA (supports both)
├── classic/
│   └── server.crt         # ECDSA certificate
├── pqc/
│   └── server.crt         # ML-DSA certificate
└── comparison.txt         # Side-by-side comparison
```

## The Key Insight

```
BEFORE (Classic):                    AFTER (PQC):
─────────────────                    ─────────────

pki cert issue \                          pki cert issue \
  --profile ec/tls-server \            --profile ml-dsa-kem/tls-server \
  --cn api.example.com                 --cn api.example.com

        │                                    │
        ▼                                    ▼
┌─────────────────┐                 ┌─────────────────┐
│ ECDSA P-384     │                 │ ML-DSA-65       │
│ Certificate     │                 │ Certificate     │
└─────────────────┘                 └─────────────────┘

SAME COMMAND STRUCTURE. ONLY THE PROFILE CHANGES.
```

## Learning Outcomes

After this demo, you'll understand:
- Why algorithm changes are policy changes
- How profiles abstract algorithm complexity
- Why PKI design enables smooth transitions
- How to implement PQC mandates without workflow changes

## Duration

~8 minutes

## Next Steps

- [OPS-03: Incident Drill](../03-incident-response/) - Practice incident response
- [PKI-04: Hybrid Catalyst](../../pki/04-hybrid-catalyst/) - Hybrid certificates
