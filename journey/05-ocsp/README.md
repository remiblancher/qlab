# PQC OCSP: Is This Cert Still Good?

## Real-Time Certificate Verification with OCSP

> **Key Message:** Real-time certificate verification with OCSP works exactly the same with PQC. Same HTTP protocol, same tools.

---

## The Scenario

You have a CRL. But it's updated every hour. A certificate was revoked 30 seconds ago. Clients don't know yet.

```
TIMELINE: The CRL Staleness Problem
───────────────────────────────────

  03:00    03:30    04:00    04:30    05:00
    │        │        │        │        │
    ▼        ▼        ▼        ▼        ▼
  CRL      Cert     CRL      CRL      CRL
  published REVOKED published published published

              ↑
              │
              For 30 min, clients
              still trust the
              revoked certificate!
```

*"I need real-time certificate status. CRLs are too slow. Does OCSP work with PQC?"*

Yes. Same HTTP protocol, same request/response format. Only signature sizes change.

---

## What This Demo Shows

| Step | What Happens | Expected Result |
|------|--------------|-----------------|
| 1 | Start OCSP responder | HTTP service on port 8888 |
| 2 | Query valid certificate | Status: GOOD |
| 3 | Revoke certificate | Certificate marked revoked |
| 4 | Query again | Status: REVOKED (immediate!) |

---

## Run the Demo

```bash
./demo.sh
```

---

## The Commands

### Step 1: Create CA and OCSP Responder Certificate

```bash
# Create PQC CA with ML-DSA-65
pki ca init --name "PQC CA" \
    --profile profiles/pqc-ca.yaml \
    --dir output/pqc-ca

# Issue delegated OCSP responder certificate
# Best practice: CA key stays offline
pki cert issue --ca-dir output/pqc-ca \
    --profile profiles/ocsp-responder.yaml \
    --cn "OCSP Responder" \
    --out output/ocsp-responder.crt \
    --key-out output/ocsp-responder.key

# Issue TLS certificate to verify
pki cert issue --ca-dir output/pqc-ca \
    --profile profiles/pqc-tls-server.yaml \
    --cn server.example.com \
    --dns server.example.com \
    --out output/server.crt \
    --key-out output/server.key
```

### Step 2: Start OCSP Responder

```bash
# Start with delegated certificate (recommended)
pki ocsp serve --port 8888 --ca-dir output/pqc-ca \
    --cert output/ocsp-responder.crt \
    --key output/ocsp-responder.key
```

### Step 3: Query Certificate Status

```bash
# Generate OCSP request
pki ocsp request --issuer output/pqc-ca/ca.crt \
    --cert output/server.crt \
    -o output/request.ocsp

# Send to responder via HTTP POST
curl -s -X POST \
    -H "Content-Type: application/ocsp-request" \
    --data-binary @output/request.ocsp \
    http://localhost:8888/ \
    -o output/response.ocsp

# Inspect response
pki ocsp info output/response.ocsp
```

### Step 4: Revoke and Re-query

```bash
# Revoke certificate
pki cert revoke <serial> --ca-dir output/pqc-ca --reason keyCompromise

# Query again - status changes immediately!
curl -s -X POST \
    -H "Content-Type: application/ocsp-request" \
    --data-binary @output/request.ocsp \
    http://localhost:8888/ \
    -o output/response2.ocsp

pki ocsp info output/response2.ocsp
# Status: revoked
# Revocation Reason: keyCompromise
```

---

## CRL vs OCSP

| Criteria | CRL | OCSP |
|----------|-----|------|
| **Update** | Periodic (hourly/daily) | Real-time |
| **Size** | Can be large (full list) | Small (one response) |
| **Availability** | Works offline | Requires network |
| **Latency** | Local read | Network request |
| **Vuln. window** | Until next CRL | Nearly zero |

**In practice**: Use BOTH
- OCSP for real-time checks
- CRL as offline fallback

---

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

The OCSP responder certificate has:
- Extended Key Usage: `id-kp-OCSPSigning` (1.3.6.1.5.5.7.3.9)
- OCSP No Check extension (prevents infinite verification loop)

---

## Size Comparison

| Component | Classical (ECDSA) | Post-Quantum (ML-DSA) | Notes |
|-----------|-------------------|----------------------|-------|
| OCSP Request | ~100 bytes | ~100 bytes | Same format |
| OCSP Response | ~300 bytes | ~3,500 bytes | PQC signature larger |

*Responses are larger due to ML-DSA signatures, but the protocol is unchanged.*

---

## Response Times

| Operation | Classical | PQC | Notes |
|-----------|-----------|-----|-------|
| Request generation | <1ms | <1ms | Same |
| Network round-trip | ~Xms | ~Xms | Same protocol |
| Signature verification | <1ms | ~2-5ms | ML-DSA slightly slower |

---

## What You Learned

1. **Same HTTP protocol:** RFC 6960 works unchanged with PQC
2. **Delegated responders:** Best practice keeps CA keys offline
3. **Real-time status:** Revocation changes are immediate
4. **Size tradeoff:** PQC responses are larger but acceptable
5. **Drop-in replacement:** Existing OCSP clients work with PQC responders

---

## References

- [RFC 6960: Online Certificate Status Protocol (OCSP)](https://datatracker.ietf.org/doc/html/rfc6960)
- [RFC 5019: Lightweight OCSP Profile](https://datatracker.ietf.org/doc/html/rfc5019)
- [RFC 6277: OCSP Algorithm Agility](https://datatracker.ietf.org/doc/html/rfc6277)

---

← [Revocation](../04-revocation/) | [Next: Code Signing →](../06-code-signing/)
