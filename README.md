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

> 🎯 **When Should You Start?**
> PQC migration takes 2–5 years. Your data's confidentiality requirement determines urgency.
> [Calculate your timeline →](journey/00-revelation/)

---

## Installation

### macOS / Linux

```bash
git clone https://github.com/remiblancher/post-quantum-pki-lab.git
cd post-quantum-pki-lab
./tooling/install.sh
```

### Windows (PowerShell)

```powershell
git clone https://github.com/remiblancher/post-quantum-pki-lab.git
cd post-quantum-pki-lab
.\tooling\install.ps1
```

> **Note:** The demos require a bash shell. Use [Git Bash](https://git-scm.com/downloads) or [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) to run them.

Then start with: `./journey/00-revelation/demo.sh`

**Requirements:** OpenSSL 3.x (for demo verification commands)

---

## Learning Path

**Total time: ~2h** | **Quick path: 20 min** (Revelation + Quick Start)

### 🗺️ Journey Map

```
┌─────────────────────────────────────────────────────────────────┐
│  AWARENESS              BUILD                    LIFECYCLE      │
│  ┌──────┐ ┌──────┐      ┌──────┐ ┌──────┐    ┌──────┐ ┌──────┐ │
│  │UC-00 │→│UC-01 │  →   │UC-02 │→│UC-03 │ →  │UC-04 │→│UC-05 │ │
│  │Why?  │ │How?  │      │Chain │ │Hybrid│    │CRL   │ │OCSP  │ │
│  └──────┘ └──────┘      └──────┘ └──────┘    └──────┘ └──────┘ │
│                                                       ↓        │
│  MIGRATION              ENCRYPTION           LONG-TERM SIGS    │
│  ┌──────┐               ┌──────┐            ┌──────┬──────┬────┐│
│  │UC-10 │  ←            │UC-09 │    ←       │UC-06 │UC-07 │UC-08│
│  │Agility│              │KEM   │            │Sign  │Time  │LTV ││
│  └──────┘               └──────┘            └──────┴──────┴────┘│
└─────────────────────────────────────────────────────────────────┘
```

---

### 🚀 Awareness

| # | Lab | Time | Takeaway |
|---|-----|------|----------|
| 0 | [**The Revelation**](journey/00-revelation/) | 10 min | Your data is already being recorded |
| 1 | [**Quick Start**](journey/01-quickstart/) | 10 min | Same workflow, just different algorithms |

↓ *Let's build!*

### 📚 Build

| # | Lab | Time | Takeaway |
|---|-----|------|----------|
| 2 | [**Full PQC Chain**](journey/02-full-chain/) | 10 min | Build a 100% PQC chain |
| 3 | [**Hybrid Catalyst**](journey/03-hybrid/) | 10 min | Or hybrid to coexist with legacy |

↓ *PKI operations stay identical*

### ⚙️ Lifecycle

| # | Lab | Time | Takeaway |
|---|-----|------|----------|
| 4 | [**Revocation**](journey/04-revocation/) | 10 min | Revoke = same command |
| 5 | [**OCSP**](journey/05-ocsp/) | 10 min | Verify = same protocol |

↓ *Sign, timestamp, archive for decades*

### 💼 Long-Term Signatures

| # | Lab | Time | Takeaway |
|---|-----|------|----------|
| 6 | [**Code Signing**](journey/06-code-signing/) | 10 min | Signatures that outlive the threat |
| 7 | [**Timestamping**](journey/07-timestamping/) | 15 min | Prove WHEN, forever |
| 8 | [**LTV**](journey/08-ltv-signatures/) | 15 min | Bundle proofs for offline verification |

↓ *Except for encryption...*

### 🔐 Encryption

| # | Lab | Time | Takeaway |
|---|-----|------|----------|
| 9 | [**CMS Encryption**](journey/09-cms-encryption/) | 15 min | KEM keys require a new pattern: attestation |

↓ *And for production migration?*

### 🧭 Migration

| # | Lab | Time | Takeaway |
|---|-----|------|----------|
| 10 | [**Crypto-Agility**](journey/10-crypto-agility/) | 15 min | CA versioning + trust bundles |

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

## Resources

- [QPKI - Post-Quantum PKI](https://github.com/remiblancher/post-quantum-pki) — The PKI toolkit used by QLAB
- [Glossary](docs/GLOSSARY.md) — PQC and PKI terminology
- [Troubleshooting](docs/TROUBLESHOOTING.md) — Common issues and solutions
- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [FIPS 203 (ML-KEM)](https://csrc.nist.gov/pubs/fips/203/final)
- [FIPS 204 (ML-DSA)](https://csrc.nist.gov/pubs/fips/204/final)
- [ITU-T X.509 (Hybrid Certificates)](https://www.itu.int/rec/T-REC-X.509)

---

## License

Apache License 2.0 — See [LICENSE](LICENSE)
