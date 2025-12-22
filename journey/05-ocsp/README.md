# Mission 7: "Is This Cert Still Good?"

## OCSP Responder with Hybrid

### The Problem

You have a CRL. But it's updated every hour.

A certificate was revoked 30 seconds ago.
Clients don't know yet.

```
TIMELINE
────────

  03:00    03:30    04:00    04:30    05:00
    │        │        │        │        │
    ▼        ▼        ▼        ▼        ▼
  CRL      Revoc    CRL      CRL      CRL
  published cert    published published published

                ↑
                │
                For 30 min, clients
                still trust the
                revoked certificate!
```

### The Threat

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  VULNERABILITY WINDOW: Stale CRL                                │
│                                                                  │
│                                                                  │
│    03:30  Certificate revoked (key compromised)                 │
│    03:35  Client checks the certificate                         │
│                                                                  │
│       Client                         CRL (03:00)                 │
│         │                               │                        │
│         │  "Is this cert valid?"        │                        │
│         │  ───────────────────────────► │                        │
│         │                               │                        │
│         │  ◄─────────────────────────── │                        │
│         │  "Yes, valid"                 │                        │
│         │  (stale CRL!)                 │                        │
│         ▼                                                        │
│       ✓ Connection accepted                                      │
│                                                                  │
│    The attacker can use the cert for 30 min!                    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### The Solution: OCSP (Online Certificate Status Protocol)

**Real-time** verification:

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  OCSP: Instant query                                            │
│                                                                  │
│                                                                  │
│    Client                         OCSP Responder                │
│      │                                  │                        │
│      │  "Status of cert 12345?"         │                        │
│      │  ──────────────────────────────► │                        │
│      │                                  │                        │
│      │                                  │  Checks real-time      │
│      │                                  │  database              │
│      │                                  │                        │
│      │  ◄────────────────────────────── │                        │
│      │  OCSP Response:                  │                        │
│      │  - Status: REVOKED               │                        │
│      │  - Reason: keyCompromise         │                        │
│      │  - Time: 03:30:00                │                        │
│      │  - Signature: OCSP (hybrid)      │                        │
│      │                                  │                        │
│      ▼                                                           │
│    ❌ Connection refused (real-time)                             │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
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

## What You'll Do

1. **Start an OCSP responder** for your hybrid CA
2. **Query the status** of a valid certificate
3. **Revoke the certificate** via the CA
4. **Observe the change**: status goes from "good" to "revoked"
5. **Compare**: CRL vs OCSP in real-time

---

## Anatomy of an OCSP Response

```
OCSP Response
─────────────

┌─────────────────────────────────────────────────────────────┐
│  Version: 1                                                 │
│  Responder: CN=OCSP Responder                              │
│  Produced At: 2024-12-15T03:35:00Z                         │
│                                                             │
│  Response:                                                  │
│  ──────────                                                 │
│  Serial: 12345                                              │
│  Status: revoked                                            │
│  Revocation Time: 2024-12-15T03:30:00Z                     │
│  Revocation Reason: keyCompromise                          │
│                                                             │
│  This Update: 2024-12-15T03:35:00Z                         │
│  Next Update: 2024-12-15T04:35:00Z                         │
│                                                             │
│  Signature: ECDSA P-384 + ML-DSA-65                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## What You'll Have at the End

- Working OCSP responder
- Captured responses (good / revoked)
- Proof of real-time change
- Understanding of OCSP workflow

---

## Run the Mission

```bash
./demo.sh
```

---

← [Revocation](../07-revocation/) | [Next: Crypto-Agility →](../09-crypto-agility/)
