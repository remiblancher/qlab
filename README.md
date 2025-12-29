# Post-Quantum PKI Lab (QLAB)

> **"The PKI is the tool for transition — post-quantum is an engineering problem, not magic."**

Educational demonstrations for transitioning to Post-Quantum Cryptography using a real PKI implementation.

> **QLAB** is built on top of **[QPKI (Post-Quantum PKI)](https://github.com/remiblancher/post-quantum-pki)**, which provides the underlying PKI toolkit for all certificate authority operations, key generation, and cryptographic functions. QPKI is an external dependency.

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
- **Hybrid certificates provide a quantum-safe migration path** — protect legacy and future clients
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

**Total time: ~1h40** | **Minimum path: 15 min** (Quick Start + Revelation)

### 🚀 Getting Started

| # | Mission | Time | Key Message |
|---|---------|------|-------------|
| 0 | [**Quick Start**](journey/00-quickstart/) — Create your first CA | 8 min | Quantum breaks algorithms, not PKI workflows. Migration is configuration, not redesign. |
| 1 | [**The Revelation**](journey/01-revelation/) — Why PQC matters? | 7 min | Quantum attacks are passive and retroactive. Today's encrypted data is tomorrow's plaintext. |

### 📚 Core PKI

| # | Mission | Time | Key Message |
|---|---------|------|-------------|
| 2 | [**Full PQC Chain**](journey/02-full-chain/) — Root → Issuing → TLS (ML-DSA) | 10 min | One classical link breaks the entire chain. PQC must be end-to-end. |
| 3 | [**Hybrid Catalyst**](journey/03-hybrid/) — Dual-key certificate (ECDSA + ML-DSA) | 10 min | Hybrid bridges legacy and quantum-safe. Security fails only if both algorithms fail. |

### ⚙️ PKI Lifecycle

| # | Mission | Time | Key Message |
|---|---------|------|-------------|
| 4 | [**Revocation**](journey/04-revocation/) — CRL generation | 8 min | PQC keys get compromised too. Revocation works exactly the same. |
| 5 | [**PQC OCSP**](journey/05-ocsp/) — Is This Cert Still Good? | 8 min | OCSP reports trust in real-time. PQC doesn't change how revocation is checked. |

### 🔧 Applications

| # | Mission | Time | Key Message |
|---|---------|------|-------------|
| 6 | [**PQC Code Signing**](journey/06-code-signing/) — Signatures That Outlive the Threat | 8 min | Signatures must outlive algorithms. Quantum makes forgery undetectable. |
| 7 | [**PQC Timestamping**](journey/07-timestamping/) — Trust Now, Verify Forever | 8 min | Timestamps prove WHEN. Without PQC, that proof becomes forgeable. |
| 8 | [**PQC LTV**](journey/08-ltv-signatures/) — Sign Today, Verify in 30 Years | 10 min | LTV bundles all proofs for offline verification. Every element must be quantum-safe. |
| 9 | [**CMS Encryption**](journey/09-cms-encryption/) — Encrypt documents (ML-KEM) | 10 min | KEM keys can't sign. Attestation links encryption keys to identity. |

### 🧭 Architecture & Migration

| # | Mission | Time | Key Message |
|---|---------|------|-------------|
| 10 | [**Crypto-Agility**](journey/10-crypto-agility/) — Migrate ECDSA → ML-DSA | 12 min | Quantum timelines are uncertain. Crypto-agility means reversible migration. |

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
│   └── 10-crypto-agility/      # Crypto-Agility
├── reference/usecases/         # Reference documentation
├── lib/                        # Shell helpers
└── bin/qpki                    # QPKI tool (Post-Quantum PKI)
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
- Composite certificates *(supported, no lab demo)*

---

## Requirements

- **Go 1.21+** (for building QPKI from source)
- **OpenSSL 3.x** (for verification demos)
- **Docker** (optional, for isolated environments)

---

## Useful Links

- [QPKI - Post-Quantum PKI](https://github.com/remiblancher/post-quantum-pki) — The PKI toolkit used by QLAB
- [Glossary](docs/GLOSSARY.md) — PQC and PKI terminology
- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [FIPS 203 (ML-KEM)](https://csrc.nist.gov/pubs/fips/203/final)
- [FIPS 204 (ML-DSA)](https://csrc.nist.gov/pubs/fips/204/final)
- [ITU-T X.509 (Hybrid Certificates)](https://www.itu.int/rec/T-REC-X.509)

---

## About

**QLAB** (Post-Quantum PKI Lab) is an educational resource to help teams understand PKI and Post-Quantum Cryptography (PQC) migration through hands-on practice.

QLAB provides:
- Lab exercises and scenarios for learning PQC migration
- Interactive demonstrations of quantum-safe certificate operations
- Step-by-step journeys from classical to post-quantum PKI

QLAB uses **[QPKI (Post-Quantum PKI)](https://github.com/remiblancher/post-quantum-pki)** for all PKI operations including:
- Certificate Authority (CA) management
- Certificate generation and issuance
- Post-Quantum Cryptography (PQC) algorithms
- Hybrid certificate support

## License

Apache License 2.0 — See [LICENSE](LICENSE)
