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

| # | Name | Title | Duration | Audience |
|---|------|-------|----------|----------|
| 01 | TLS Server Certificate | ["Nothing changes... except the algorithm"](usecases/01-classic-vs-pqc-tls/) | 5 min | Developers |
| 02 | Hybrid Certificate (Catalyst) | "Hybrid = best of both worlds" | 10 min | Security Architects |
| 03 | Long-Term Encryption | "The real problem: Store Now, Decrypt Later" | 8 min | CISOs |
| 04 | Revocation & Incident | "PKI operations don't change" | 5 min | Operations |
| 05 | Full PQC PKI | "Full post-quantum chain of trust" | 10 min | Visionaries |
| 06 | Code Signing | "Code signing for 30 years" | 8 min | IoT/Defense |
| 07 | Certificate Bundles | "Smooth rotation with bundles" | 10 min | Architects |
| 08 | PQC Timestamping | "Trust Now, Verify Forever" | 10 min | Legal/AI/Compliance |

## Quick Start

```bash
# Install the PKI tool
./tooling/install.sh

# Run your first demo
cd usecases/01-classic-vs-pqc-tls
./demo.sh
```

## Learning Paths

```
         BEGINNER (Everyone) - 2-3h
                  |
       +----------+----------+
       |          |          |
   DEVELOPER   SECURITY   EXECUTIVE
     8-10h      10-12h       2-3h
       |          |          |
       +----------+          |
            |               END
         ADVANCED
          15h+
```

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
- Catalyst certificates (ITU-T X.509 9.8)
- Composite certificates

## Requirements

- Go 1.21+ (for building the PKI tool)
- OpenSSL 3.x (for verification demos)
- Docker (optional, for isolated environments)

## Project Structure

```
post-quantum-pki-lab/
├── usecases/           # Educational use cases
├── tooling/            # Installation scripts
├── lib/                # Shared shell functions
├── docker/             # Container environments
├── notebooks/          # Jupyter analysis
└── assets/             # Diagrams and branding
```

## About

This project is part of the **Quantum-Safe PKI** initiative by **QentriQ**.

**Need help with your PQC transition?** [Contact us](https://qentriq.com)

## License

Apache License 2.0 — See [LICENSE](LICENSE)
