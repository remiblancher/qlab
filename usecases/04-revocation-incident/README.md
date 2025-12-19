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
5. Generate and examine the CRL

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
| **CRL** | Certificate Revocation List | Larger (PQC signatures) |
| **OCSP** | Online Certificate Status Protocol | Same workflow |
| **CRL Distribution Points** | URLs in certificate | No change |

## Size Comparison

| Component | Classical (ECDSA) | Post-Quantum (ML-DSA) | Notes |
|-----------|-------------------|----------------------|-------|
| CRL signature | ~96 bytes | ~3,293 bytes | ~34x larger |
| CRL total size | Small | Slightly larger | Depends on revoked count |

*The CRL is larger due to the PQC signature, but the workflow is identical.*

## Incident Response Workflow

```
1. DETECT
   └─► Key compromise discovered

2. ASSESS
   └─► Identify affected certificates

3. REVOKE
   └─► pki revoke --ca-dir <ca> --cert <cert> --reason keyCompromise

4. PUBLISH
   └─► pki crl --ca-dir <ca>  (generates updated CRL)

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

## What You Learned

1. **Revocation is algorithm-agnostic:** Same commands, same workflow
2. **CRLs are signed:** PQC CRLs have larger signatures
3. **Incident response unchanged:** Your runbooks still apply
4. **Operations teams:** No retraining needed for basic PKI ops

## Related Use Cases

- **Certificate issuance:** [UC-01: Classical vs PQC](../01-classic-vs-pqc-tls/)
- **Hybrid approach:** [UC-02: Hybrid Certificates](../02-hybrid-cert/)

## References

- [RFC 5280: X.509 PKI Certificate and CRL Profile](https://datatracker.ietf.org/doc/html/rfc5280)
- [NIST SP 800-57: Key Management Guidelines](https://csrc.nist.gov/publications/detail/sp/800-57-part-1/rev-5/final)

---

**Need help with PQC incident response planning?** Contact [QentriQ](https://qentriq.com)
