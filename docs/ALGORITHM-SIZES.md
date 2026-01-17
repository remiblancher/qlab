# PQC Algorithm Sizes Reference

Technical reference for NIST post-quantum algorithm variants.

## ML-KEM (FIPS 203) — Key Encapsulation

| Variant | Security Level | Public Key | Ciphertext | Shared Secret |
|---------|----------------|------------|------------|---------------|
| ML-KEM-512 | Level 1 | 800 B | 768 B | 32 B |
| ML-KEM-768 | Level 3 | 1,184 B | 1,088 B | 32 B |
| ML-KEM-1024 | Level 5 | 1,568 B | 1,568 B | 32 B |

## ML-DSA (FIPS 204) — Digital Signatures

| Variant | Security Level | Public Key | Signature |
|---------|----------------|------------|-----------|
| ML-DSA-44 | Level 2 | 1,312 B | 2,420 B |
| ML-DSA-65 | Level 3 | 1,952 B | 3,309 B |
| ML-DSA-87 | Level 5 | 2,592 B | 4,627 B |

## SLH-DSA (FIPS 205) — Hash-Based Signatures

| Variant | Security Level | Public Key | Signature |
|---------|----------------|------------|-----------|
| SLH-DSA-128s | Level 1 | 32 B | 7,856 B |
| SLH-DSA-128f | Level 1 | 32 B | 17,088 B |
| SLH-DSA-192s | Level 3 | 48 B | 16,224 B |
| SLH-DSA-192f | Level 3 | 48 B | 35,664 B |
| SLH-DSA-256s | Level 5 | 64 B | 29,792 B |
| SLH-DSA-256f | Level 5 | 64 B | 49,856 B |

*s = small signature (slower), f = fast signing (larger signature)*

## Security Levels

| Level | Classical Equivalent | Use Case |
|-------|---------------------|----------|
| Level 1 | AES-128 | Standard security |
| Level 3 | AES-192 | Recommended default |
| Level 5 | AES-256 | Maximum security |
