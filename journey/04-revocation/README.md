# Oops, We Need to Revoke!

## Incident Response: When Keys Are Compromised

> **Key Message:** Revoking a PQC certificate works exactly like revoking a classical one. Same workflow, same commands.

---

## The Scenario

It's 3 AM. You receive an alert:

```
🚨 SECURITY ALERT
   The private key for server.example.com
   was detected on GitHub.
```

What do you do?

*"We had a security incident. A private key was compromised. How do we revoke a post-quantum certificate?"*

The same way you revoke any certificate. PKI operations are algorithm-agnostic.

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  COMPROMISED KEY: The attacker can impersonate your server      │
│                                                                  │
│    Attacker                                                      │
│        │                                                         │
│        │  server.key (stolen)                                    │
│        ▼                                                         │
│    ┌──────────┐                                                  │
│    │ Fake     │  The attacker can now:                          │
│    │ Server   │  - Impersonate server.example.com               │
│    │          │  - Intercept client traffic                     │
│    │          │  - Sign malicious content                       │
│    └──────────┘                                                  │
│                                                                  │
│    The certificate is still technically "valid".                │
│    Solution: REVOKE IT IMMEDIATELY                              │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## What This Demo Shows

| Operation | Classical | Post-Quantum |
|-----------|-----------|--------------|
| Issue certificate | Same workflow | Same workflow |
| Revoke certificate | Same workflow | Same workflow |
| Generate CRL | Same workflow | Same workflow |
| Verify revocation | Same workflow | Same workflow |

---

## Run the Demo

```bash
./demo.sh
```

---

## The Commands

### Step 1: Create CA and Issue Certificate

```bash
# Create PQC CA
pki ca init --profile profiles/pqc-ca.yaml \
    --name "PQC CA" \
    --dir output/pqc-ca

# Issue TLS certificate
pki cert issue --ca-dir output/pqc-ca \
    --profile profiles/pqc-tls-server.yaml \
    --var cn=server.example.com \
    --out output/server.crt \
    --keyout output/server.key

# Get the serial number
openssl x509 -in output/server.crt -noout -serial
```

### Step 2: Revoke Certificate

```bash
# Revoke certificate with reason
pki cert revoke <serial> --ca-dir output/pqc-ca --reason keyCompromise

# Generate updated CRL
pki ca crl gen --ca-dir output/pqc-ca
```

### Step 3: Verify Revocation

```bash
# Verify certificate against CRL (should fail)
pki verify --cert output/server.crt \
    --ca output/pqc-ca/ca.crt \
    --crl output/pqc-ca/crl/ca.crl
```

---

## Revocation Reasons (RFC 5280)

| Code | Reason | When to Use |
|------|--------|-------------|
| 0 | unspecified | Default, no specific reason |
| 1 | keyCompromise | Private key exposed |
| 2 | cACompromise | CA's key was compromised |
| 3 | affiliationChanged | Subject's organization changed |
| 4 | superseded | Replaced by new certificate |
| 5 | cessationOfOperation | Service no longer needed |

---

## Incident Response Workflow

```
1. DETECT
   └─► Key compromise discovered (leak, breach, etc.)

2. ASSESS
   └─► Identify affected certificates (serial numbers)

3. REVOKE
   └─► pki cert revoke <serial> --ca-dir <ca> --reason keyCompromise

4. PUBLISH
   └─► pki ca crl gen --ca-dir <ca>

5. NOTIFY
   └─► Inform relying parties, update distribution points

6. REMEDIATE
   └─► Issue replacement certificates with new keys
```

**Note:** Revocation prevents future trust. It does not remove already-installed malware or undo past compromise.

---

## Size Comparison

| Component | Classical (ECDSA) | Post-Quantum (ML-DSA) | Ratio |
|-----------|-------------------|----------------------|-------|
| CRL signature | ~96 bytes | ~3,293 bytes | ~34x |
| CRL total size | ~500 bytes | ~3,800 bytes | ~7.6x |

*CRLs are larger due to PQC signatures, but the protocol is unchanged.*

*CRL size usually remains negligible compared to network traffic.*

---

## What You Learned

1. **Algorithm-agnostic:** Revocation workflow is identical for classical and PQC
2. **CRLs are signed:** PQC CRLs have larger signatures
3. **Same commands:** No new tools or procedures needed
4. **Ops teams:** No retraining required for basic PKI operations
5. **Next step:** CRLs work, but what if you need real-time revocation? See [OCSP](../05-ocsp/)

---

## References

- [RFC 5280: X.509 PKI Certificate and CRL Profile](https://datatracker.ietf.org/doc/html/rfc5280)
- [NIST SP 800-57: Key Management Guidelines](https://csrc.nist.gov/publications/detail/sp/800-57-part-1/rev-5/final)

---

← [Hybrid](../03-hybrid/) | [Next: OCSP →](../05-ocsp/)
