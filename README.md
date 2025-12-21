# Post-Quantum PKI Lab

> **"The PKI is the tool for transition — post-quantum is an engineering problem, not magic."**

Educational demonstrations for transitioning to Post-Quantum Cryptography using a real PKI implementation.

---

## Why This Matters

Quantum computers will eventually break RSA and ECC cryptography. The question isn't *if*, but *when*. Organizations need to prepare now — not panic, but plan.

This lab demonstrates:
- **Classical and post-quantum PKI work the same way**
- **Hybrid certificates provide a safe migration path**
- **The PKI model is algorithm-agnostic**

---

## Quick Start

```bash
# 1. Clone and install
git clone https://github.com/remiblancher/post-quantum-pki-lab.git
cd post-quantum-pki-lab
./tooling/install.sh

# 2. Launch menu
./start.sh

# 3. Or directly the Quick Start (10 min)
./quickstart/demo.sh
```

---

## Learning Path

**Total time: ~2h** | **Minimum path: 18 min** (Quick Start + Revelation)

### 🚀 Getting Started

| # | Mission | Time |
|---|---------|------|
| 0 | [**Quick Start**](quickstart/) — Create your first CA (ECDSA) | 10 min |
| 1 | [**The Revelation**](journey/00-revelation/) — Why PQC matters (SNDL threat) | 8 min |

### 📚 Level 1: PQC Basics

| # | Mission | Time |
|---|---------|------|
| 2 | [**Full PQC Chain**](journey/01-pqc-basics/01-full-chain/) — Root → Issuing → TLS (ML-DSA) | 10 min |
| 3 | [**Hybrid Catalyst**](journey/01-pqc-basics/02-hybrid/) — Dual-key certificate (ECDSA + ML-DSA) | 10 min |

### 🔧 Level 2: Applications

| # | Mission | Time |
|---|---------|------|
| 4 | [**mTLS**](journey/02-applications/01-mtls/) — Mutual authentication (ML-DSA) | 8 min |
| 5 | [**Code Signing**](journey/02-applications/02-code-signing/) — Sign your releases (ML-DSA) | 8 min |
| 6 | [**Timestamping**](journey/02-applications/03-timestamping/) — Proof of existence (ML-DSA) | 8 min |

### ⚙️ Level 3: Ops & Lifecycle

| # | Mission | Time |
|---|---------|------|
| 7 | [**Revocation**](journey/03-ops-lifecycle/01-revocation/) — CRL generation (Hybrid) | 10 min |
| 8 | [**OCSP**](journey/03-ops-lifecycle/02-ocsp/) — Real-time status (Hybrid) | 10 min |
| 9 | [**Crypto-Agility**](journey/03-ops-lifecycle/03-crypto-agility/) — Migrate ECDSA → ML-DSA | 10 min |

### 🎯 Level 4: Advanced (Optional)

> These missions are optional and exploratory. You can stop at Level 3 without losing the main thread.

| # | Mission | Time |
|---|---------|------|
| 10 | [**LTV Signatures**](journey/04-advanced/01-ltv-signatures/) — Valid in 30 years (Hybrid) | 8 min |
| 11 | [**PQC Tunnel**](journey/04-advanced/02-pqc-tunnel/) — Key exchange demo (ML-KEM) | 8 min |
| 12 | [**CMS Encryption**](journey/04-advanced/03-cms-encryption/) — Encrypt documents (ML-KEM) | 8 min |

---

## Project Structure

```
post-quantum-pki-lab/
├── start.sh                    # Main menu
├── quickstart/                 # Quick Start (10 min)
│   ├── demo.sh
│   └── README.md
├── journey/                    # Guided journey
│   ├── 00-revelation/          # "Store Now, Decrypt Later"
│   ├── 01-pqc-basics/          # "Build Your Foundation" + "Best of Both"
│   ├── 02-applications/        # mTLS, Code Signing, Timestamping
│   ├── 03-ops-lifecycle/       # Revocation, OCSP, Crypto-Agility
│   └── 04-advanced/            # LTV, PQC Tunnel, CMS
├── workspace/                  # Your artifacts (persistent)
│   ├── quickstart/             # Classic CA
│   ├── level-1/                # PQC CA + Hybrid CA
│   ├── level-2/                # Signatures, timestamps
│   ├── level-3/                # CRL, OCSP
│   └── level-4/                # LTV, tunnels
├── reference/usecases/         # Reference documentation
├── lib/                        # Shell helpers
└── bin/pki                     # PKI tool (Go)
```

---

## Supported Algorithms

### Classical (Production)
- ECDSA P-256, P-384, P-521
- RSA 2048, 4096
- Ed25519

### Post-Quantum (Experimental)
- **ML-DSA** (FIPS 204) — Lattice-based signatures
- **SLH-DSA** (FIPS 205) — Hash-based signatures
- **ML-KEM** (FIPS 203) — Key encapsulation

### Hybrid (Experimental)
- Catalyst certificates (ITU-T X.509 9.8)
- Composite certificates *(not yet implemented)*

---

## Requirements

- **Go 1.21+** (for building the PKI tool)
- **OpenSSL 3.x** (for verification demos)
- **Docker** (optional, for isolated environments)

---

## Interactive Mode

This lab uses an interactive mode where you type the important commands:

```bash
┌─────────────────────────────────────────────────────────────────┐
│  MISSION 1: Create your CA                                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  A CA (Certificate Authority) is the trust anchor.             │
│  It signs all your certificates.                                │
│                                                                 │
│  >>> Type this command:                                         │
│                                                                 │
│      pki init-ca --name "My CA" --algorithm ml-dsa-65          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

$ pki init-ca --name "My CA" --algorithm ml-dsa-65
✓ CA created: ca.crt (ML-DSA-65)
```

Complex commands are executed automatically with explanation.

---

## Persistent Workspace

Each level has its own workspace. Your CAs and certificates are preserved between sessions:

```bash
# View workspace status
./start.sh  # then option "s"

# Reset a level
./start.sh  # then option "r"
```

---

## Useful Links

- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [FIPS 203 (ML-KEM)](https://csrc.nist.gov/pubs/fips/203/final)
- [FIPS 204 (ML-DSA)](https://csrc.nist.gov/pubs/fips/204/final)
- [ITU-T X.509 (Hybrid Certificates)](https://www.itu.int/rec/T-REC-X.509)

---

## About

This project is part of the Quantum-Safe PKI initiative by [QentriQ](https://qentriq.com).

Need help with your PQC transition? [Contact us](https://qentriq.com)

## License

Apache License 2.0 — See [LICENSE](LICENSE)
