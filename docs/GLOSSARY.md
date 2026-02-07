---
title: "Glossary"
description: "PKI and post-quantum cryptography terminology"
---

# Glossary

## Cryptographic Algorithms

| Term | Definition |
|------|------------|
| **ML-DSA** | Module-Lattice Digital Signature Algorithm (FIPS 204). Post-quantum signature scheme based on lattices. Replaces RSA/ECDSA for signatures. |
| **ML-KEM** | Module-Lattice Key Encapsulation Mechanism (FIPS 203). Post-quantum key exchange. Replaces ECDH/RSA for key establishment. |
| **SLH-DSA** | Stateless Hash-based Digital Signature Algorithm (FIPS 205). Post-quantum signature based on hash functions. Conservative alternative to ML-DSA. |
| **ECDSA** | Elliptic Curve Digital Signature Algorithm. Classical signature scheme vulnerable to quantum attacks. |
| **ECDH** | Elliptic Curve Diffie-Hellman. Classical key exchange vulnerable to quantum attacks. |
| **X25519** | Curve25519-based key exchange. Fast classical algorithm, vulnerable to quantum. |
| **Ed25519** | Edwards-curve Digital Signature Algorithm. Fast classical signatures, vulnerable to quantum. |

## PKI Concepts

| Term | Definition |
|------|------------|
| **CA** | Certificate Authority. Entity that issues and signs digital certificates. |
| **Root CA** | Top-level CA in a hierarchy. Self-signed, trust anchor. |
| **Issuing CA** | Intermediate CA that issues end-entity certificates. Signed by Root CA. |
| **CRL** | Certificate Revocation List. Signed list of revoked certificate serial numbers. |
| **OCSP** | Online Certificate Status Protocol. Real-time certificate validity check. |
| **TSA** | Timestamp Authority. Trusted service that provides cryptographic proof of when data existed (RFC 3161). |
| **CSR Attestation** | RFC 9883 mechanism where a signing certificate attests for a KEM key that cannot sign its own CSR. |
| **mTLS** | Mutual TLS. Both client and server authenticate with certificates. |
| **SAN** | Subject Alternative Name. Certificate extension for multiple identities (DNS, IP, email). |

## Post-Quantum Concepts

| Term | Definition |
|------|------------|
| **PQC** | Post-Quantum Cryptography. Algorithms resistant to quantum computer attacks. |
| **SNDL** | Store Now, Decrypt Later. Threat where adversaries capture encrypted data today to decrypt with future quantum computers. |
| **TNFL** | Trust Now, Forge Later. Threat where classical signatures can be forged retroactively once quantum computers exist. |
| **Hybrid** | Combining classical + post-quantum algorithms for defense in depth. |
| **Catalyst** | ITU-T X.509 9.8 hybrid certificate format with dual signatures. |
| **Composite** | Alternative hybrid format combining keys/signatures into single objects. |
| **Crypto-Agility** | Ability to switch cryptographic algorithms without major infrastructure changes. |
| **LTV** | Long-Term Validation. Signatures that remain verifiable for decades. |

## Certificate Types

| Term | Definition |
|------|------------|
| **TLS Certificate** | Server identity certificate for HTTPS/TLS connections. |
| **Client Certificate** | End-user or device identity for mTLS authentication. |
| **Code Signing** | Certificate for signing software releases. |
| **Timestamping** | Certificate for trusted time authority (TSA). |
| **KEM Certificate** | Certificate containing ML-KEM public key for key encapsulation. |

## Standards

| Term | Definition |
|------|------------|
| **FIPS 203** | NIST standard for ML-KEM (key encapsulation). |
| **FIPS 204** | NIST standard for ML-DSA (digital signatures). |
| **FIPS 205** | NIST standard for SLH-DSA (hash-based signatures). |
| **X.509** | ITU-T standard for public key certificates. |
| **RFC 3161** | Time-Stamp Protocol (TSP). Standard for trusted timestamping services. |
| **RFC 9883** | Use of Post-Quantum KEM in CMS. Defines CSR attestation for KEM keys. |
| **CMS** | Cryptographic Message Syntax (RFC 5652). Format for signed/encrypted data. |
| **S/MIME** | Secure email standard using CMS. |
