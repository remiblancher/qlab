# UC-04: "PKI operations don't change"

## Revocation & Incident Response

> **Key Message:** Revoking a PQC certificate works exactly like revoking a classical one.

> **Visual diagrams:** See [`diagram.txt`](diagram.txt) for ASCII diagrams of the revocation workflow.

## The Scenario

*"We had a security incident. A private key was compromised. How do we revoke a post-quantum certificate?"*

The same way you revoke any certificate. PKI operations are algorithm-agnostic.

## What This Demo Shows

| Operation | Classical | Post-Quantum |
|-----------|-----------|--------------|
| Issue certificate | Same workflow | Same workflow |
| Revoke certificate | Same workflow | Same workflow |
| Generate CRL | Same workflow | Same workflow |
| Verify revocation | Same workflow | Same workflow |

## Run the Demo

```bash
./demo.sh
```

The demo will:
1. Create a PQC CA (ML-DSA-65)
2. Issue a TLS certificate
3. Simulate a key compromise incident
4. Revoke the certificate
5. Compare CRL sizes (Classical vs PQC)
6. Compare OCSP response sizes (Classical vs PQC)

## The Commands

### Step 1: Create PQC CA and Issue Certificate

```bash
# Create PQC CA
pki ca init --name "PQC Root CA" --algorithm ml-dsa-65 --dir ./pqc-ca

# Issue TLS certificate
pki cert issue --ca-dir ./pqc-ca \
    --profile ml-dsa-kem/tls-server \
    --cn server.example.com \
    --out server.crt \
    --key-out server.key

# Inspect certificate
pki inspect server.crt
```

### Step 2: Revoke Certificate

```bash
# Revoke certificate (serial from certificate)
pki cert revoke <serial> --ca-dir ./pqc-ca --reason keyCompromise --gen-crl

# Inspect CRL
pki inspect ./pqc-ca/ca.crl
```

### Step 3: Generate CRL (optional)

```bash
# Generate CRL separately
pki ca crl gen --ca-dir ./pqc-ca --days 7
```

**Notice anything?** The revocation workflow is identical to classical PKI.

## Revocation Concepts

### Why Revocation Matters

Certificates have expiration dates, but sometimes you need to invalidate them **before** they expire:
- Private key compromise
- Employee termination
- Certificate misuse
- CA compromise

### Revocation Methods

| Method | Description | PQC Impact |
|--------|-------------|------------|
| **CRL** | Certificate Revocation List (batch) | Larger (PQC signatures) |
| **OCSP** | Online Certificate Status Protocol (real-time) | Larger responses (PQC signatures) |
| **CRL Distribution Points** | URLs in certificate | No change |

## Size Comparison

### CRL Sizes

| Component | Classical (ECDSA) | Post-Quantum (ML-DSA) | Notes |
|-----------|-------------------|----------------------|-------|
| CRL signature | ~96 bytes | ~3,293 bytes | ~34x larger |
| CRL total size | ~500 bytes | ~3,800 bytes | Depends on revoked count |

### OCSP Response Sizes

| Component | Classical (ECDSA) | Post-Quantum (ML-DSA) | Notes |
|-----------|-------------------|----------------------|-------|
| OCSP response | ~300 bytes | ~3,500 bytes | Per certificate query |

*Both CRL and OCSP responses are larger due to PQC signatures, but the protocols are unchanged.*

### CRL vs OCSP

| Method | Description | Use Case |
|--------|-------------|----------|
| **CRL** | Download entire list | Offline verification, batch processing |
| **OCSP** | Query per certificate | Real-time verification, online systems |

## Incident Response Workflow

```
1. DETECT
   └─► Key compromise discovered

2. ASSESS
   └─► Identify affected certificates

3. REVOKE
   └─► pki cert revoke --ca-dir <ca> --cert <cert> --reason keyCompromise

4. PUBLISH
   └─► pki ca crl gen --ca-dir <ca>  (generates updated CRL)

5. NOTIFY
   └─► Inform relying parties

6. REMEDIATE
   └─► Issue new certificates
```

## Revocation Reasons (RFC 5280)

| Code | Reason | When to Use |
|------|--------|-------------|
| 0 | unspecified | Default, no specific reason |
| 1 | keyCompromise | Private key exposed |
| 2 | cACompromise | CA's key was compromised |
| 3 | affiliationChanged | Subject's org changed |
| 4 | superseded | Replaced by new cert |
| 5 | cessationOfOperation | No longer needed |

## OCSP Commands

```bash
# Generate OCSP response (CA-signed mode)
pki ocsp sign --serial <serial> --status revoked \
    --revocation-reason keyCompromise \
    --ca ca.crt --key ca.key -o response.ocsp

# Generate OCSP response (delegated responder mode)
pki ocsp sign --serial <serial> --status good \
    --ca ca.crt --cert ocsp-responder.crt --key ocsp-responder.key -o response.ocsp

# Inspect OCSP response
pki ocsp info response.ocsp

# Verify OCSP response
pki ocsp verify --response response.ocsp --ca ca.crt

# Start OCSP responder (optional, for HTTP service)
pki ocsp serve --ca-dir ./pqc-ca --addr :8080
```

## What You Learned

1. **Revocation is algorithm-agnostic:** Same commands, same workflow
2. **CRLs are signed:** PQC CRLs have larger signatures (~7.6x)
3. **OCSP responses are signed:** PQC OCSP responses are larger (~12x)
4. **Incident response unchanged:** Your runbooks still apply
5. **Operations teams:** No retraining needed for basic PKI ops

## Related Use Cases

- **Certificate issuance:** [UC-01: Classical vs PQC](../01-classic-vs-pqc-tls/)
- **Hybrid approach:** [UC-02: Hybrid Certificates](../02-hybrid-cert/)

## References

- [RFC 5280: X.509 PKI Certificate and CRL Profile](https://datatracker.ietf.org/doc/html/rfc5280)
- [RFC 6960: Online Certificate Status Protocol (OCSP)](https://datatracker.ietf.org/doc/html/rfc6960)
- [NIST SP 800-57: Key Management Guidelines](https://csrc.nist.gov/publications/detail/sp/800-57-part-1/rev-5/final)

---

**Need help with PQC incident response planning?** Contact [QentriQ](https://qentriq.com)
