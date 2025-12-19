# UC-09: Trust, but verify

**Key Message:** Deploying a real-time OCSP verification service works exactly the same with PQC.

## The Scenario

Your organization needs real-time certificate verification. OCSP (Online Certificate Status Protocol) provides instant certificate status checks, unlike CRLs which require periodic downloads.

**The question:** Can we deploy PQC OCSP responders using the same infrastructure?

**The answer:** Yes. Same HTTP protocol, same tools, same architecture.

## What This Demo Shows

1. **Delegated OCSP responder** - Best practice: CA key stays offline
2. **Real-time queries** - HTTP POST with binary OCSP request
3. **Status changes** - Revoke and see immediate effect
4. **Size comparison** - PQC responses are larger but protocol unchanged

## Run the Demo

```bash
./demo.sh
```

The demo will:
1. Create Classical and PQC CAs
2. Issue delegated OCSP responder certificates
3. Issue TLS server certificates
4. Start OCSP responders (HTTP services on ports 8080/8081)
5. Query certificate status in real-time
6. Revoke a certificate and verify status change
7. Compare response sizes and times

## The Commands

### Step 1: Create CA

```bash
# Classical CA
pki init-ca --name "Classic Root CA" --algorithm ecdsa-p384 --dir ./classic-ca

# PQC CA (hybrid for compatibility)
pki init-ca --name "PQC Root CA" --algorithm ecdsa-p384 \
    --hybrid-algorithm ml-dsa-65 --dir ./pqc-ca
```

### Step 2: Issue Delegated OCSP Responder Certificate

```bash
# Best practice: Use delegated responder (CA key stays offline)
pki issue --ca-dir ./pqc-ca \
    --profile hybrid/catalyst/ocsp-responder \
    --cn "PQC OCSP Responder" \
    --out ocsp-responder.crt \
    --key-out ocsp-responder.key
```

The OCSP responder certificate has:
- Extended Key Usage: `id-kp-OCSPSigning` (1.3.6.1.5.5.7.3.9)
- OCSP No Check extension (prevents infinite verification loop)

### Step 3: Start OCSP Responder

```bash
# Start with delegated certificate
pki ocsp serve --port 8080 --ca-dir ./pqc-ca \
    --cert ocsp-responder.crt \
    --key ocsp-responder.key

# Or with CA-signed responses (simpler but less secure)
pki ocsp serve --port 8080 --ca-dir ./pqc-ca
```

### Step 4: Query Certificate Status

```bash
# 1. Generate OCSP request
pki ocsp request --issuer ca.crt --cert server.crt -o request.ocsp

# 2. Send to OCSP responder via HTTP POST
curl -s -X POST \
    -H "Content-Type: application/ocsp-request" \
    --data-binary @request.ocsp \
    http://localhost:8080/ \
    -o response.ocsp

# 3. Verify the response
pki ocsp verify --response response.ocsp --ca ca.crt

# Inspect response details
pki ocsp info response.ocsp
```

### Step 5: Revoke and Re-query

```bash
# Revoke certificate
pki revoke <serial> --ca-dir ./pqc-ca --reason keyCompromise

# Query again - status changes immediately
curl -s -X POST \
    -H "Content-Type: application/ocsp-request" \
    --data-binary @request.ocsp \
    http://localhost:8080/ \
    -o response2.ocsp

pki ocsp info response2.ocsp
# Status: revoked
# Revocation Reason: keyCompromise
```

## OCSP Architecture

### CA-Signed Mode (Simple)

```
┌─────────────┐                      ┌──────────────────┐
│   Client    │ ─── OCSP Request ──► │  OCSP Responder  │
│ (curl/app)  │ ◄── OCSP Response ── │ (pki ocsp serve) │
└─────────────┘                      └────────┬─────────┘
                                              │
                                     Signs with CA key
                                     (CA key online - risk!)
```

### Delegated Responder Mode (Recommended)

```
┌─────────────┐                      ┌──────────────────┐
│   Client    │ ─── OCSP Request ──► │  OCSP Responder  │
│ (curl/app)  │ ◄── OCSP Response ── │ (pki ocsp serve) │
└─────────────┘                      └────────┬─────────┘
                                              │
                                     Signs with responder key
                                     (CA key stays offline!)
                                              │
                                     ┌────────▼─────────┐
                                     │ OCSP Responder   │
                                     │   Certificate    │
                                     │ (id-kp-OCSPSign) │
                                     └──────────────────┘
```

## Size Comparison

| Component | Classical (ECDSA) | PQC (Hybrid) | Notes |
|-----------|-------------------|--------------|-------|
| OCSP Request | ~100 bytes | ~100 bytes | Same format |
| OCSP Response | ~300 bytes | ~300 bytes | Hybrid uses ECDSA sig |
| Pure PQC Response | - | ~3,500 bytes | ML-DSA signature |

*Hybrid mode uses ECDSA signatures for OCSP responses, keeping them small while the CA certificate contains PQC keys.*

## Response Times

| Operation | Classical | PQC | Notes |
|-----------|-----------|-----|-------|
| Request generation | <1ms | <1ms | Same |
| Network round-trip | ~Xms | ~Xms | Same protocol |
| Signature verification | <1ms | ~2-5ms | ML-DSA slightly slower |

## What You Learned

1. **Same HTTP protocol:** RFC 6960 works unchanged with PQC
2. **Delegated responders:** Best practice keeps CA keys offline
3. **Real-time status:** Revocation changes are immediate
4. **Size tradeoff:** PQC responses are larger (~10x) but acceptable
5. **Drop-in replacement:** Existing OCSP clients work with PQC responders

## Difference from UC-04

| Aspect | UC-04 (Revocation) | UC-09 (OCSP Service) |
|--------|-------------------|---------------------|
| Mode | Offline file generation | Online HTTP service |
| Output | CRL/OCSP files | HTTP responses |
| Use case | Batch distribution | Real-time queries |
| Focus | Incident response | Service deployment |

## Related Use Cases

- **Certificate revocation:** [UC-04: PKI Operations](../04-revocation-incident/)
- **Certificate issuance:** [UC-01: Classical vs PQC](../01-classic-vs-pqc-tls/)

## References

- [RFC 6960: Online Certificate Status Protocol (OCSP)](https://datatracker.ietf.org/doc/html/rfc6960)
- [RFC 5019: Lightweight OCSP Profile](https://datatracker.ietf.org/doc/html/rfc5019)
- [RFC 6277: OCSP Algorithm Agility](https://datatracker.ietf.org/doc/html/rfc6277)

---

**Need help deploying PQC OCSP infrastructure?** Contact [QentriQ](https://qentriq.com)
