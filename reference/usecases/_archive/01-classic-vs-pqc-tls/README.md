# UC-01: "Nothing changes... except the algorithm"

## TLS Server Certificate: Classical vs Post-Quantum

> **Key Message:** The PKI doesn't change. Only the algorithm changes.

> **Visual diagrams:** See [`diagram.txt`](diagram.txt) for ASCII diagrams comparing classical and PQC certificate workflows.

## The Scenario

*"I want to issue post-quantum certificates. Does it change my PKI workflow?"*

Short answer: **No.** The PKI workflow is identical. Only the algorithm name changes. This demo proves it.

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

### Step 1: Classical (ECDSA P-384)

```bash
# Create CA
pki ca init --name "Classic Root CA" --profile ec/root-ca --dir ./classic-ca

# Issue TLS certificate
pki cert issue --ca-dir ./classic-ca \
    --profile ec/tls-server \
    --cn classic.example.com \
    --dns classic.example.com \
    --out classic-server.crt \
    --key-out classic-server.key

# Inspect
pki inspect classic-server.crt
```

### Step 2: Post-Quantum (ML-DSA-65)

```bash
# Create CA
pki ca init --name "PQ Root CA" --profile ml-dsa/root-ca --dir ./pqc-ca

# Issue TLS certificate
pki cert issue --ca-dir ./pqc-ca \
    --profile ml-dsa-kem/tls-server \
    --cn pq.example.com \
    --dns pq.example.com \
    --out pq-server.crt \
    --key-out pq-server.key

# Inspect
pki inspect pq-server.crt
```

**Notice anything?** The workflow is identical. Only the algorithm name changes.

> **Tip:** For detailed ASN.1 output, use `openssl x509 -in <cert> -text -noout`

## Expected Results

### Size Comparison

| Metric | Classical (ECDSA P-384) | Post-Quantum (ML-DSA-65) | Ratio |
|--------|-------------------------|--------------------------|-------|
| Public key | ~97 bytes | ~1,952 bytes | ~20x |
| Signature | ~96 bytes | ~3,293 bytes | ~34x |
| Certificate | ~1 KB | ~6 KB | ~6x |

*Approximate ratios. Actual sizes depend on certificate extensions and metadata.*

### Performance Comparison

| Operation | Classical | Post-Quantum | Notes |
|-----------|-----------|--------------|-------|
| Key generation | fast | fast | Similar order of magnitude |
| Sign | fast | fast | ML-DSA slightly slower |
| Verify | fast | fast | ML-DSA faster than ECDSA |

*Performance varies by hardware. Run `demo.sh` for real measurements on your machine.*

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

Post-quantum cryptography prepares your infrastructure for the future. The key insight from this demo:

**Your PKI skills transfer 100%.** Learning PQC doesn't mean relearning PKI.

### Want to go deeper?

- **Why PQC for encryption?** → [UC-03: Store Now, Decrypt Later](../03-store-now-decrypt-later/)
- **Why PQC for long-lived signatures?** → [UC-06: Code Signing](../06-code-signing/)
- **How to migrate safely?** → [UC-02: Hybrid Certificates](../02-hybrid-cert/)

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
