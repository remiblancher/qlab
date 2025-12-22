# Mission 2: "Best of Both Worlds"

## Hybrid Catalyst with ECDSA + ML-DSA

### The Problem

You have a PQC PKI. But some of your clients don't support ML-DSA yet.

```
┌──────────────────┐                    ┌──────────────────┐
│  LEGACY Client   │                    │  MODERN Client   │
│  ──────────────  │                    │  ─────────────   │
│  OpenSSL 1.x     │                    │  OpenSSL 3.x     │
│  Java 8          │                    │  Go 1.23+        │
│  Old browser     │                    │  Chrome 2024+    │
│                  │                    │                  │
│  Understands:    │                    │  Understands:    │
│  ✓ RSA           │                    │  ✓ RSA           │
│  ✓ ECDSA         │                    │  ✓ ECDSA         │
│  ✗ ML-DSA        │                    │  ✓ ML-DSA        │
└──────────────────┘                    └──────────────────┘
         │                                       │
         │                                       │
         └───────────────┬───────────────────────┘
                         │
                         ▼
              How to serve both?
```

### The Solution: Hybrid Certificate

A hybrid certificate contains **two keys**:

```
┌─────────────────────────────────────────────────────────────────┐
│  HYBRID CERTIFICATE (Catalyst)                                  │
│  ════════════════════════════                                   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  PRIMARY KEY: ECDSA P-384                               │   │
│  │  ────────────────────────                               │   │
│  │  - Compatible with ALL clients                          │   │
│  │  - Used by legacy clients                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  PQC EXTENSION: ML-DSA-65                               │   │
│  │  ─────────────────────────                              │   │
│  │  - In an X.509 extension                                │   │
│  │  - Used by modern clients                               │   │
│  │  - Invisible to legacy clients                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Standard**: ITU-T X.509 Section 9.8 (Catalyst)

---

## How Does It Work?

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  LEGACY Client   │     │  HYBRID          │     │  MODERN Client   │
│                  │     │  CERTIFICATE     │     │                  │
│  Verifies with   │────►│                  │◄────│  Verifies with   │
│  ECDSA           │     │  ECDSA + ML-DSA  │     │  ML-DSA          │
│                  │     │                  │     │                  │
│  ✓ Works         │     │                  │     │  ✓ Works         │
└──────────────────┘     └──────────────────┘     └──────────────────┘
```

**Advantages**:
- Backward compatibility
- Post-quantum protection for modern clients
- Progressive migration
- If one algo is compromised, the other protects

---

## What You'll Do

1. **Create a hybrid CA** (ECDSA P-384 + ML-DSA-65)
2. **Issue a hybrid certificate** for a server
3. **Test with OpenSSL** (sees ECDSA)
4. **Test with pki** (verifies BOTH ECDSA AND ML-DSA)

---

## What You'll Have at the End

- Hybrid CA (dual signature)
- Hybrid server certificate
- Proof of legacy compatibility
- Proof of PQC verification

---

## Run the Mission

```bash
./demo.sh
```

---

← [Full Chain](../02-full-chain/) | [Next: mTLS →](../04-mtls/)
