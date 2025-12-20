# Post-Quantum PKI Lab

> **"The PKI is the tool for transition — post-quantum is an engineering problem, not magic."**

Educational demonstrations for transitioning to Post-Quantum Cryptography using a real PKI implementation.

## Why This Matters

Quantum computers will eventually break RSA and ECC cryptography. The question isn't *if*, but *when*. Organizations need to prepare now — not panic, but plan.

**This lab demonstrates:**
- Classical and post-quantum PKI work the same way
- Hybrid certificates provide a safe migration path
- The PKI model is algorithm-agnostic

## Use Cases

### Section 1: PKI Fundamentals (~33 min)

Learn the core concepts of Post-Quantum PKI.

| # | Title | What You'll See | Duration |
|---|-------|-----------------|----------|
| PKI-01 | ["Store Now, Decrypt Later"](usecases/pki/01-store-now-decrypt-later/) | Your urgency score: "Act now!" | 5 min |
| PKI-02 | ["Classic vs PQC: Nothing Changes"](usecases/pki/02-classic-vs-pqc/) | Size & time comparison table | 5 min |
| PKI-03 | ["Full PQC Chain of Trust"](usecases/pki/03-full-pqc-chain/) | Root → Issuing → End ✓ | 10 min |
| PKI-04 | ["Hybrid PQC: Best of Both Worlds"](usecases/pki/04-hybrid-catalyst/) | ECDSA + ML-DSA in 1 cert | 8 min |
| PKI-05 | ["Oops, We Need to Revoke!"](usecases/pki/05-revocation-crl/) | Status: good → revoked | 5 min |

### Section 2: Applications (~64 min)

See PQC in action with real-world applications.

| # | Title | What You'll See | Duration |
|---|-------|-----------------|----------|
| APP-01 | ["PQC Signing: Sign It, Prove It"](usecases/applications/01-pqc-code-signing/) | Firmware: signed ✓ tampered ✗ | 8 min |
| APP-02 | ["PQC Timestamping: Trust Now, Verify Forever"](usecases/applications/02-pqc-timestamping/) | Certified timestamp on file | 8 min |
| APP-03 | ["PQC mTLS: Show Me Your Badge"](usecases/applications/03-mtls-authentication/) | "Welcome Alice!" via mTLS | 10 min |
| APP-04 | ["PQC OCSP: Is This Cert Still Good?"](usecases/applications/04-ocsp-responder/) | Real-time cert status check | 8 min |
| APP-05 | ["Crypto-Agility: Rotate Without Breaking"](usecases/applications/05-crypto-agility/) | Synchronized cert rotation | 10 min |
| APP-06 | ["Build a PQC Tunnel"](usecases/applications/06-tls-tunnel/) | Data through PQC tunnel | 10 min |
| APP-07 | ["LTV: Sign Today, Verify in 30 Years"](usecases/applications/07-ltv-document-signing/) | Proof file valid in 2055 | 10 min |

### Section 3: Ops & Migration (~26 min) — *Optional*

Bridge between demos and production migration.

| # | Title | What You'll See | Duration |
|---|-------|-----------------|----------|
| OPS-01 | ["Inventory Before You Migrate"](usecases/ops/01-inventory-scan/) | "Found: 3 ECDSA, 0 PQC" | 8 min |
| OPS-02 | ["Policy, Not Refactor"](usecases/ops/02-policy-profiles/) | Same workflow, different algo | 8 min |
| OPS-03 | ["Incident Drill"](usecases/ops/03-incident-response/) | Revoke → Re-issue → Verify | 10 min |

## Quick Start

```bash
# Install the PKI tool
./tooling/install.sh

# Run your first demo
cd usecases/pki/01-store-now-decrypt-later
./demo.sh
```

## Learning Paths

```
              START HERE
                  │
                  ▼
    ┌─────────────────────────────┐
    │  PKI Fundamentals (5 UC)    │  ~33 min
    │  Understand the concepts    │
    └─────────────┬───────────────┘
                  │
                  ▼
    ┌─────────────────────────────┐
    │  Applications (7 UC)        │  ~62 min
    │  See it in action           │
    └─────────────┬───────────────┘
                  │
                  ▼
    ┌─────────────────────────────┐
    │  Ops & Migration (3 UC)     │  ~26 min
    │  Plan your transition       │  (optional)
    └─────────────────────────────┘
```

### By Role

| Role | Recommended Path |
|------|------------------|
| **Developer** | PKI-01, PKI-02 → APP-01, APP-03 |
| **Security Architect** | All PKI → APP-04, APP-05 → OPS-01, OPS-02 |
| **CISO/Executive** | PKI-01, PKI-04 → APP-02 |
| **Operations** | PKI-05 → APP-04, APP-05, APP-06 → All OPS |

## Supported Algorithms

### Classical (Production)
- ECDSA P-256, P-384, P-521
- RSA 2048, 4096
- Ed25519

### Post-Quantum (Experimental)
- **ML-DSA** (FIPS 204) — Lattice-based signatures
- **SLH-DSA** (FIPS 205) — Hash-based signatures
- **ML-KEM** (FIPS 203) — Key encapsulation

### Hybrid
- **Catalyst certificates** (ITU-T X.509 9.8)
- Composite certificates (IETF draft-lamps-pq-composite-*) — *not yet supported*

## Requirements

- Go 1.21+ (for building the PKI tool)
- OpenSSL 3.x (for verification demos)
- Docker (optional, for isolated environments)

## Project Structure

```
post-quantum-pki-lab/
├── usecases/
│   ├── pki/                # PKI fundamentals (5 UC)
│   ├── applications/       # Real-world applications (7 UC)
│   ├── ops/                # Ops & Migration (3 UC)
│   └── _archive/           # Previous UC versions
├── tooling/                # Installation scripts
├── lib/                    # Shared shell functions
├── docker/                 # Container environments
└── assets/                 # Diagrams and branding
```

## About

This project is part of the **Quantum-Safe PKI** initiative by **QentriQ**.

**Need help with your PQC transition?** [Contact us](https://qentriq.com)

## License

Apache License 2.0 — See [LICENSE](LICENSE)
