# UC-07: "Smooth rotation with bundles"

## Certificate Bundles for Coupled Lifecycle

> **Key Message:** Bundles group related certificates for synchronized renewal and revocation.

> **Visual diagrams:** See [`diagram.txt`](diagram.txt) for ASCII diagrams of bundle lifecycle management.

## The Scenario

*"We have hybrid certificates with both classical and PQC keys. How do we manage their lifecycle together?"*

Certificate bundles solve this by grouping related certificates with a coupled lifecycle:
- All certificates in a bundle share the same validity period
- All certificates are renewed together
- All certificates are revoked together

## What This Demo Shows

| Operation | Without Bundles | With Bundles |
|-----------|----------------|--------------|
| Issue multiple certs | Manual, separate | Single command |
| Renewal | Each cert separately | All at once |
| Revocation | Risk of missing one | Atomic operation |
| Audit trail | Fragmented | Unified |

## Run the Demo

```bash
./demo.sh
```

**Prerequisites:**
- PKI tool installed (`../../tooling/install.sh`)
- ~5 minutes of your time

## The Commands

### Step 1: Create Hybrid CA

```bash
# Create a hybrid CA for bundle enrollment
pki ca init --name "Hybrid CA" \
    --algorithm ecdsa-p384 \
    --dir ./hybrid-ca

# Inspect
pki inspect ./hybrid-ca/ca.crt
```

### Step 2: Enroll a Certificate Bundle

```bash
# Enroll creates a complete bundle with all certificates
pki enroll --ca-dir ./hybrid-ca \
    --profile hybrid/catalyst/tls-client \
    --subject "CN=Alice,O=Demo Organization" \
    --out ./alice-bundle

# List bundle contents
ls -la ./alice-bundle/
```

### Step 3: Manage Bundle Lifecycle

```bash
# List all bundles
pki bundle list --ca-dir ./hybrid-ca

# Show bundle details
pki bundle info <bundle-id> --ca-dir ./hybrid-ca

# Renew bundle (all certs together)
pki bundle renew <bundle-id> --ca-dir ./hybrid-ca

# Revoke bundle (atomic operation)
pki bundle revoke <bundle-id> --ca-dir ./hybrid-ca --reason keyCompromise
```

> **Tip:** Bundle IDs follow the pattern `subject-date-hash` (e.g., `alice-20250119-abcd1234`)

## Why Bundles Matter

### Problem: Certificate Sprawl

Without bundles, hybrid certificates create management complexity:

```
Hybrid Identity "Alice"
├── Classical certificate (ECDSA)     → Expires 2026-01-15
├── PQC certificate (ML-DSA)          → Expires 2026-01-15 (maybe?)
└── KEM certificate (ML-KEM)          → Expires 2026-01-16 (oops!)

What happens when:
- One cert expires before others?
- One cert is revoked but others aren't?
- Keys need rotation but only some are updated?
```

### Solution: Coupled Lifecycle

```
Bundle "alice-20250115-abcd1234"
├── Classical certificate (ECDSA)     ─┐
├── PQC certificate (ML-DSA)          ─┼─► Same validity
└── KEM certificate (ML-KEM)          ─┘   Same renewal
                                           Same revocation
```

## Bundle Operations

| Operation | Command | Effect |
|-----------|---------|--------|
| **Create** | `pki enroll --profile ...` | Issues all certs, creates bundle |
| **List** | `pki bundle list` | Shows all bundles |
| **Info** | `pki bundle info <id>` | Bundle details |
| **Renew** | `pki bundle renew <id>` | New certs, same subject |
| **Revoke** | `pki bundle revoke <id>` | All certs revoked atomically |
| **Export** | `pki bundle export <id>` | Combined PEM output |

## Use Cases for Bundles

| Scenario | Why Bundles Help |
|----------|------------------|
| Hybrid migration | Classical + PQC certs stay synchronized |
| TLS with KEM | Signature + encryption certs coupled |
| User identities | All user certs managed as unit |
| Service accounts | Easy rotation across all certs |

## What You Learned

1. **Coupled lifecycle**: All bundle certs share validity and operations
2. **Atomic operations**: Renewal and revocation affect all certs
3. **Simplified management**: One command instead of many
4. **Audit clarity**: Single bundle ID for tracking

## Bundle Best Practices

| Practice | Reason |
|----------|--------|
| Use bundles for hybrid certs | Prevents desynchronization |
| Include bundle ID in logs | Traceability |
| Automate bundle renewal | Consistent rotation |
| Test revocation procedures | Ensure atomicity works |

## Related Use Cases

- **Hybrid certificates**: [UC-02: Hybrid Certificates](../02-hybrid-cert/)
- **Full PQC hierarchy**: [UC-05: Full PQC PKI](../05-full-pqc-pki/)
- **Revocation**: [UC-04: Revocation & Incident](../04-revocation-incident/)

## References

- [RFC 5280: X.509 PKI Certificate Profile](https://datatracker.ietf.org/doc/html/rfc5280)
- [ITU-T X.509: Catalyst Certificates](https://www.itu.int/rec/T-REC-X.509)

---

**Need help with certificate lifecycle management?** Contact [QentriQ](https://qentriq.com)
