# UC-01: "Nothing changes... except the algorithm"

## TLS Server Certificate: Classical vs Post-Quantum

> **Key Message:** The PKI doesn't change. Only the algorithm changes.

## The Scenario

*"I'm deploying an HTTPS server today, but I want it to remain secure for the next 20 years."*

This is a valid concern. A certificate issued today with ECDSA or RSA might be vulnerable to quantum attacks within its lifetime. The solution? Issue a post-quantum certificate instead — using the exact same PKI workflow.

## What This Demo Shows

| Step | Classical | Post-Quantum |
|------|-----------|--------------|
| Create CA | ECDSA P-384 | ML-DSA-65 |
| Issue cert | Same workflow | Same workflow |
| Result | Vulnerable to quantum | Quantum-resistant |

## Run the Demo

```bash
./demo.sh
```

**Prerequisites:**
- PKI tool installed (`../tooling/install.sh`)
- ~2 minutes of your time

## The Commands

### Classical (ECDSA P-384)

```bash
# Create CA
pki init-ca --name "Classic Root CA" --algorithm ecdsa-p384 --dir ./classic-ca

# Issue TLS certificate
pki issue --ca-dir ./classic-ca \
    --profile ec/tls-server \
    --cn classic.example.com \
    --dns classic.example.com \
    --out classic-server.crt \
    --key-out classic-server.key
```

### Post-Quantum (ML-DSA-65)

```bash
# Create CA
pki init-ca --name "PQ Root CA" --algorithm ml-dsa-65 --dir ./pqc-ca

# Issue TLS certificate
pki issue --ca-dir ./pqc-ca \
    --profile ml-dsa-kem/tls-server \
    --cn pq.example.com \
    --dns pq.example.com \
    --out pq-server.crt \
    --key-out pq-server.key
```

**Notice anything?** The workflow is identical. Only the algorithm name changes.

## Expected Results

### Size Comparison

| Metric | Classical (ECDSA P-384) | Post-Quantum (ML-DSA-65) | Ratio |
|--------|-------------------------|--------------------------|-------|
| Public key | ~97 bytes | ~1,952 bytes | ~20x |
| Signature | ~96 bytes | ~3,293 bytes | ~34x |
| Certificate | ~1 KB | ~6 KB | ~6x |

### Performance Comparison

| Operation | Classical | Post-Quantum | Notes |
|-----------|-----------|--------------|-------|
| Key generation | ~1 ms | ~5 ms | Still fast |
| Sign | ~1 ms | ~10 ms | Still fast |
| Verify | ~1 ms | ~3 ms | Still fast |

**The trade-off is clear:** Larger sizes in exchange for quantum resistance.

## What You Learned

### What stayed the same:
- Certificate structure (X.509)
- CA hierarchy concept
- Issuance workflow
- Revocation mechanism
- Trust model
- Your PKI knowledge

### What changed:
- Signature algorithm identifier
- Key and signature sizes
- OIDs (Object Identifiers)

## Why This Matters

### The Quantum Threat Timeline

```
Today                     2030                      2040
  |                         |                         |
  v                         v                         v
[Issue cert]          [Quantum computers]       [Cert expires]
     \                      |                      /
      \                     |                     /
       +-------- Cert lifetime (10-20 years) ---+
                            |
                    [VULNERABLE PERIOD]
```

If you issue a 10-year certificate with ECDSA today, it might be broken before it expires.

### The Solution: Start Now

1. **Evaluate** your certificate lifetimes
2. **Test** post-quantum algorithms in lab environments
3. **Plan** your migration timeline
4. **Deploy** hybrid certificates for compatibility

## Next Steps

- [UC-02: Hybrid Certificates](../02-hybrid-cert/) — Best of both worlds
- [UC-03: Store Now, Decrypt Later](../03-store-now-decrypt-later/) — The real threat

## Algorithms Used

### ECDSA P-384 (Classical)
- Elliptic Curve Digital Signature Algorithm
- NIST P-384 curve
- ~192-bit security level
- Vulnerable to Shor's algorithm on quantum computers

### ML-DSA-65 (Post-Quantum)
- Module-Lattice Digital Signature Algorithm
- NIST FIPS 204 standard (2024)
- Security Level 3 (~192-bit equivalent)
- Resistant to known quantum attacks
- Based on the hardness of Module-LWE problem

## References

- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)
- [Cloudflare CIRCL Library](https://github.com/cloudflare/circl)

---

**Need help with your PQC transition?** Contact [QentriQ](https://qentriq.com)
