# QLAB

**Post-Quantum PKI Lab**

> **"The PKI is the tool for transition — post-quantum is an engineering problem, not magic."**

QLAB is an educational resource to help teams understand PKI and Post-Quantum Cryptography (PQC) migration through hands-on practice.

- **Lab exercises** — Learn PQC migration with real scenarios
- **Interactive demos** — Quantum-safe certificate operations
- **Step-by-step journeys** — From classical to post-quantum PKI

QLAB uses **[QPKI](https://github.com/remiblancher/post-quantum-pki)** for all PKI operations.

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

> ⏰ **The Clock is Ticking**
> Your 2024 TLS traffic is being recorded right now. In 2035, it could be plaintext.
> How long must your data stay secret? [Calculate your urgency →](journey/01-revelation/)

---

## Installation

**Requirements:** Go 1.25+, OpenSSL 3.x

```bash
git clone https://github.com/remiblancher/post-quantum-pki-lab.git
cd post-quantum-pki-lab
./tooling/install.sh
```

Then start with: `./journey/00-quickstart/demo.sh`

---

## Learning Path

**Total time: ~1h45** | **Minimum path: 20 min** (Quick Start + Revelation)

### 🧭 Story Arc

```
UC-00: "Same workflow, but PKI must evolve"
         │
         ▼ Why evolve?
UC-01: "Your data is already being recorded"
         │
         ▼ How to evolve?
UC-02: "Build a 100% PQC chain"
UC-03: "Or hybrid to coexist with legacy"
         │
         ▼ PKI evolves, but operations stay identical
UC-04/05: "Revoke, verify = same commands"
UC-06/07/08: "Sign, timestamp, archive = same workflows"
         │
         ▼ Except for encryption...
UC-09: "KEM keys require a new pattern: attestation"
         │
         ▼ And for production migration?
UC-10: "Crypto-agility = CA versioning + trust bundles"
```

### 🚀 Getting Started

| # | Mission | Time | Key Message |
|---|---------|------|-------------|
| 0 | [**Quick Start**](journey/00-quickstart/) — Create your first CA | 10 min | Same commands, evolved PKI. Multi-algorithm support is the new baseline. |
| 1 | [**The Revelation**](journey/01-revelation/) — Why PQC matters? | 10 min | Your data is already being recorded. The clock is ticking. |

### 📚 Core PKI

| # | Mission | Time | Key Message |
|---|---------|------|-------------|
| 2 | [**Full PQC Chain**](journey/02-full-chain/) — Root → Issuing → TLS (ML-DSA) | 10 min | End-to-end PQC chain = same architecture, quantum-safe. |
| 3 | [**Hybrid Catalyst**](journey/03-hybrid/) — Dual-key certificate (ECDSA + ML-DSA) | 10 min | Hybrid = parallel algorithms. Legacy and PQC coexist. |

### ⚙️ PKI Lifecycle

| # | Mission | Time | Key Message |
|---|---------|------|-------------|
| 4 | [**Revocation**](journey/04-revocation/) — CRL generation | 10 min | Revoking PQC certs = same command, same workflow. |
| 5 | [**PQC OCSP**](journey/05-ocsp/) — Is This Cert Still Good? | 10 min | OCSP real-time status = same HTTP protocol. |

### 💼 Real-World Applications

| # | Mission | Time | Key Message |
|---|---------|------|-------------|
| 6 | [**PQC Code Signing**](journey/06-code-signing/) — Signatures That Outlive the Threat | 10 min | Code signatures live 10-30 years. PQC makes them unforgeable. |
| 7 | [**PQC Timestamping**](journey/07-timestamping/) — Trust Now, Verify Forever | 10 min | Timestamps prove WHEN — even after cert expiration. |
| 8 | [**PQC LTV**](journey/08-ltv-signatures/) — Sign Today, Verify in 30 Years | 10 min | LTV bundles all proofs for offline verification in 2055. |
| 9 | [**CMS Encryption**](journey/09-cms-encryption/) — Encrypt documents (ML-KEM) | 10 min | KEM keys can't sign. Attestation links encryption to identity. |

### 🧭 Architecture & Migration

| # | Mission | Time | Key Message |
|---|---------|------|-------------|
| 10 | [**Crypto-Agility**](journey/10-crypto-agility/) — Migrate ECDSA → ML-DSA | 15 min | Crypto-agility = reversible migration via CA versioning. |

> 💡 **After UC-01**, you'll understand WHY migration is urgent.
> Continue to UC-02+ to learn HOW to do it.

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

## Useful Links

- [QPKI - Post-Quantum PKI](https://github.com/remiblancher/post-quantum-pki) — The PKI toolkit used by QLAB
- [Glossary](docs/GLOSSARY.md) — PQC and PKI terminology
- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [FIPS 203 (ML-KEM)](https://csrc.nist.gov/pubs/fips/203/final)
- [FIPS 204 (ML-DSA)](https://csrc.nist.gov/pubs/fips/204/final)
- [ITU-T X.509 (Hybrid Certificates)](https://www.itu.int/rec/T-REC-X.509)

---

## License

Apache License 2.0 — See [LICENSE](LICENSE)
