---
jupytext:
  text_representation:
    extension: .md
    format_name: myst
kernelspec:
  display_name: Python 3
  language: python
  name: python3
---

# Chapter 7: Randomness and Stream Ciphers

## Introduction

Randomness sits at the heart of cryptography. Every key, nonce, and padding byte ultimately draws its security from unpredictability. In this chapter, we trace the path from **naive random numbers** through **true entropy** to the two encryption schemes built on top of randomness: the theoretically perfect **One-Time Pad** and the practical **Stream Cipher**.

```{admonition} Learning Objectives
:class: tip
By the end of this chapter you will be able to:
- Explain what a PRNG is and how the `rand()` function works internally
- Describe why `rand()` (and any deterministic PRNG) is **cryptographically insecure**
- Define **entropy** and explain how hardware generates true random numbers
- Prove the perfect secrecy of the **One-Time Pad** and state its requirements
- Explain how stream ciphers trade OTP's perfect security for practicality
- Describe the **ChaCha20** stream cipher, including its state, quarter-round, and encryption pipeline
```

---

## Warm-Up: Predict the Next Number

A program uses `rand()` to generate encryption keys. Its first output is **1250496027**. Without knowing the seed, can an attacker predict the next value? What does this imply about using `rand()` for cryptography?

```{admonition} Solution
:class: dropdown
Yes — `rand()` typically uses a **Linear Congruential Generator (LCG)** whose full state is a single integer. Given $x_0 = 1250496027$, the next value is deterministic:

$$x_1 = (1103515245 \times 1250496027 + 12345) \bmod 2^{31} = 1082907587$$

An attacker who captures one `rand()` output can predict **all future outputs indefinitely** and reconstruct all past outputs. This makes `rand()` completely unsuitable for any security-sensitive value — keys, nonces, session tokens, or anything that must be unpredictable.
```

---

## 1. What Is Randomness?

In everyday language, "random" means *unpredictable*. A cryptographer is more precise:

```{admonition} Definition: Cryptographic Randomness
:class: note
A sequence of bits is **cryptographically random** if no polynomial-time algorithm can distinguish it from a truly uniformly random sequence with non-negligible probability.
```

Why does this matter? If an attacker can predict the next byte of your keystream — even slightly better than chance — they gain a foothold to break the cipher.

---

## 2. Pseudo-Random Number Generators (PRNG)

A **Pseudo-Random Number Generator** is a *deterministic* algorithm that, given an initial value called the **seed**, produces a long sequence of numbers that *look* random but are fully determined by that seed.

### 2.1 How `rand()` Works — the Linear Congruential Generator

The `rand()` function found in C's standard library and many other languages is typically implemented as a **Linear Congruential Generator (LCG)**:

$$X_{n+1} = (a \cdot X_n + c) \mod m$$

| Parameter | Role | Common value (glibc) |
|-----------|------|----------------------|
| $m$ | Modulus — output range | $2^{31}$ |
| $a$ | Multiplier | $1103515245$ |
| $c$ | Increment | $12345$ |
| $X_0$ | Seed | user-supplied (often time-based) |

The full state machine of an LCG looks like this:

```{mermaid}
flowchart LR
    SEED(["Seed X₀<br/>(e.g. time())"])
    S1["X₁ = (a·X₀ + c) mod m"]
    S2["X₂ = (a·X₁ + c) mod m"]
    S3["X₃ = (a·X₂ + c) mod m"]
    DOTS(["..."])

    SEED --> S1 --> S2 --> S3 --> DOTS

    style SEED fill:#4A90D9,color:#fff,stroke:#2c6fad
    style S1 fill:#7B68EE,color:#fff,stroke:#5a4fcf
    style S2 fill:#7B68EE,color:#fff,stroke:#5a4fcf
    style S3 fill:#7B68EE,color:#fff,stroke:#5a4fcf
    style DOTS fill:#999,color:#fff,stroke:#666
```

**Key insight:** given the same seed, every run produces the *identical* sequence.

```{code-cell} python
:tags: [thebe-init]

def lcg_rand(seed, a=1103515245, c=12345, m=2**31):
    """Simulate glibc-style rand() using a Linear Congruential Generator."""
    state = seed
    results = []
    for _ in range(10):
        state = (a * state + c) % m
        results.append(state)
    return results

seed = 42
sequence_1 = lcg_rand(seed)
sequence_2 = lcg_rand(seed)   # same seed → same sequence

print("Run 1 with seed 42:", sequence_1[:5])
print("Run 2 with seed 42:", sequence_2[:5])
print("Identical?", sequence_1 == sequence_2)
```

```{admonition} Observation
:class: warning
Two runs with the **same seed** produce the **same numbers**. There is no randomness — only the *appearance* of randomness.
```

---

## 3. Why `rand()` Is NOT Secure

### 3.1 The Seed Is Often Predictable

On many systems `rand()` is seeded with `time()` — the current Unix timestamp in seconds. An attacker who knows the approximate moment a program ran has fewer than a few million seeds to try, which is trivially brute-forceable.

### 3.2 Full State Recovery from Output

An LCG has only 31 bits of internal state. Seeing **one** output value is often enough to reconstruct the state and **predict every future output**:

```{code-cell} python
:tags: [thebe-init]

def recover_next_lcg(observed_output, a=1103515245, c=12345, m=2**31):
    """Given one LCG output, compute the next output directly."""
    # The observed value IS the current state in a simple LCG
    next_state = (a * observed_output + c) % m
    return next_state

observed = 1250496027     # attacker captures one rand() output
predicted = recover_next_lcg(observed)
print(f"Attacker observed: {observed}")
print(f"Attacker predicts next value: {predicted}")

# Verify against the actual sequence
actual = lcg_rand(42)
print(f"\nActual sequence:   {actual[:5]}")
print(f"  Observed value at index 0: {actual[0]}")
print(f"  Predicted index 1:         {predicted}")
print(f"  Actual index 1:            {actual[1]}")
print(f"  Match: {predicted == actual[1]}")
```

```{admonition} Security Verdict: rand() is BROKEN for cryptography
:class: danger
- **Predictable from a single output** (state is fully exposed)
- **Short state** → short period, auditable patterns
- **Time-based seeding** → seed space is tiny
- **Never** use `rand()`, `random.random()`, or `Math.random()` for keys, nonces, tokens, or any security-sensitive value.
```

### 3.3 The Right Tool: CSPRNG

A **Cryptographically Secure PRNG (CSPRNG)** satisfies two extra properties:

| Property | Meaning |
|----------|---------|
| **Next-bit test** | Given all previous bits, no algorithm can predict the next bit better than 50 % |
| **State compromise resistance** | Learning the current state reveals nothing about past outputs |

Examples: `os.urandom()`, `/dev/urandom`, `secrets` module (Python), `CryptGenRandom` (Windows).

```{code-cell} python
:tags: [thebe-init]

import os
import secrets

# Correct way to generate random bytes for cryptographic use
secure_key_16 = os.urandom(16)           # 128-bit key
secure_key_32 = secrets.token_bytes(32)  # 256-bit key

print("CSPRNG 128-bit key (hex):", secure_key_16.hex())
print("CSPRNG 256-bit key (hex):", secure_key_32.hex())
print("\nEach run produces DIFFERENT values — seeded from OS entropy pool.")
```

---

## 4. Entropy and True Randomness

### 4.1 What Is Entropy?

**Entropy** is a measure of *unpredictability*, borrowed from Shannon's information theory:

$$H = -\sum_{i} p_i \log_2 p_i \quad \text{(bits)}$$

A single fair coin flip has 1 bit of entropy. A 256-bit cryptographic key should have 256 bits of entropy — meaning an attacker must try all $2^{256}$ possibilities.

### 4.2 True Random Number Generators (TRNG)

TRNGs harvest **physical entropy** — phenomena so complex they cannot be predicted:

```{mermaid}
flowchart TD
    subgraph HARDWARE ["Hardware Entropy Sources"]
        direction TB
        A["⌨ Keyboard timing<br/>jitter"]
        B["🖱 Mouse movement<br/>micro-delays"]
        C["💽 Disk I/O<br/>latency noise"]
        D["🌡 Thermal noise<br/>in CPU/RAM"]
        E["🔬 Photon arrival<br/>times (HSM)"]
    end

    subgraph OS ["OS Entropy Pool (/dev/random, RDRAND)"]
        POOL["Entropy Pool<br/>(collected bits mixed<br/>by cryptographic hash)"]
    end

    subgraph OUTPUT ["Output"]
        CSPRNG2["CSPRNG (e.g. ChaCha20)<br/>seeded from pool"]
        RAND_OUT(["Cryptographically<br/>Random Bytes"])
    end

    A & B & C & D & E --> POOL
    POOL --> CSPRNG2 --> RAND_OUT

    style HARDWARE fill:#2d6a4f,color:#fff,stroke:#1b4332
    style OS fill:#1d3557,color:#fff,stroke:#0d1b2a
    style OUTPUT fill:#6d3b47,color:#fff,stroke:#4a2030
```

The operating system continuously mixes these sources into an **entropy pool**, which is then stretched by a CSPRNG to produce an unlimited stream of cryptographically strong bytes.

---

## 5. The One-Time Pad (OTP)

Joseph Mauborgne proposed an improvement to the Vernam cipher that yields the ultimate in security. Mauborgne suggested using a **random key that is as long as the message**, so that the key need not be repeated. In addition, the key is to be used to encrypt and decrypt a single message, and then is discarded. Each new message requires a new key of the same length as the new message.

Such a scheme, known as a **one-time pad**, is unbreakable. It produces random output that bears no statistical relationship to the plaintext. Because the ciphertext contains no information whatsoever about the plaintext, there is simply no way to break the code.

The **One-Time Pad** is the only encryption scheme proven to be **perfectly secure** — even against an attacker with unlimited computation.

The security of the one-time pad is entirely due to the randomness of the key. If the stream of characters that constitute the key is truly random, then the stream of characters that constitute the ciphertext will be truly random. Thus, there are no patterns or regularities that a cryptanalyst can use to attack the ciphertext.

The one-time pad offers complete security but, in practice, has two fundamental difficulties:

1. **Key generation:** There is the practical problem of making large quantities of random keys. Any heavily used system might require millions of random characters on a regular basis. Supplying truly random characters in this volume is a significant task.
2. **Key distribution:** Even more daunting is the problem of key distribution and protection. For every message to be sent, a key of equal length is needed by both sender and receiver. Thus, a mammoth key distribution problem exists.

### 5.1 How OTP Works

$$C_i = P_i \oplus K_i$$
$$P_i = C_i \oplus K_i$$

Where:
- $P$ is the plaintext byte sequence
- $K$ is the key (pad) — must be **truly random, as long as the plaintext, and never reused**
- $C$ is the ciphertext
- $\oplus$ is the XOR operation

```{mermaid}
flowchart LR
    TRNG(["🎲 TRNG<br/>True Random Bytes"])
    KEY["Key K<br/>(same length as P<br/>shared securely)"]
    PLAIN["Plaintext P"]
    XOR_E["⊕ XOR"]
    CIPHER["Ciphertext C"]
    XOR_D["⊕ XOR"]
    PLAIN2["Plaintext P"]

    TRNG --> KEY
    PLAIN --> XOR_E
    KEY --> XOR_E --> CIPHER

    CIPHER --> XOR_D
    KEY --> XOR_D --> PLAIN2

    style TRNG fill:#2d6a4f,color:#fff,stroke:#1b4332
    style KEY fill:#e9c46a,color:#000,stroke:#d4a017
    style CIPHER fill:#e63946,color:#fff,stroke:#b5000e
    style XOR_E fill:#457b9d,color:#fff,stroke:#1d3557
    style XOR_D fill:#457b9d,color:#fff,stroke:#1d3557
    style PLAIN2 fill:#52b788,color:#fff,stroke:#2d6a4f
```

### 5.1 Solved Example — OTP Encryption and Decryption

```{prf:example} One-Time Pad — Step-by-Step
:label: ex-otp-solved

**Problem:** Encrypt the plaintext `"HELLO"` using the one-time pad with the key `"XMCKL"`.

---

**Step 1 — Convert letters to numbers** (A = 0, B = 1, …, Z = 25):

| | H | E | L | L | O |
|---|---|---|---|---|---|
| **Plaintext (P)** | 7 | 4 | 11 | 11 | 14 |
| **Key (K)** | 23 | 12 | 2 | 10 | 11 |

---

**Step 2 — Encrypt:** $C_i = (P_i + K_i) \bmod 26$

| | H | E | L | L | O |
|---|---|---|---|---|---|
| $P_i$ | 7 | 4 | 11 | 11 | 14 |
| $K_i$ | 23 | 12 | 2 | 10 | 11 |
| $P_i + K_i$ | 30 | 16 | 13 | 21 | 25 |
| $C_i = (P_i + K_i) \bmod 26$ | **4** | **16** | **13** | **21** | **25** |
| **Ciphertext letter** | **E** | **Q** | **N** | **V** | **Z** |

**Ciphertext: `EQNVZ`**

---

**Step 3 — Decrypt:** $P_i = (C_i - K_i) \bmod 26$

| | E | Q | N | V | Z |
|---|---|---|---|---|---|
| $C_i$ | 4 | 16 | 13 | 21 | 25 |
| $K_i$ | 23 | 12 | 2 | 10 | 11 |
| $C_i - K_i$ | −19 | 4 | 11 | 11 | 14 |
| $P_i = (C_i - K_i) \bmod 26$ | **7** | **4** | **11** | **11** | **14** |
| **Plaintext letter** | **H** | **E** | **L** | **L** | **O** |

**Recovered plaintext: `HELLO`** ✓

---

**Key observations:**
- The key is used **once only** and then discarded.
- Without the key, every 5-letter word is equally likely to be the plaintext — perfect secrecy holds.
```

### 5.2 Formal Definition of Perfect Secrecy

```{admonition} Shannon's Definition — Perfect Secrecy (1949)
:class: tip
An encryption scheme provides **perfect secrecy** if for every plaintext $P$, every ciphertext $C$, and every possible message distribution:

$$\Pr[P = p \mid C = c] = \Pr[P = p]$$

In words: **Observing the ciphertext gives no additional information about the plaintext.**

Equivalently: every plaintext is equally likely to produce any given ciphertext — ciphertext alone reveals nothing.
```

**Intuition:** With perfect secrecy, intercepting ciphertext "XQBR" tells you nothing:
- It could decrypt to "HELP" with probability $\frac{1}{26^4}$
- It could decrypt to "FIRE" with probability $\frac{1}{26^4}$
- All four-letter words are equally probable — the attacker gains nothing.

### 5.3 The Uniform Distribution Requirement

For perfect secrecy, the **ciphertext must follow a uniform distribution** over all possible ciphertexts:

$$\Pr[C = c] = \frac{1}{|\mathcal{C}|} \quad \text{for every possible ciphertext } c$$

```{admonition} Why Uniformity Matters
:class: warning
**Non-uniform distribution (broken cipher):**

| Ciphertext | Frequency |
|-----------|-----------|
| 'Q' | 15% — exploitable |
| 'W' | 12% — exploitable |
| 'Z' | 1%  — exploitable |

Statistical patterns reveal information about the plaintext — frequency analysis works.

---

**Uniform distribution (perfect secrecy):**

| Ciphertext | Frequency |
|-----------|-----------|
| Every symbol | $\approx \frac{1}{|\mathcal{C}|}$ |

No statistical patterns to exploit — cryptanalysis is impossible.
```

### 5.4 Shannon's Theorem

```{admonition} Shannon's Theorem (1949)
:class: tip
Perfect secrecy is achievable **if and only if**:

1. $|\mathcal{K}| \geq |\mathcal{M}|$ — the number of possible keys is at least as large as the number of possible plaintexts
2. Every key is used with **equal probability**
3. Every plaintext–key pair produces a **unique ciphertext**

**Key implication:** The key must be **at least as long as the plaintext** and **never reused**.

The only known cipher meeting all three conditions: **The One-Time Pad**.
```

**Proof sketch for the OTP:** For any observed ciphertext $c$ and any candidate plaintext $p'$, there exists exactly one key $k' = c \oplus p'$ that would encrypt $p'$ to $c$. Since every key is equally likely and the mapping is bijective, every plaintext is equally probable given $c$ — perfect secrecy holds.

### 5.5 Shannon's Proof for the OTP

Shannon proved in 1949 that for the OTP:

$$\Pr[P = p \mid C = c] = \Pr[P = p]$$

Seeing the ciphertext gives an attacker **zero information** about the plaintext. For every possible plaintext $p$, there exists exactly one key $k$ that would produce the observed ciphertext $c$. The attacker cannot distinguish which is correct.

```{code-cell} python
:tags: [thebe-init]

import os

def otp_encrypt(plaintext: bytes, key: bytes) -> bytes:
    assert len(key) >= len(plaintext), "Key must be at least as long as plaintext!"
    return bytes(p ^ k for p, k in zip(plaintext, key))

otp_decrypt = otp_encrypt  # XOR is its own inverse

message = b"ATTACK AT DAWN"
key = os.urandom(len(message))        # TRUE random key from OS entropy

ciphertext = otp_encrypt(message, key)
recovered  = otp_decrypt(ciphertext, key)

print(f"Plaintext:  {message}")
print(f"Key (hex):  {key.hex()}")
print(f"Ciphertext: {ciphertext.hex()}")
print(f"Recovered:  {recovered}")
print(f"Correct:    {recovered == message}")
```

### 5.6 OTP Requirements and Limitations

| Requirement | Consequence if violated |
|-------------|------------------------|
| Key is **truly random** | Cipher reduces to a weaker stream cipher |
| Key is **as long as the plaintext** | Cannot encrypt more than $(|K|)$ bits |
| Key is **used only once** | Two-time pad attack: $C_1 \oplus C_2 = P_1 \oplus P_2$ leaks plaintext XOR |
| Key is **distributed securely** | If key channel is insecure, why not send the message there directly? |

```{admonition} The OTP Dilemma
:class: warning
If you have a secure channel for sending a key as long as your message, you already have a secure channel — just send the message there. The OTP is theoretically perfect but practically impractical for most use cases.
```

---

## 6. Stream Ciphers — Practical Approximations of the OTP

A stream cipher *simulates* the OTP by replacing the truly random key with a **CSPRNG keystream** seeded by a short secret key:

```{mermaid}
flowchart LR
    subgraph OTP_COL ["One-Time Pad"]
        T1(["TRNG 🎲"])
        K1["Truly Random<br/>Keystream"]
        E1["⊕"]
        T1 --> K1 --> E1
    end

    subgraph SC_COL ["Stream Cipher"]
        T2["Secret Key<br/>+ Nonce"]
        K2["CSPRNG<br/>Keystream"]
        E2["⊕"]
        T2 --> K2 --> E2
    end

    P1["Plaintext"] --> E1 --> C1["Ciphertext"]
    P2["Plaintext"] --> E2 --> C2["Ciphertext"]

    style T1 fill:#2d6a4f,color:#fff
    style K1 fill:#52b788,color:#fff
    style T2 fill:#e9c46a,color:#000
    style K2 fill:#f4a261,color:#000
    style E1 fill:#457b9d,color:#fff
    style E2 fill:#457b9d,color:#fff
    style C1 fill:#e63946,color:#fff
    style C2 fill:#e63946,color:#fff
```

| Property | One-Time Pad | Stream Cipher |
|----------|-------------|---------------|
| Keystream source | TRNG (true random) | CSPRNG (seeded) |
| Key length | = message length | Short (128–256 bits) |
| Theoretical security | **Perfect** (information-theoretic) | Computational (breaks if CSPRNG breaks) |
| Practical usability | Impractical | ✅ Widely used |
| Reuse key? | Never — breaks completely | Never — but shorter impact |

The trade-off is clear: stream ciphers are **computationally secure** (secure only against bounded adversaries), not information-theoretically secure. Their safety depends entirely on the quality of the underlying CSPRNG.

---

## 7. RC4 — The Simplest Stream Cipher (and Why It Broke)

**RC4** (Rivest Cipher 4), designed by Ron Rivest in 1987, was the most widely deployed stream cipher in history — used in WEP, WPA, SSL/TLS, and SSH for over two decades. Its appeal was extreme simplicity: the entire cipher fits in about 15 lines of code.

### 7.1 RC4 Internal State

RC4 maintains a single array `S` of 256 bytes — a permutation of 0–255 — plus two indices `i` and `j`:

```{mermaid}
flowchart LR
    subgraph STATE ["RC4 State"]
        S["S[0..255]<br/>(256-byte permutation)"]
        IJ["i = 0, j = 0<br/>(two byte indices)"]
    end
    KEY(["Key<br/>(1–256 bytes)"])
    OUT(["Keystream byte<br/>S[S[i]+S[j]]"])

    KEY -->|"Key Scheduling<br/>Algorithm (KSA)"| S
    STATE -->|"Pseudo-Random<br/>Generation (PRGA)"| OUT

    style KEY fill:#e9c46a,color:#000,stroke:#d4a017
    style S fill:#457b9d,color:#fff,stroke:#1d3557
    style IJ fill:#457b9d,color:#fff,stroke:#1d3557
    style OUT fill:#e63946,color:#fff,stroke:#b5000e
```

### 7.2 RC4 Algorithm Step by Step

**Phase 1 — Key Scheduling (KSA):** Initialise `S = [0,1,…,255]` then scramble it using the key:

```{mermaid}
flowchart TD
    INIT["S = [0, 1, 2, ..., 255]<br/>j = 0"]
    LOOP["for i in 0..255"]
    CALC["j = (j + S[i] + key[i mod keylen]) mod 256"]
    SWAP["swap S[i] and S[j]"]
    DONE(["S is now a<br/>key-dependent permutation"])

    INIT --> LOOP --> CALC --> SWAP --> LOOP
    LOOP -->|"i = 255 done"| DONE

    style INIT fill:#1d3557,color:#fff
    style CALC fill:#457b9d,color:#fff
    style SWAP fill:#457b9d,color:#fff
    style DONE fill:#2d6a4f,color:#fff
```

**Phase 2 — Pseudo-Random Generation (PRGA):** Output one keystream byte per step:

```{mermaid}
flowchart LR
    START(["i = 0, j = 0"])
    INC["i = (i + 1) mod 256"]
    JSTEP["j = (j + S[i]) mod 256"]
    SW["swap S[i] and S[j]"]
    OUT["t = (S[i] + S[j]) mod 256<br/>output S[t]"]
    XOR["⊕ XOR with plaintext byte"]

    START --> INC --> JSTEP --> SW --> OUT --> XOR --> INC

    style INC fill:#457b9d,color:#fff
    style JSTEP fill:#457b9d,color:#fff
    style SW fill:#457b9d,color:#fff
    style OUT fill:#6d3b47,color:#fff
    style XOR fill:#1d3557,color:#fff
```

### 7.3 RC4 in Python

```{code-cell} python
:tags: [thebe-init]

def rc4(key: bytes, data: bytes) -> bytes:
    """RC4 stream cipher — educational implementation only, NOT secure."""
    # Key Scheduling Algorithm (KSA)
    S = list(range(256))
    j = 0
    for i in range(256):
        j = (j + S[i] + key[i % len(key)]) % 256
        S[i], S[j] = S[j], S[i]

    # Pseudo-Random Generation Algorithm (PRGA)
    i = j = 0
    keystream = []
    for _ in data:
        i = (i + 1) % 256
        j = (j + S[i]) % 256
        S[i], S[j] = S[j], S[i]
        t = (S[i] + S[j]) % 256
        keystream.append(S[t])

    return bytes(b ^ k for b, k in zip(data, keystream))


key     = b"SecretKey"
message = b"ATTACK AT DAWN"

ciphertext = rc4(key, message)
recovered  = rc4(key, ciphertext)   # RC4 is its own inverse

print(f"Plaintext:  {message}")
print(f"Key:        {key}")
print(f"Ciphertext: {ciphertext.hex()}")
print(f"Decrypted:  {recovered}")
print(f"Match:      {recovered == message}")
```

### 7.4 Why RC4 Is Broken

```{admonition} RC4 Vulnerabilities
:class: danger
- **First-byte bias:** The first bytes of the keystream are statistically biased — `S[0]` is often equal to the second key byte. Drop at least 256 bytes of keystream before use ("RC4-drop256").
- **WEP attack (FMS/KoreK):** WEP reused key prefixes across packets, letting attackers recover the full key from ~1 million packets.
- **BEAST/POODLE/RC4 attacks (2013–2015):** Statistical biases in the keystream allowed partial plaintext recovery in HTTPS after collecting millions of TLS records.
- **RFC 7465 (2015):** RC4 was formally **prohibited** in TLS by the IETF.
```

**Never use RC4 in production.** It is included here solely to understand how stream ciphers evolved and why the design principles of ChaCha20 matter.

---

### 7.5 Solved Example — RC4 Step by Step (Toy N = 8)

To keep the walkthrough human-traceable, we use a **toy version of RC4 with N = 8** — the state array `S` holds 8 entries (0–7) and all arithmetic is **mod 8**. Real RC4 uses N = 256 with mod 256; the algorithm structure is identical.

**Given:**

| Parameter | Value |
|:---|:---|
| N | 8 |
| Key | `[1, 2, 3]` |
| Plaintext | `"Hi"` = \[72, 105\] |

---

#### Phase 1 — Key Scheduling Algorithm (KSA)

**Initialise:** `S = [0, 1, 2, 3, 4, 5, 6, 7]`, `j = 0`

For each `i` from 0 to 7: `j = (j + S[i] + key[i mod 3]) mod 8`, then swap `S[i] ↔ S[j]`.

| i | key[i mod 3] | j_old | j_new | Swap | S after swap |
|:---:|:---:|:---:|:---:|:---:|:---|
| 0 | 1 | 0 | (0+0+1) mod 8 = **1** | S[0] ↔ S[1] | `[1, 0, 2, 3, 4, 5, 6, 7]` |
| 1 | 2 | 1 | (1+0+2) mod 8 = **3** | S[1] ↔ S[3] | `[1, 3, 2, 0, 4, 5, 6, 7]` |
| 2 | 3 | 3 | (3+2+3) mod 8 = **0** | S[2] ↔ S[0] | `[2, 3, 1, 0, 4, 5, 6, 7]` |
| 3 | 1 | 0 | (0+0+1) mod 8 = **1** | S[3] ↔ S[1] | `[2, 0, 1, 3, 4, 5, 6, 7]` |
| 4 | 2 | 1 | (1+4+2) mod 8 = **7** | S[4] ↔ S[7] | `[2, 0, 1, 3, 7, 5, 6, 4]` |
| 5 | 3 | 7 | (7+5+3) mod 8 = **7** | S[5] ↔ S[7] | `[2, 0, 1, 3, 7, 4, 6, 5]` |
| 6 | 1 | 7 | (7+6+1) mod 8 = **6** | S[6] ↔ S[6] | `[2, 0, 1, 3, 7, 4, 6, 5]` *(no change)* |
| 7 | 2 | 6 | (6+5+2) mod 8 = **5** | S[7] ↔ S[5] | `[2, 0, 1, 3, 7, 5, 6, 4]` |

**S after KSA = `[2, 0, 1, 3, 7, 5, 6, 4]`** — a key-dependent permutation of 0–7 ✓

---

#### Phase 2 — Pseudo-Random Generation (PRGA)

**Starting state:** `i = 0`, `j = 0`, `S = [2, 0, 1, 3, 7, 5, 6, 4]`

For each output byte: `i = (i+1) mod 8`, `j = (j + S[i]) mod 8`, swap `S[i] ↔ S[j]`, output `S[(S[i]+S[j]) mod 8]`.

| Step | i | j | Swap | t = (S[i]+S[j]) mod 8 | **k = S[t]** | S after swap |
|:---:|:---:|:---:|:---:|:---:|:---:|:---|
| 1 | 1 | (0+**S[1]**=0) mod 8 = **0** | S[1] ↔ S[0] | (2+0) mod 8 = 2 | **S[2] = 1** | `[0, 2, 1, 3, 7, 5, 6, 4]` |
| 2 | 2 | (0+**S[2]**=1) mod 8 = **1** | S[2] ↔ S[1] | (2+1) mod 8 = 3 | **S[3] = 3** | `[0, 1, 2, 3, 7, 5, 6, 4]` |

**Keystream = `[1, 3]`**

---

#### Encryption

$$\text{ciphertext}_i = \text{plaintext}_i \oplus k_i$$

| Byte | Plaintext | Hex | Keystream | XOR | **Ciphertext** | Hex |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | `H` = 72 | `0x48` | k₁ = 1 | 72 ⊕ 1 = **73** | 73 | `0x49` |
| 2 | `i` = 105 | `0x69` | k₂ = 3 | 105 ⊕ 3 = **106** | 106 | `0x6A` |

**Ciphertext = `[0x49, 0x6A]`**

---

#### Decryption

RC4 is **its own inverse** — applying the same keystream to the ciphertext recovers the plaintext:

| Byte | Ciphertext | Hex | Keystream | XOR | **Plaintext** |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | 73 | `0x49` | k₁ = 1 | 73 ⊕ 1 = **72** | `H` ✓ |
| 2 | 106 | `0x6A` | k₂ = 3 | 106 ⊕ 3 = **105** | `i` ✓ |

**Recovered plaintext = `"Hi"` ✓**

```{admonition} Toy vs. Real RC4
:class: note
This N=8 example uses **mod 8** arithmetic to keep tables human-readable. Real RC4 runs the same algorithm with **N = 256, mod 256**, performing 256 KSA rounds and generating one byte of keystream per plaintext byte. The Python implementation in §7.3 executes the full algorithm.
```

---

## 8. Trivium — An Elegant Hardware Stream Cipher

**Trivium**, designed by Christophe De Cannière and Bart Preneel in 2006, is an eSTREAM Portfolio finalist. It was designed to be hardware-efficient, and its internal structure is remarkably clean compared to RC4.

### 8.1 Trivium State — Three Shift Registers

Trivium's entire state is just **288 bits** split across three non-linear feedback shift registers:

```{mermaid}
flowchart TD
    subgraph REG ["288-bit State"]
        A["Register A<br/>93 bits (s₁ … s₉₃)<br/>Init: key[0..79], rest = 0"]
        B["Register B<br/>84 bits (s₉₄ … s₁₇₇)<br/>Init: IV[0..79], rest = 0"]
        C["Register C<br/>111 bits (s₁₇₈ … s₂₈₈)<br/>Init: 0…0111"]
    end

    t1["t₁ = s₆₆ ⊕ s₉₃"]
    t2["t₂ = s₁₆₂ ⊕ s₁₇₇"]
    t3["t₃ = s₂₄₃ ⊕ s₂₈₈"]

    OUT["Output bit z = t₁ ⊕ t₂ ⊕ t₃"]

    FB_A["s₁ ← t₃ ⊕ (s₂₈₆ AND s₂₈₇) ⊕ s₆₉"]
    FB_B["s₉₄ ← t₁ ⊕ (s₉₁ AND s₉₂) ⊕ s₁₇₁"]
    FB_C["s₁₇₈ ← t₂ ⊕ (s₁₇₅ AND s₁₇₆) ⊕ s₂₄₈"]

    REG --> t1 & t2 & t3
    t1 & t2 & t3 --> OUT
    t1 --> FB_B
    t2 --> FB_C
    t3 --> FB_A

    style A fill:#1d3557,color:#fff
    style B fill:#457b9d,color:#fff
    style C fill:#2d6a4f,color:#fff
    style OUT fill:#e63946,color:#fff
    style FB_A fill:#6d3b47,color:#fff
    style FB_B fill:#6d3b47,color:#fff
    style FB_C fill:#6d3b47,color:#fff
```

Each clock cycle:
1. Compute three tap values `t₁`, `t₂`, `t₃`
2. XOR them → one output bit
3. Feed each `tₙ` (with a non-linear AND term) back into the *next* register — creating the mixing between the three registers

The non-linear AND gates (`s₉₁ AND s₉₂`, etc.) prevent the cipher from being broken by linear cryptanalysis.

### 8.2 Trivium Key Setup

Before generating keystream, Trivium runs **1152 blank clock cycles** (18 × 64) to fully mix the key and IV into the state — no output is produced during this phase:

```{mermaid}
flowchart LR
    LOAD["Load:<br/>A ← key (80 bits)<br/>B ← IV (80 bits)<br/>C[109..111] ← 111"]
    WARM["Warm-up:<br/>Clock 1152 times<br/>(discard output)"]
    READY(["State fully mixed —<br/>keystream generation begins"])

    LOAD --> WARM --> READY

    style LOAD fill:#1d3557,color:#fff
    style WARM fill:#457b9d,color:#fff
    style READY fill:#2d6a4f,color:#fff
```

### 8.3 Trivium in Python

```{code-cell} python
:tags: [thebe-init]

def trivium(key_bits: list, iv_bits: list, length: int) -> bytes:
    """
    Trivium stream cipher — educational implementation.
    key_bits: list of 80 bits (LSB first)
    iv_bits:  list of 80 bits (LSB first)
    length:   number of output BYTES requested
    """
    # Initialise 288-bit state as three registers
    s = [0] * 288
    s[0:80]   = key_bits        # Register A ← key
    s[93:173] = iv_bits         # Register B ← IV
    s[285] = s[286] = s[287] = 1  # Register C tail = 111

    def clock():
        t1 = s[65]  ^ s[92]
        t2 = s[161] ^ s[176]
        t3 = s[242] ^ s[287]
        out_bit = t1 ^ t2 ^ t3
        # Feedback with non-linear AND term
        new_s0   = t3 ^ (s[285] & s[286]) ^ s[68]
        new_s93  = t1 ^ (s[90]  & s[91])  ^ s[170]
        new_s177 = t2 ^ (s[174] & s[175]) ^ s[263]
        # Shift registers (rotate right by inserting at position 0)
        s[1:93]  = s[0:92]
        s[0]     = new_s0
        s[94:177] = s[93:176]
        s[93]    = new_s93
        s[178:288] = s[177:287]
        s[177]   = new_s177
        return out_bit

    # Warm-up: 1152 clock cycles, no output
    for _ in range(1152):
        clock()

    # Generate keystream
    keystream_bits = [clock() for _ in range(length * 8)]
    keystream = bytes(
        sum(keystream_bits[i*8 + b] << b for b in range(8))
        for i in range(length)
    )
    return keystream


def int_to_bits(n: int, length: int) -> list:
    """Convert integer to LSB-first bit list of given length."""
    return [(n >> i) & 1 for i in range(length)]


message  = b"Hello Trivium!"
key_int  = 0xDEADBEEFCAFEBABE0102  # 80-bit key as integer
iv_int   = 0x00112233445566778899  # 80-bit IV

key_bits = int_to_bits(key_int, 80)
iv_bits  = int_to_bits(iv_int,  80)

ks         = trivium(key_bits, iv_bits, len(message))
ciphertext = bytes(p ^ k for p, k in zip(message, ks))
recovered  = bytes(c ^ k for c, k in zip(ciphertext, trivium(key_bits, iv_bits, len(message))))

print(f"Plaintext:  {message}")
print(f"Keystream:  {ks.hex()}")
print(f"Ciphertext: {ciphertext.hex()}")
print(f"Decrypted:  {recovered}")
print(f"Match:      {recovered == message}")
```

### 8.4 Trivium vs RC4 vs ChaCha20

| Property | RC4 | Trivium | ChaCha20 |
|----------|-----|---------|----------|
| State size | 2 058 bits (256×8 + 2 indices) | **288 bits** | 512 bits |
| Key size | 40–2048 bits | 80 bits | 256 bits |
| IV/Nonce | None (dangerous) | 80 bits | 96 bits |
| Design | Array permutation | 3 shift registers | ARX matrix |
| Hardware efficiency | Poor | **Excellent** | Moderate |
| Software speed | Fast | Moderate | **Fastest** |
| Security | ❌ Broken | ✅ (no known attack) | ✅ Proven |
| Use today | Never | Embedded/IoT only | **Recommended** |

---

## 9. ChaCha20 — A Modern Stream Cipher

**ChaCha20**, designed by Daniel J. Bernstein in 2008, is one of the most widely deployed stream ciphers today. It powers:
- **TLS 1.3** (HTTPS on most of the internet)
- **WireGuard** VPN
- **SSH** (OpenSSH)
- **Android/iOS** disk encryption
- **Signal**, **WhatsApp**, **Google Chrome**

It replaced the broken RC4 and is preferred over AES-CTR in software implementations for its speed and resistance to timing attacks.

### 9.1 ChaCha20 State

ChaCha20 operates on a **4 × 4 matrix of 32-bit words** (512 bits total):

```{mermaid}
block-beta
    columns 4
    C0["🔵 'expa'<br/>Constant 0"]:1
    C1["🔵 'nd 3'<br/>Constant 1"]:1
    C2["🔵 '2-by'<br/>Constant 2"]:1
    C3["🔵 'te k'<br/>Constant 3"]:1
    K0["🟡 Key[0]"]:1
    K1["🟡 Key[1]"]:1
    K2["🟡 Key[2]"]:1
    K3["🟡 Key[3]"]:1
    K4["🟡 Key[4]"]:1
    K5["🟡 Key[5]"]:1
    K6["🟡 Key[6]"]:1
    K7["🟡 Key[7]"]:1
    CTR["🟢 Counter"]:1
    N0["🔴 Nonce[0]"]:1
    N1["🔴 Nonce[1]"]:1
    N2["🔴 Nonce[2]"]:1

    style C0 fill:#1d3557,color:#fff,stroke:#0d1b2a
    style C1 fill:#1d3557,color:#fff,stroke:#0d1b2a
    style C2 fill:#1d3557,color:#fff,stroke:#0d1b2a
    style C3 fill:#1d3557,color:#fff,stroke:#0d1b2a
    style K0 fill:#e9c46a,color:#000,stroke:#d4a017
    style K1 fill:#e9c46a,color:#000,stroke:#d4a017
    style K2 fill:#e9c46a,color:#000,stroke:#d4a017
    style K3 fill:#e9c46a,color:#000,stroke:#d4a017
    style K4 fill:#e9c46a,color:#000,stroke:#d4a017
    style K5 fill:#e9c46a,color:#000,stroke:#d4a017
    style K6 fill:#e9c46a,color:#000,stroke:#d4a017
    style K7 fill:#e9c46a,color:#000,stroke:#d4a017
    style CTR fill:#52b788,color:#fff,stroke:#2d6a4f
    style N0 fill:#e63946,color:#fff,stroke:#b5000e
    style N1 fill:#e63946,color:#fff,stroke:#b5000e
    style N2 fill:#e63946,color:#fff,stroke:#b5000e
```

- **Constants (blue):** fixed "expand 32-byte k" ASCII bytes — no hidden backdoor possible
- **Key (yellow):** 256-bit secret key (8 × 32-bit words)
- **Counter (green):** starts at 0, increments by 1 per 64-byte block — enables random access
- **Nonce (red):** 96-bit one-time value — ensures unique keystream per message

### 9.2 The Quarter-Round — ChaCha20's Core Mixing Step

All security comes from 20 rounds of a simple **quarter-round** applied to four 32-bit words $a, b, c, d$:

$$a \mathrel{+}= b;\quad d \mathrel{\oplus}= a;\quad d \lll 16$$
$$c \mathrel{+}= d;\quad b \mathrel{\oplus}= c;\quad b \lll 12$$
$$a \mathrel{+}= b;\quad d \mathrel{\oplus}= a;\quad d \lll 8$$
$$c \mathrel{+}= d;\quad b \mathrel{\oplus}= c;\quad b \lll 7$$

Where $\lll$ is a **left rotation** (not shift). The operations are add–XOR–rotate (ARX), chosen specifically because they are:
- **Constant-time** (no secret-dependent branches or table lookups → immune to timing attacks)
- **Hardware-efficient** with no lookup tables
- **Fully invertible** in the proof

```{mermaid}
%%{init: {'flowchart': {'nodeSpacing': 30, 'rankSpacing': 30}, 'themeVariables': {'fontSize': '12px'}}}%%
flowchart LR
    INPUT["a, b, c, d"]
    R1["① a+=b · d^=a · d&lt;&lt;&lt;16"]
    R2["② c+=d · b^=c · b&lt;&lt;&lt;12"]
    R3["③ a+=b · d^=a · d&lt;&lt;&lt;8"]
    R4["④ c+=d · b^=c · b&lt;&lt;&lt;7"]
    OUTPUT["a', b', c', d'"]

    INPUT --> R1 --> R2 --> R3 --> R4 --> OUTPUT

    style INPUT fill:#1d3557,color:#fff
    style R1 fill:#457b9d,color:#fff
    style R2 fill:#457b9d,color:#fff
    style R3 fill:#457b9d,color:#fff
    style R4 fill:#457b9d,color:#fff
    style OUTPUT fill:#2d6a4f,color:#fff
```

### 9.3 Full ChaCha20 Encryption Pipeline

```{mermaid}
flowchart TD
    KEY(["🔑 256-bit Key"])
    NONCE(["🎲 96-bit Nonce<br/>(unique per message)"])
    CTR_INIT(["🔢 Counter = 0"])

    subgraph BLOCK ["For each 64-byte block (counter = 0, 1, 2, ...)"]
        direction TB
        INIT["Build 4×4 initial state<br/>(constants + key + counter + nonce)"]
        ROUNDS["20 Quarter-Rounds<br/>(10× column rounds + 10× diagonal rounds)"]
        ADD["Add initial state to output state<br/>(prevents round inversion)"]
        KEYBLOCK["64 bytes of keystream"]
    end

    PLAIN["📄 Plaintext block<br/>(up to 64 bytes)"]
    XOR_OP["⊕ XOR"]
    CIPHER_OUT["🔒 Ciphertext block"]
    INC["Counter += 1"]

    KEY & NONCE & CTR_INIT --> INIT
    INIT --> ROUNDS --> ADD --> KEYBLOCK
    PLAIN --> XOR_OP
    KEYBLOCK --> XOR_OP --> CIPHER_OUT
    CIPHER_OUT --> INC --> INIT

    style KEY fill:#e9c46a,color:#000
    style NONCE fill:#e63946,color:#fff
    style CTR_INIT fill:#52b788,color:#fff
    style ROUNDS fill:#457b9d,color:#fff
    style ADD fill:#457b9d,color:#fff
    style KEYBLOCK fill:#6d3b47,color:#fff
    style XOR_OP fill:#1d3557,color:#fff
    style CIPHER_OUT fill:#e63946,color:#fff
    style INC fill:#52b788,color:#fff
```

The **final addition** of initial state to the scrambled state is critical — it prevents an attacker from inverting the rounds to recover the key.

### 9.4 ChaCha20 in Python

```{code-cell} python
:tags: [thebe-init]

import os
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms

def chacha20_encrypt(key: bytes, nonce: bytes, plaintext: bytes) -> bytes:
    """Encrypt plaintext with ChaCha20 using the cryptography library."""
    # Counter starts at 0, encoded as 4 little-endian bytes prefixed to nonce
    algorithm = algorithms.ChaCha20(key, nonce=b'\x00\x00\x00\x00' + nonce)
    cipher = Cipher(algorithm, mode=None)
    encryptor = cipher.encryptor()
    return encryptor.update(plaintext)

chacha20_decrypt = chacha20_encrypt  # stream cipher: same operation both ways

# Generate a random 256-bit key and 96-bit nonce
key   = os.urandom(32)   # 256 bits
nonce = os.urandom(12)   # 96 bits

message = b"Cryptography is the art of hiding in plain sight."

ciphertext = chacha20_encrypt(key, nonce, message)
recovered  = chacha20_decrypt(key, nonce, ciphertext)

print(f"Original : {message.decode()}")
print(f"Key      : {key.hex()}")
print(f"Nonce    : {nonce.hex()}")
print(f"Encrypted: {ciphertext.hex()}")
print(f"Decrypted: {recovered.decode()}")
print(f"Match    : {recovered == message}")
```

### 9.5 The Nonce-Reuse Catastrophe

Stream ciphers share OTP's fatal weakness: **reusing the same (key, nonce) pair with different messages**.

If $C_1 = P_1 \oplus K$ and $C_2 = P_2 \oplus K$, then:

$$C_1 \oplus C_2 = P_1 \oplus P_2$$

The keystream cancels, and the attacker has the XOR of two plaintexts — which is often enough to recover both.

```{code-cell} python
:tags: [thebe-init]

# DEMONSTRATION OF NONCE REUSE ATTACK
# (Never do this in real code!)

key   = os.urandom(32)
nonce = os.urandom(12)   # same nonce for BOTH messages — catastrophic!

msg1 = b"TRANSFER 10000 TO ACCOUNT 123456"
msg2 = b"TRANSFER 99999 TO ACCOUNT 654321"

c1 = chacha20_encrypt(key, nonce, msg1)
c2 = chacha20_encrypt(key, nonce, msg2)

# Attacker intercepts c1 and c2 — they XOR them:
xor_ciphers = bytes(a ^ b for a, b in zip(c1, c2))

# This equals P1 XOR P2 — attacker can use cribs to read both messages
xor_plaintexts = bytes(a ^ b for a, b in zip(msg1, msg2))

print("c1 ⊕ c2 == p1 ⊕ p2:", xor_ciphers == xor_plaintexts)
print("Attacker now has P1 ⊕ P2:", xor_ciphers.hex())
print("(With known-plaintext fragments, full recovery is possible)")
```

```{admonition} Golden Rule of Stream Ciphers
:class: danger
**Never reuse a (key, nonce) pair.** Generate a fresh random nonce for every message, or use a counter-based nonce scheme that guarantees uniqueness.
```

---

## 10. Summary: The Randomness–Security Spectrum

```{mermaid}
graph LR
    A["🎰 rand() / LCG<br/>Predictable<br/>NOT secure"]
    B["🔐 CSPRNG<br/>/dev/urandom<br/>Computationally secure"]
    C["🎲 TRNG<br/>Hardware entropy<br/>True random"]
    D["📋 One-Time Pad<br/>Perfect secrecy<br/>Impractical"]
    E["🌊 Stream Cipher<br/>ChaCha20, AES-CTR<br/>Practical & secure<br/>(if nonce unique)"]

    A -->|"add cryptographic hardening"| B
    B -->|"seed from"| C
    C -->|"key material for"| D
    B -->|"keystream for"| E

    style A fill:#e63946,color:#fff,stroke:#b5000e
    style B fill:#f4a261,color:#000,stroke:#d4721a
    style C fill:#2d6a4f,color:#fff,stroke:#1b4332
    style D fill:#1d3557,color:#fff,stroke:#0d1b2a
    style E fill:#457b9d,color:#fff,stroke:#1d3557
```

| Scheme | Keystream Source | Security Model | Practical? |
|--------|-----------------|----------------|------------|
| `rand()` / LCG | Deterministic, predictable | ❌ Broken | — |
| CSPRNG | Entropy-seeded, unpredictable | Computational | ✅ Yes |
| One-Time Pad | TRNG | **Information-theoretic (perfect)** | ❌ Not scalable |
| Stream Cipher | CSPRNG | Computational | ✅ Yes |

```{admonition} Key Takeaways
:class: tip
1. **`rand()` is not random** — it is a deterministic sequence predictable from one output.
2. **Entropy** is physical unpredictability; the OS harvests it for you via `/dev/urandom` / `os.urandom()`.
3. **OTP** is perfectly secure *because* its key is truly random and never reused — but this makes it impractical.
4. **Stream ciphers** replace the true-random keystream with a CSPRNG-generated one, trading perfect security for practicality.
5. **ChaCha20** is the modern standard: fast, constant-time, and proven secure. Use it via `cryptography` or `libsodium`.
6. **Nonce reuse** in stream ciphers is catastrophic — always use a fresh, unique nonce per message.
```

---

## Exercises

```{exercise} LCG Period
:label: ch07-ex-lcg-period
Write a Python function that computes the period of an LCG (the number of steps before the sequence repeats). Test it with $a=5$, $c=3$, $m=16$, starting from $X_0=0$. What does a short period imply for security?
```

````{solution} ch07-ex-lcg-period
:label: sol-ch07-ex-lcg-period
:class: dropdown

```python
def lcg_period(a, c, m, x0):
    seen = {}
    x = x0
    step = 0
    while x not in seen:
        seen[x] = step
        x = (a * x + c) % m
        step += 1
    return step - seen[x]

print(lcg_period(5, 3, 16, 0))  # → 16
```

With $a=5$, $c=3$, $m=16$, $X_0=0$ the sequence is $0, 3, 2, 13, 4, 7, 6, 1, 8, 11, 10, 5, 12, 15, 14, 9$ — period **16** (full period by Hull–Dobell theorem since $\gcd(3,16)=1$, $5-1=4$ divisible by 4, and $m$ is a power of 2 but not 4 — check manually).

**Security implication:** A short period means the keystream repeats after only a few bytes. An attacker who collects enough ciphertext can detect the repetition (e.g. via coincidence index) and recover the entire keystream by XOR, breaking the cipher with no key knowledge required.
````

```{exercise} Two-Time Pad
:label: ch07-ex-two-time-pad
Given two ciphertexts encrypted with the same OTP key:
- $C_1 = \mathtt{1a2b3c4d}$
- $C_2 = \mathtt{0f1e2d3c}$

Compute $C_1 \oplus C_2$. If you know that $P_1$ starts with `"Hello"` (ASCII), recover the first 5 bytes of $P_2$.
```

```{solution} ch07-ex-two-time-pad
:label: sol-ch07-ex-two-time-pad
:class: dropdown

**Step 1 — XOR the two ciphertexts:**

$$C_1 \oplus C_2 = \mathtt{1a2b3c4d} \oplus \mathtt{0f1e2d3c} = \mathtt{15353071}$$

Since $C_i = P_i \oplus K$, we have $C_1 \oplus C_2 = P_1 \oplus P_2$. The key cancels out entirely.

**Step 2 — Use known $P_1$ to recover $P_2$:**

$P_1 =$ `"Hello"` in ASCII = `48 65 6c 6c 6f` (5 bytes, only 4 bytes of ciphertext given — work with 4):

| Byte | $C_1$ | $C_2$ | $C_1 \oplus C_2 = P_1 \oplus P_2$ | $P_1$ (ASCII) | $P_2 = (P_1 \oplus P_2) \oplus P_1$ |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 0 | `1a` | `0f` | `15` | `48` (`H`) | `5d` = `]` |
| 1 | `2b` | `1e` | `35` | `65` (`e`) | `50` = `P` |
| 2 | `3c` | `2d` | `11` | `6c` (`l`) | `7d` = `}` |
| 3 | `4d` | `3c` | `71` | `6c` (`l`) | `1d` (control) |

**Conclusion:** The two-time pad immediately exposes $P_1 \oplus P_2$. Given any partial knowledge of one plaintext, the other is directly revealed — demonstrating why an OTP key must **never** be reused.
```

```{exercise} ChaCha20 Nonce Size
:label: ch07-ex-chacha20-nonce
ChaCha20 uses a 96-bit nonce. If nonces are chosen uniformly at random, how many messages can be encrypted before a collision has 50% probability (birthday bound)? Express your answer as a power of 2.
```

```{solution} ch07-ex-chacha20-nonce
:label: sol-ch07-ex-chacha20-nonce
:class: dropdown

The birthday bound for a uniform random value drawn from a space of size $N = 2^{96}$ is:

$$q \approx \sqrt{N} = \sqrt{2^{96}} = 2^{48}$$

After encrypting approximately $2^{48}$ messages with randomly-chosen nonces, the probability of a nonce collision reaches 50%.

**In practice:** $2^{48} \approx 2.8 \times 10^{14}$ messages. For an application sending 1 million messages per second, this threshold is reached in about **9 years** — comfortably safe for a single long-lived key. However, the standard recommendation is to **rotate the key** well before this limit (e.g. after $2^{32}$ messages or after a fixed time window), particularly when nonces are randomly generated rather than counters.

**Counter-based nonces:** Using a strictly-incrementing 96-bit counter eliminates the birthday risk entirely (no collisions until wrap-around at $2^{96}$), at the cost of requiring persistent state.
```
