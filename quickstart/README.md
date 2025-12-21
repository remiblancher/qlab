# Quick Start: Classical vs Post-Quantum

## Same PKI, Different Crypto

> **Key Message:** The PKI doesn't change. Only the algorithm changes.

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
./quickstart/demo.sh
```

**Duration:** 10 minutes

## The Commands

### Step 1: Classical (ECDSA P-384)

```bash
# Create CA
pki init-ca --profile ec/root-ca --name "Classic Root CA" --dir ./classic-ca

# Issue TLS certificate
pki issue --ca-dir ./classic-ca \
    --profile ec/tls-server \
    --cn classic.example.com \
    --dns classic.example.com \
    --out classic-server.crt \
    --key-out classic-server.key
```

### Step 2: Post-Quantum (ML-DSA-65)

```bash
# Create CA
pki init-ca --profile ml-dsa/root-ca --name "PQ Root CA" --dir ./pqc-ca

# Issue TLS certificate
pki issue --ca-dir ./pqc-ca \
    --profile ml-dsa/tls-server \
    --cn pq.example.com \
    --dns pq.example.com \
    --out pq-server.crt \
    --key-out pq-server.key
```

**Notice anything?** The workflow is identical. Only the profile name changes.

## Expected Results

### Size Comparison

| Metric | Classical (ECDSA) | Post-Quantum (ML-DSA) | Ratio |
|--------|-------------------|----------------------|-------|
| CA Certificate | ~800 B | ~3 KB | ~4x |
| Server Certificate | ~1 KB | ~5 KB | ~5x |
| Private Key | ~300 B | ~4 KB | ~13x |

*Actual sizes depend on certificate extensions.*

**The trade-off:** Larger sizes in exchange for quantum resistance.

## What You Learned

### What stayed the same:
- Commands: `init-ca`, `issue`
- Certificate structure (X.509)
- CA hierarchy concept
- Your PKI knowledge

### What changed:
- Profile: `ec/*` → `ml-dsa/*`
- Key and signature sizes

## What's Next?

Your classical CA works perfectly today. The question is: **for how long?**

Your ECDSA certificates are being harvested right now. When quantum computers arrive, they'll be decrypted.

```bash
./journey/00-revelation/demo.sh
```

Discover the "Store Now, Decrypt Later" threat.

## Reset

```bash
./reset.sh quickstart
```
