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

## Performance Benchmarks

*Source: [arXiv:2503.12952](https://arxiv.org/abs/2503.12952) (2025), CPU @ 3.3 GHz*

### ML-DSA vs ECDSA (Signatures)

| Algorithm | KeyGen | Sign | Verify | Total |
|-----------|--------|------|--------|-------|
| ML-DSA-44 | 0.09 ms | 0.45 ms | 0.10 ms | 0.64 ms |
| ML-DSA-65 | 0.15 ms | 0.70 ms | 0.15 ms | 0.99 ms |
| ML-DSA-87 | 0.25 ms | 0.84 ms | 0.27 ms | 1.36 ms |
| ECDSA P-256 | 0.30 ms | 0.40 ms | 0.10 ms | 0.80 ms |
| ECDSA P-384 | 0.50 ms | 0.90 ms | 0.30 ms | 1.70 ms |

### Direct Comparison (Security Level 3: ML-DSA-65 vs ECDSA P-384)

| Metric | ECDSA P-384 | ML-DSA-65 | Ratio |
|--------|-------------|-----------|-------|
| KeyGen | 0.50 ms | 0.15 ms | **3x faster** |
| Sign | 0.90 ms | 0.70 ms | **~20% faster** |
| Verify | 0.30 ms | 0.15 ms | **2x faster** |
| Public Key | 97 B | 1,952 B | **20x larger** |
| Signature | 96 B | 3,309 B | **34x larger** |

> Ratios remain valid across different machines.
> Absolute values are indicative (CPU @ 3.3 GHz).

### RSA vs ML-DSA (Signatures)

*Sources: [OpenSSL Cookbook](https://www.feistyduck.com/library/openssl-cookbook/online/openssl-command-line/performance.html), [arXiv:2503.12952](https://arxiv.org/abs/2503.12952)*

| Algorithm | Sign | Verify | Ratio vs ML-DSA-65 |
|-----------|------|--------|-------------------|
| RSA-2048 | ~1 ms | 0.045 ms | Sign: **7x slower** |
| RSA-3072 | ~4.8 ms | 0.096 ms | Sign: **7x slower** |
| ML-DSA-65 | 0.70 ms | 0.15 ms | — |

> RSA verification is faster, but signing is significantly slower than ML-DSA.
> For servers that sign frequently, ML-DSA provides better throughput.

### ML-KEM vs X25519 vs RSA (Key Exchange)

*Sources: [arXiv:2508.01694](https://arxiv.org/html/2508.01694v3), [filippo.io](https://words.filippo.io/dispatches/mlkem768/)*

| Algorithm | Operation | Time | Ratio |
|-----------|-----------|------|-------|
| ML-KEM-768 | Encaps + Decaps | ~0.2 ms | **Baseline** |
| X25519 | ECDHE | ~0.65 ms | ~3x slower |
| RSA-3072 | Key transport | >200 ms | ~1000x slower |

> ML-KEM is faster than X25519 for key exchange, despite larger key sizes.
> RSA key transport is orders of magnitude slower and rarely used in modern TLS.
>
> *X25519 = ECDH (Elliptic Curve Diffie-Hellman) on Curve25519.*

## References

- [FIPS 203: ML-KEM Standard](https://csrc.nist.gov/pubs/fips/203/final)
- [FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)
- [FIPS 205: SLH-DSA Standard](https://csrc.nist.gov/pubs/fips/205/final)
- [arXiv:2503.12952 - PQC Performance Analysis](https://arxiv.org/abs/2503.12952)
- [arXiv:2508.01694 - ML-KEM vs RSA/ECC](https://arxiv.org/html/2508.01694v3)
- [OpenSSL Cookbook - Performance](https://www.feistyduck.com/library/openssl-cookbook/online/openssl-command-line/performance.html)
