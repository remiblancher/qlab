# Mission 5: "Trust Now, Verify Forever"

## Timestamping with ML-DSA

### The Problem

You sign a contract today. In 5 years, your certificate has expired.

Is the signature still valid?

```
TODAY                                IN 5 YEARS
─────                                ──────────

  Contract.pdf                       Contract.pdf
  + Signature                        + Signature
  ✓ Certificate valid                ❌ Certificate expired

  "This contract was                 "Was this contract
   signed on 12/15/2024"              really signed
                                      BEFORE expiration?"
```

### The Threat

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  PROBLEM: The signature date is not proven                      │
│                                                                  │
│                                                                  │
│    2024                              2029                        │
│      │                                 │                         │
│      │  Signature created              │  Certificate expired   │
│      │                                 │                         │
│      ▼                                 ▼                         │
│    ┌─────────┐                      ┌─────────┐                 │
│    │ Contract│                      │ Contract│                 │
│    │ signed  │                      │ signed  │                 │
│    │         │                      │         │                 │
│    │ ✓ Valid │  ────────────────►   │ ? Valid │                 │
│    └─────────┘                      └─────────┘                 │
│                                                                  │
│    Without timestamping, impossible to prove that the signature │
│    was created BEFORE the certificate expiration.               │
│                                                                  │
│    An attacker could:                                            │
│    - Backdate a signature (fraud)                               │
│    - Contest the validity of a contract                         │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### The Solution: Cryptographic Timestamping (TSA)

A trusted authority (TSA) proves when the signature was created:

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  WITH TSA TIMESTAMPING                                           │
│                                                                  │
│    1. You sign the document                                      │
│                                                                  │
│       Contract.pdf                                               │
│       + Your signature                                           │
│           │                                                      │
│           │  2. You request a timestamp                          │
│           ▼                                                      │
│       ┌───────────────────────────────────────────┐             │
│       │  TSA (Timestamp Authority)                │             │
│       │  ─────────────────────────                │             │
│       │                                           │             │
│       │  "I certify that this hash existed       │             │
│       │   on 12/15/2024 at 14:32:05 UTC"         │             │
│       │                                           │             │
│       │  + TSA Signature (ML-DSA-65)             │             │
│       │  + Certified clock                       │             │
│       └───────────────────────────────────────────┘             │
│           │                                                      │
│           ▼                                                      │
│    3. The timestamp is added to the document                    │
│                                                                  │
│       Contract.pdf                                               │
│       + Your signature                                           │
│       + TSA timestamp                                            │
│                                                                  │
│    VERIFICATION IN 2029:                                         │
│    ✓ The signature existed on 12/15/2024                        │
│    ✓ It was BEFORE the certificate expiration                   │
│    ✓ The document is still valid                                │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## How It Works Technically

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  TIMESTAMPING WORKFLOW (RFC 3161)                              │
│                                                                 │
│  1. CLIENT                                                      │
│     ────────                                                    │
│     hash = SHA-512(signature)                                   │
│     request = TimeStampReq(hash)                                │
│                                                                 │
│  2. TSA                                                         │
│     ────                                                        │
│     clock = certified_time()                                    │
│     token = {                                                   │
│       hash: received_hash,                                      │
│       time: "2024-12-15T14:32:05Z",                            │
│       tsa: "TSA Acme Corp",                                     │
│       serial: 123456                                            │
│     }                                                           │
│     signature = ML-DSA.Sign(token, tsa_key)                     │
│                                                                 │
│  3. RESULT                                                      │
│     ─────────                                                   │
│     TimeStampResp = token + signature                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Use Cases

| Domain | Need | Retention period |
|--------|------|-----------------|
| Contracts | Proof of signature | 10-30 years |
| Invoices | Tax compliance | 10 years |
| Patents | Proof of priority | 20+ years |
| Medical | Patient records | 50+ years |
| Legal | Legal evidence | Indefinite |

---

## What You'll Do

1. **Create a TSA** (Timestamp Authority) with ML-DSA-65
2. **Timestamp a document** via the RFC 3161 protocol
3. **Verify the timestamp**: clock, hash, TSA signature
4. **Simulate the future**: verify in 2055

---

## What You'll Have at the End

- TSA certificate ML-DSA-65
- Timestamped document (timestamp token)
- Verification proof
- Trust until 2055+

---

## Run the Mission

```bash
./demo.sh
```

---

← [Code Signing](../05-code-signing/) | [Next: Revocation →](../07-revocation/)
