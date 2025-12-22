# Mission 4: "Secure Your Releases"

## Code Signing with ML-DSA

### The Problem

You distribute firmware to your clients. How do they know you really created it?

```
WITHOUT CODE SIGNING
────────────────────

   Developer                    Attacker                    Client
       │                              │                           │
       │  firmware.bin                │                           │
       │  ────────────────────────────┼──────────────────────────►│
       │                              │                           │
       │                              │  firmware.bin (modified)  │
       │                              │  ──────────────────────►  │
       │                              │                           │
       │                              │                           ▼
       │                              │                    ┌──────────────┐
       │                              │                    │  Which one   │
       │                              │                    │  is real?    │
       │                              │                    └──────────────┘
```

### The Threat

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  SUPPLY CHAIN ATTACK: Modify code in transit                    │
│                                                                  │
│                                                                  │
│    Developer                                                     │
│        │                                                         │
│        │  firmware.bin (original)                                │
│        ▼                                                         │
│    ┌──────────┐                                                  │
│    │  Mirror  │ ◄──── Attacker injects malware                  │
│    │  Server  │                                                  │
│    └──────────┘                                                  │
│        │                                                         │
│        │  firmware.bin (compromised)                             │
│        ▼                                                         │
│    ┌──────────┐                                                  │
│    │  Client  │  Installs the firmware                          │
│    │          │  without knowing it's                           │
│    │          │  been modified                                  │
│    └──────────┘                                                  │
│                                                                  │
│  Real-world examples:                                            │
│  - SolarWinds (2020): malware injected in an update             │
│  - CodeCov (2021): build script compromised                     │
│  - 3CX (2023): supply chain of a supply chain                   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### The Solution: Code Signing

Sign the code BEFORE distributing it:

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  WITH CODE SIGNING                                               │
│                                                                  │
│    Developer                                                     │
│        │                                                         │
│        │  1. Signs firmware.bin with ML-DSA                      │
│        ▼                                                         │
│    ┌─────────────────────────────────┐                          │
│    │  firmware.bin                   │                          │
│    │  + firmware.bin.sig (signature) │                          │
│    │  + signing.crt (certificate)    │                          │
│    └─────────────────────────────────┘                          │
│        │                                                         │
│        ▼                                                         │
│    ┌──────────┐                                                  │
│    │  Client  │  2. Verifies the signature                      │
│    │          │                                                  │
│    │          │  ✓ Hash matches                                 │
│    │          │  ✓ Signature valid                              │
│    │          │  ✓ Certificate in the chain                     │
│    │          │                                                  │
│    │          │  → Installation authorized                      │
│    └──────────┘                                                  │
│                                                                  │
│  If the firmware is modified:                                    │
│  ❌ Hash doesn't match → Signature invalid → REJECTED           │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## What a Signature Guarantees

| Property | Meaning |
|----------|---------|
| **Integrity** | The file hasn't been modified |
| **Authenticity** | It really comes from the publisher |
| **Non-repudiation** | The publisher can't deny signing it |

---

## What You'll Do

1. **Create a code-signing certificate** with ML-DSA-65
2. **Sign a "firmware"** (binary file)
3. **Verify the signature**: integrity + authenticity
4. **Modify the file** and see the verification fail

---

## Anatomy of a Signature

```
firmware.bin.sig
────────────────

┌─────────────────────────────────────────────────────────────┐
│  ML-DSA-65 Signature                                        │
│  ─────────────────────                                      │
│                                                              │
│  File hash     : SHA-512(firmware.bin)                      │
│  Signature     : ML-DSA.Sign(hash, private_key)             │
│  Size          : ~3293 bytes                                │
│                                                              │
│  Verification:                                               │
│  1. Recalculate the file hash                               │
│  2. Verify with the certificate's public key                │
│  3. Verify the certificate is in the CA chain               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## What You'll Have at the End

- ML-DSA-65 signing certificate
- firmware.bin file
- firmware.bin.sig signature
- Verification proof (valid / invalid if modified)

---

## Run the Mission

```bash
./demo.sh
```

---

← [mTLS](../04-mtls/) | [Next: Timestamping →](../06-timestamping/)
