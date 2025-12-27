# PQC mTLS: Show Me Your Badge

## Mutual TLS Authentication with ML-DSA

> **Key Message:** mTLS = mutual authentication. No passwords. Just certificates. With PQC, it's quantum-resistant.

---

## The Problem

```
CLASSIC HTTPS = One-way verification
──────────────────────────────────────

   Client                              Server
     │                                    │
     │  ────────────────────────────────► │
     │     "Prove who you are"            │
     │                                    │
     │  ◄──────────────────────────────── │
     │     Server certificate ✓           │
     │                                    │

     The server is verified.
     But the client? Anyone can connect.
```

---

## The Threat

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│    Classic HTTPS: The client is not authenticated               │
│                                                                  │
│       Attacker                                                   │
│          │                                                       │
│          │  "I am Alice"                                         │
│          ▼                                                       │
│    ┌──────────┐         ┌──────────┐                            │
│    │  Client  │────────►│  Server  │                            │
│    │  (who?)  │         │          │                            │
│    └──────────┘         └──────────┘                            │
│                                                                  │
│    The server doesn't know if it's really Alice.                │
│    It trusts anyone.                                            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**Risks**:
- Identity theft
- Unauthorized API access
- Man-in-the-middle attack

---

## The Solution: mTLS (Mutual TLS)

With mTLS, **BOTH** parties prove their identity:

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│    mTLS: Mutual verification                                    │
│                                                                  │
│    ┌──────────┐                           ┌──────────┐          │
│    │  Alice   │◄─────────────────────────►│  Server  │          │
│    │          │                           │          │          │
│    │  Cert    │   1. Server → Client      │  Cert    │          │
│    │  ML-DSA  │      "Here's my cert"     │  ML-DSA  │          │
│    │          │                           │          │          │
│    │          │   2. Client → Server      │          │          │
│    │          │      "Here's my cert"     │          │          │
│    │          │                           │          │          │
│    │    ✓     │   3. Mutual               │    ✓     │          │
│    │  Valid   │      verification         │  Valid   │          │
│    └──────────┘                           └──────────┘          │
│                                                                  │
│    Both parties are authenticated.                              │
│    The attacker can no longer impersonate Alice.                │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**Advantages**:
- Zero-trust: never trust by default
- No passwords to manage
- Quantum-safe with ML-DSA

---

## What This Demo Shows

| Step | What Happens | Key Concept |
|------|--------------|-------------|
| 1 | Explain mTLS vs HTTPS | Client authentication |
| 2 | Create mTLS CA | Dedicated trust anchor |
| 3 | Issue server certificate | serverAuth EKU |
| 4 | Issue client certificates | clientAuth EKU |
| 5 | Simulate authentication | Alice OK, Bob OK, Mallory rejected |
| 6 | Show summary | Files created |

---

## Real-World Use Cases

| Scenario | Why mTLS? |
|----------|-----------|
| Microservices API | Each service authenticates to others |
| IoT devices | Each device proves its identity to backend |
| Zero-trust network | No implicit trust, everything is verified |
| CI/CD pipelines | Runners authenticate to registries |

---

## Run the Demo

```bash
./demo.sh
```

---

## The Commands

### Step 1: Create mTLS CA

```bash
# Create dedicated CA for mTLS
pki ca init --name "mTLS Demo CA" \
    --algorithm ml-dsa-65 \
    --dir output/mtls-ca
```

### Step 2: Issue Server Certificate

```bash
# Server certificate with serverAuth EKU
pki cert issue --ca-dir output/mtls-ca \
    --profile ml-dsa/tls-server \
    --cn "api.example.com" \
    --dns api.example.com \
    --out output/server.crt \
    --key-out output/server.key
```

### Step 3: Issue Client Certificates

```bash
# Client certificate for Alice
pki cert issue --ca-dir output/mtls-ca \
    --profile ml-dsa/tls-client \
    --cn "Alice" \
    --out output/alice.crt \
    --key-out output/alice.key

# Client certificate for Bob
pki cert issue --ca-dir output/mtls-ca \
    --profile ml-dsa/tls-client \
    --cn "Bob" \
    --out output/bob.crt \
    --key-out output/bob.key
```

### Step 4: Verify Client Certificates

```bash
# Verify Alice's certificate
pki verify --ca output/mtls-ca/ca.crt --cert output/alice.crt

# Verify Bob's certificate
pki verify --ca output/mtls-ca/ca.crt --cert output/bob.crt
```

---

## Certificate Profiles

| Profile | EKU | Purpose |
|---------|-----|---------|
| `ml-dsa/tls-server` | serverAuth | Server proves identity to client |
| `ml-dsa/tls-client` | clientAuth | Client proves identity to server |

---

## What You Learned

1. **mTLS** requires both parties to present certificates
2. **serverAuth** EKU = server proves identity to client
3. **clientAuth** EKU = client proves identity to server
4. **No passwords** - cryptographic proof only
5. **ML-DSA-65** ensures authentication survives quantum computers

---

## References

- [RFC 8446: TLS 1.3](https://tools.ietf.org/html/rfc8446)
- [NIST FIPS 204: ML-DSA Standard](https://csrc.nist.gov/pubs/fips/204/final)
- [Zero Trust Architecture (NIST SP 800-207)](https://csrc.nist.gov/publications/detail/sp/800-207/final)

---

← [Crypto-Agility](../10-crypto-agility/) | [Next: PQC Tunnel →](../12-pqc-tunnel/)
