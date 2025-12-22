# Mission 3: "Show Me Your Badge"

## mTLS Authentication with ML-DSA

### The Problem

You have a server. Clients want to connect to it.
How do you know it's really Alice and not an impostor?

```
Classic HTTPS = One-way verification
────────────────────────────────────

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

### The Threat

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

### The Solution: mTLS (mutual TLS)

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

## What You'll Do

1. **Create a server certificate** with ML-DSA-65 and SAN
2. **Create client certificates** for Alice and Bob
3. **Verify authentication**: Alice OK, unknown rejected
4. **Test the chain of trust**: all signed by the same CA

---

## Real-World Use Cases

| Scenario | Why mTLS? |
|----------|-----------|
| Microservices API | Each service authenticates to others |
| IoT devices | Each device proves its identity to backend |
| Zero-trust network | No implicit trust, everything is verified |
| CI/CD pipelines | Runners authenticate to registries |

---

## What You'll Have at the End

- Server certificate ML-DSA with SAN
- 2 client certificates (Alice, Bob)
- Proof that mTLS works with PQC
- Successful cross-verification

---

## Run the Mission

```bash
./demo.sh
```

---

← [Hybrid](../03-hybrid/) | [Next: Code Signing →](../05-code-signing/)
