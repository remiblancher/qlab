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

## Installation

```bash
git clone https://github.com/remiblancher/post-quantum-pki-lab.git
cd post-quantum-pki-lab
./tooling/install.sh
```

Then start with: `./journey/00-quickstart/demo.sh`

---

## Learning Path

**Total time: ~2h** | **Minimum path: 18 min** (Quick Start + Revelation)

### 🚀 Getting Started

| # | Mission | Time |
|---|---------|------|
| 0 | [**Quick Start**](journey/00-quickstart/) — Create your first CA (ECDSA) | 10 min |
| 1 | [**The Revelation**](journey/01-revelation/) — Why PQC matters (SNDL threat) | 8 min |

### 📚 Core PKI

| # | Mission | Time |
|---|---------|------|
| 2 | [**Full PQC Chain**](journey/02-full-chain/) — Root → Issuing → TLS (ML-DSA) | 10 min |
| 3 | [**Hybrid Catalyst**](journey/03-hybrid/) — Dual-key certificate (ECDSA + ML-DSA) | 10 min |

### ⚙️ PKI Lifecycle

| # | Mission | Time |
|---|---------|------|
| 4 | [**Revocation**](journey/04-revocation/) — CRL generation | 10 min |
| 5 | [**PQC OCSP**](journey/05-ocsp/) — Is This Cert Still Good? | 10 min |

### 🔧 Applications

| # | Mission | Time |
|---|---------|------|
| 6 | [**Code Signing**](journey/06-code-signing/) — Sign your releases (ML-DSA) | 8 min |
| 7 | [**Timestamping**](journey/07-timestamping/) — Proof of existence (ML-DSA) | 8 min |
| 8 | [**LTV Signatures**](journey/08-ltv-signatures/) — Valid in 30 years | 8 min |
| 9 | [**CMS Encryption**](journey/09-cms-encryption/) — Encrypt documents (ML-KEM) | 8 min |

### 🎯 Advanced

> Requires Docker and server infrastructure.

| # | Mission | Time |
|---|---------|------|
| 10 | [**Crypto-Agility**](journey/10-crypto-agility/) — Migrate ECDSA → ML-DSA | 10 min |
| 11 | [**mTLS**](journey/11-mtls/) — Mutual authentication with Docker | 10 min |
| 12 | [**PQC Tunnel**](journey/12-pqc-tunnel/) — Key exchange demo (ML-KEM) | 8 min |

---

## Project Structure

```
post-quantum-pki-lab/
├── journey/                    # Guided demos (linear progression)
│   ├── 00-quickstart/          # Quick Start
│   ├── 01-revelation/          # The Quantum Threat
│   ├── 02-full-chain/          # Full PQC Chain
│   ├── 03-hybrid/              # Hybrid Certificates
│   ├── 04-revocation/          # Revocation (CRL)
│   ├── 05-ocsp/                # OCSP
│   ├── 06-code-signing/        # Code Signing
│   ├── 07-timestamping/        # Timestamping
│   ├── 08-ltv-signatures/      # LTV Signatures
│   ├── 09-cms-encryption/      # CMS Encryption
│   ├── 10-crypto-agility/      # Crypto-Agility
│   ├── 11-mtls/                # mTLS (Docker)
│   └── 12-pqc-tunnel/          # PQC Tunnel
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

## Workspace

Each level has its own workspace. Your CAs and certificates are preserved between sessions.

```bash
# Reset a specific level
./reset.sh quickstart
./reset.sh level-1

# Reset all workspaces
./reset.sh all
```

---

## Useful Links

- [Glossary](docs/GLOSSARY.md) — PQC and PKI terminology
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
