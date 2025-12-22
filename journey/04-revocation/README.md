# Mission 6: "Oops, We Need to Revoke!"

## Revocation & CRL with Hybrid

### The Problem

It's 3 AM. You receive an alert:

```
🚨 SECURITY ALERT
   The private key for server.example.com
   was detected on GitHub.
```

What do you do?

### The Threat

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  COMPROMISED PRIVATE KEY: The attacker can do anything          │
│                                                                  │
│                                                                  │
│    Attacker                                                      │
│        │                                                         │
│        │  server.key (stolen)                                    │
│        ▼                                                         │
│    ┌──────────┐                                                  │
│    │ Fake     │  The attacker can now:                          │
│    │ Server   │                                                  │
│    │          │  1. Impersonate server.example.com              │
│    │          │  2. Intercept client traffic                    │
│    │          │  3. Sign malicious code                         │
│    │          │  4. Steal data in transit                       │
│    └──────────┘                                                  │
│                                                                  │
│    The certificate is still technically "valid".                │
│    Clients trust the attacker.                                  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**Impact**:
- Man-in-the-middle
- Credential theft
- Malware injection
- Destroyed reputation

### The Solution: Revoke Immediately

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  REVOCATION: Invalidate trust in a certificate                  │
│                                                                  │
│                                                                  │
│    1. CA adds the certificate to the CRL                        │
│                                                                  │
│       ┌─────────────────────────────────────────┐               │
│       │  CRL (Certificate Revocation List)      │               │
│       │  ─────────────────────────────────      │               │
│       │                                         │               │
│       │  Serial: 12345                          │               │
│       │  Reason: keyCompromise                  │               │
│       │  Date: 2024-12-15T03:45:00Z            │               │
│       │                                         │               │
│       │  Signature: CA (ECDSA + ML-DSA)        │               │
│       └─────────────────────────────────────────┘               │
│                                                                  │
│    2. Clients check the CRL                                     │
│                                                                  │
│       Client                         CRL                         │
│         │                             │                          │
│         │  "Is this cert valid?"      │                          │
│         │  ─────────────────────────► │                          │
│         │                             │                          │
│         │  ◄───────────────────────── │                          │
│         │  "No, revoked for           │                          │
│         │   keyCompromise"            │                          │
│         │                             │                          │
│         ▼                                                        │
│       ❌ Connection refused                                      │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Revocation Reasons

| Code | Reason | When to use |
|------|--------|-------------|
| `keyCompromise` | Key stolen | Leak on GitHub, hacking |
| `caCompromise` | CA compromised | Major incident |
| `affiliationChanged` | Affiliation changed | Employee leaves company |
| `superseded` | Superseded | New certificate issued |
| `cessationOfOperation` | Cessation of operation | Service stopped |
| `certificateHold` | Temporary suspension | Investigation in progress |

---

## What You'll Do

1. **Issue a certificate** with your hybrid CA
2. **Simulate a compromise**: the key is stolen
3. **Revoke the certificate** with reason `keyCompromise`
4. **Generate a CRL** signed hybrid
5. **Verify**: the certificate is now rejected

---

## Timeline of a Real Incident

```
03:00  Alert: key detected on GitHub
03:05  Identify the affected certificate
03:10  Revocation via CA
03:15  CRL updated and published
03:20  Clients start rejecting the cert
03:30  New certificate issued (new key)
03:35  Incident closed
```

---

## What You'll Have at the End

- Revoked certificate
- Signed CRL (ECDSA + ML-DSA)
- Verification proof: cert rejected
- Understanding of the incident workflow

---

## Run the Mission

```bash
./demo.sh
```

---

← [Timestamping](../06-timestamping/) | [Next: OCSP →](../08-ocsp/)
