# Quick Start: Classical vs Post-Quantum

**Duration: 10 minutes**

## Objective

Compare classical (ECDSA) and post-quantum (ML-DSA) PKI side by side.

At the end, you will have:
- A classical CA (ECDSA P-384)
- A post-quantum CA (ML-DSA-65)
- TLS certificates from both
- Understood: same workflow, different sizes

## Prerequisites

1. Install the `pki` tool:
   ```bash
   ./tooling/install.sh
   ```

2. A bash terminal

## Run the Demo

```bash
./quickstart/demo.sh
```

## What You'll See

### Step 1-2: Classical PKI
```bash
# Create ECDSA CA
pki init-ca --profile ec/root-ca --name "Classic Root CA" --dir ./classic-ca

# Issue TLS certificate
pki issue --ca-dir ./classic-ca --profile ec/tls-server \
    --cn classic.example.com --dns classic.example.com \
    --out classic-server.crt --key-out classic-server.key
```

### Step 3-4: Post-Quantum PKI
```bash
# Create ML-DSA CA
pki init-ca --profile ml-dsa/root-ca --name "PQ Root CA" --dir ./pqc-ca

# Issue TLS certificate
pki issue --ca-dir ./pqc-ca --profile ml-dsa/tls-server \
    --cn pq.example.com --dns pq.example.com \
    --out pq-server.crt --key-out pq-server.key
```

### Step 5: Size Comparison

| File | ECDSA | ML-DSA | Ratio |
|------|-------|--------|-------|
| CA Certificate | ~800 B | ~3 KB | ~4x |
| Server Certificate | ~1 KB | ~5 KB | ~5x |
| Private Key | ~300 B | ~4 KB | ~13x |

*Actual sizes vary by certificate extensions.*

## Generated Files

```
workspace/quickstart/
├── classic-ca/           # ECDSA P-384 CA
│   ├── ca.crt
│   └── private/ca.key
├── classic-server.crt
├── classic-server.key
├── pqc-ca/               # ML-DSA-65 CA
│   ├── ca.crt
│   └── private/ca.key
├── pq-server.crt
└── pq-server.key
```

## What's Next?

Your classical CA works today. But for how long?

```bash
./journey/00-revelation/demo.sh
```

Discover the "Store Now, Decrypt Later" threat.

## Reset

```bash
./reset.sh quickstart
```
