# Post-Quantum PKI Lab

> **"The PKI is the tool for transition — post-quantum is an engineering problem, not magic."**

Educational demonstrations for transitioning to Post-Quantum Cryptography using a real PKI implementation.

---

## Why This Matters

Quantum computers will eventually break RSA and ECC cryptography.
The question isn't *if*, but *when* — and whether your data and signatures
will still need to be trusted **after that moment**.

This matters today because:

- **Store Now, Decrypt Later (SNDL):** Encrypted data captured now can be decrypted later
- **Trust Now, Forge Later (TNFL):** Software signatures must remain valid for 10–30 years
- **Long-term records:** Legal, medical, and industrial records outlive cryptographic algorithms

This lab demonstrates:
- **Classical and post-quantum PKI work the same way** — only the algorithm changes
- **Hybrid certificates provide a safe migration path** — protect legacy and future clients
- **The PKI model is algorithm-agnostic** — your workflow stays exactly the same

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

**Total time: ~2h** | **Minimum path: 15 min** (Quick Start + Revelation)

### 🚀 Getting Started

| # | Mission | Time | Key Message |
|---|---------|------|-------------|
| 0 | [**Quick Start**](journey/00-quickstart/) — Create your first CA | 8 min | The PKI doesn't change. Only the algorithm changes. |
| 1 | [**The Revelation**](journey/01-revelation/) — Why PQC matters? | 7 min | The attack requires no hacking — just recording traffic. |

### 📚 Core PKI

| # | Mission | Time | Key Message |
|---|---------|------|-------------|
| 2 | [**Full PQC Chain**](journey/02-full-chain/) — Root → Issuing → TLS (ML-DSA) | 10 min | A complete PQC chain is no harder to build than a classical one. |
| 3 | [**Hybrid Catalyst**](journey/03-hybrid/) — Dual-key certificate (ECDSA + ML-DSA) | 10 min | You cannot upgrade all clients at once — but certificates can. |

### ⚙️ PKI Lifecycle

| # | Mission | Time | Key Message |
|---|---------|------|-------------|
| 4 | [**Revocation**](journey/04-revocation/) — CRL generation | 8 min | Revocation is a state change. CRL is its distribution. |
| 5 | [**PQC OCSP**](journey/05-ocsp/) — Is This Cert Still Good? | 8 min | OCSP reports revocation status. It does not revoke. |

### 🔧 Applications

| # | Mission | Time | Key Message |
|---|---------|------|-------------|
| 6 | [**PQC Code Signing**](journey/06-code-signing/) — Signatures That Outlive the Threat | 8 min | A forged signature is indistinguishable from a legitimate one. |
| 7 | [**PQC Timestamping**](journey/07-timestamping/) — Trust Now, Verify Forever | 8 min | Timestamps prove WHEN. They don't prove validity. |
| 8 | [**PQC LTV**](journey/08-ltv-signatures/) — Sign Today, Verify in 30 Years | 10 min | A signature is only as good as its proof chain. |
| 9 | [**CMS Encryption**](journey/09-cms-encryption/) — Encrypt documents (ML-KEM) | 10 min | You cannot prove KEM key possession by signing (RFC 9883). |

### 🎯 Advanced

> Requires Docker and server infrastructure.

| # | Mission | Time | Key Message |
|---|---------|------|-------------|
| 10 | [**Crypto-Agility**](journey/10-crypto-agility/) — Migrate ECDSA → ML-DSA | 12 min | Crypto-agility is an architectural property, not a tool. |
| 11 | [**mTLS**](journey/11-mtls/) — Mutual authentication with Docker | 12 min | PQC certificates work in standard TLS stacks. |
| 12 | [**PQC Tunnel**](journey/12-pqc-tunnel/) — Key exchange demo (ML-KEM) | 8 min | ML-KEM protects data in transit. CMS protects data at rest. |

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

### Post-Quantum (NIST Standards 2024)
- **ML-DSA** (FIPS 204) — Lattice-based signatures
- **SLH-DSA** (FIPS 205) — Hash-based signatures
- **ML-KEM** (FIPS 203) — Key encapsulation

*Standards finalized in 2024, ecosystem still maturing.*

### Hybrid (Transition)
- Catalyst certificates (ITU-T X.509 9.8)
- Composite certificates *(not yet implemented)*

---

## Requirements

- **Go 1.21+** (for building the PKI tool)
- **OpenSSL 3.x** (for verification demos)
- **Docker** (optional, for isolated environments)

---

## Useful Links

- [Glossary](docs/GLOSSARY.md) — PQC and PKI terminology
- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [FIPS 203 (ML-KEM)](https://csrc.nist.gov/pubs/fips/203/final)
- [FIPS 204 (ML-DSA)](https://csrc.nist.gov/pubs/fips/204/final)
- [ITU-T X.509 (Hybrid Certificates)](https://www.itu.int/rec/T-REC-X.509)

---

## About

An **educational resource** to help teams understand PQC migration through hands-on practice.

## License

Apache License 2.0 — See [LICENSE](LICENSE)
