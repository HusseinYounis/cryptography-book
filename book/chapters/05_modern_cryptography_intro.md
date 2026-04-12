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

# Chapter 5: Modern Cryptography — Overview

## Introduction

Classical ciphers (Chapter 3) relied on clever letter shuffling and manual operations. **Modern cryptography**, born in the second half of the 20th century, is built on a completely different foundation: **mathematical hardness problems**, **formal security definitions**, and **publicly scrutinised algorithms** whose security rests entirely in the key (recall {prf:ref}`crit-kerckhoffs`).

This chapter serves as the road map for the rest of the book. You will learn what the three families of modern cryptographic primitives are, why each one exists, how they relate to each other, and which chapters cover them in depth.

::::{grid} 1 2 2 3
:gutter: 3

:::{grid-item-card} 🔐 Symmetric Cryptography
Same key for encryption and decryption. Fast, efficient, ideal for bulk data. Chapters 6 – 8.
:::

:::{grid-item-card} 🗝️ Asymmetric Cryptography
Public key encrypts; private key decrypts. Solves key distribution. Chapters 9 – 11.
:::

:::{grid-item-card} #️⃣ Hash Functions
No key. One-way compression. Integrity, authentication, signatures. Chapter 12.
:::

::::

```{admonition} Why Three Families?
:class: important
No single primitive does everything:
- **Symmetric ciphers** are fast but require a shared secret — how do two strangers agree on one?
- **Asymmetric ciphers** solve key agreement but are ~1000× slower than symmetric ones.
- **Hash functions** provide integrity and enable digital signatures but cannot encrypt.

Real systems use **all three together** — asymmetric to exchange a symmetric key, symmetric for bulk encryption, and hashing for integrity and authentication.
```

---

## Warm-Up: Which Tool for the Job?

A journalist wants to:
(a) Send a 5 GB encrypted video to an editor securely over the internet,
(b) Prove to the editor that the file has not been tampered with, and
(c) Establish a shared encryption key without having met the editor before.

Which cryptographic primitive handles each task?

```{admonition} Solution
:class: dropdown
(a) **Symmetric encryption** (AES) — fast enough for gigabytes of data.

(b) **Hash function** (SHA-256) — compute a digest of the file; the editor recomputes and compares.

(c) **Asymmetric / Public-key cryptography** (Diffie-Hellman or RSA key exchange) — two strangers can establish a shared secret over a public channel.

This is exactly the architecture of **TLS** — the protocol securing every HTTPS connection.
```

---

## 1. From Classical to Modern

Classical ciphers fail the modern adversary for a simple reason: their security is based on *obscurity of the algorithm* rather than *hardness of a mathematical problem*.

```{prf:definition} Modern Cipher
:label: def-modern-cipher

A **modern cipher** is a cryptographic algorithm whose security is:

1. **Formally defined** — a precise mathematical statement of what an adversary can and cannot do
2. **Publicly known** — the algorithm is fully published; only the key is secret
3. **Computationally grounded** — breaking it requires solving a problem believed to be computationally hard (e.g. factoring large numbers, computing discrete logarithms)
4. **Proof-based** — security is argued by reduction: "if you can break the cipher, you can solve the hard problem"
```

```{admonition} The Shift in Thinking
:class: note
Classical cryptographers asked: *"Can my enemy figure out this clever trick?"*

Modern cryptographers ask: *"Can any polynomial-time algorithm distinguish my ciphertext from random noise — and if so, what hard mathematical problem must they solve first?"*

This shift from art to science happened in two landmark papers:
- Shannon (1949) — information-theoretic security, perfect secrecy
- Diffie & Hellman (1976) — public-key cryptography, computational security {cite}`diffie1976new`
```

---

## 2. Symmetric Cryptography

### 2.1 Definition and Core Idea

```{prf:definition} Symmetric-Key Encryption (SKE)
:label: def-ske

A **symmetric-key encryption scheme** is a triple of efficient algorithms $(\text{Gen}, \text{Enc}, \text{Dec})$:

- $\text{Gen}(1^n) \to k$ — generates a key $k$ from the security parameter $n$
- $\text{Enc}_k(m) \to c$ — encrypts message $m$ under key $k$
- $\text{Dec}_k(c) \to m$ — decrypts ciphertext $c$ under the **same** key $k$

**Correctness:** $\text{Dec}_k(\text{Enc}_k(m)) = m$ for all $m$ and all $k$ output by $\text{Gen}$.

The key $k$ is a **shared secret** — both communicating parties must possess it.
```

### 2.2 The Two Sub-Families

Symmetric ciphers split into two distinct constructions depending on how they process data:

::::{grid} 1 2 2 2
:gutter: 3

:::{grid-item-card} ⚡ Stream Ciphers
Encrypt **one bit or byte at a time** by XOR-ing with a pseudorandom keystream.

**Best for:** real-time communication, network streams, low-latency applications.

**Examples:** ChaCha20, Salsa20, RC4 (broken)

→ *Covered in Chapter 7*
:::

:::{grid-item-card} 📦 Block Ciphers
Encrypt data in **fixed-size blocks** (128 bits for AES) using rounds of substitution and permutation.

**Best for:** file encryption, database encryption, building MACs.

**Examples:** AES, DES (broken), 3DES (deprecated)

→ *Covered in Chapter 8*
:::

::::

### 2.3 Key Properties

| Property | Value |
|:---|:---|
| Key relationship | Encryption key = Decryption key |
| Speed | Very fast (AES-NI: ~1 GB/s on commodity hardware) |
| Key size | 128 – 256 bits (modern) |
| Main challenge | **Key distribution** — how do parties share the secret key over a public network? |
| Security model | IND-CPA, IND-CCA (see Chapter 4 for attack models) |

```{prf:example} Symmetric Encryption in Practice
:label: ex-ske-practice

**HTTPS connection (simplified):**

1. Browser and server use **asymmetric key exchange** (ECDH) to agree on a 256-bit session key — a number that never travels the network.
2. All subsequent HTTP traffic is encrypted with **AES-256-GCM** (symmetric) using that session key.
3. A **SHA-256 HMAC** authenticates each record so tampering is detected.

The symmetric cipher does 99.9% of the encryption work because it is orders of magnitude faster than asymmetric operations.
```

---

## 3. Asymmetric (Public-Key) Cryptography

### 3.1 The Key Distribution Problem

Symmetric encryption has one fundamental weakness: before two parties can communicate securely, they must already share a secret key. How do they agree on that key if they have never met and all their communication is observable?

This was an **open problem for 3,000 years**. It was solved in 1976 by Diffie and Hellman {cite}`diffie1976new`.

```{prf:definition} Public-Key Encryption (PKE)
:label: def-pke

A **public-key encryption scheme** is a triple $(\text{Gen}, \text{Enc}, \text{Dec})$:

- $\text{Gen}(1^n) \to (pk, sk)$ — generates a **public key** $pk$ and a **private key** $sk$
- $\text{Enc}_{pk}(m) \to c$ — encrypts with the **public** key (anyone can encrypt)
- $\text{Dec}_{sk}(c) \to m$ — decrypts with the **private** key (only the owner can decrypt)

**Correctness:** $\text{Dec}_{sk}(\text{Enc}_{pk}(m)) = m$ for all $(pk, sk)$ output by $\text{Gen}$.
```

### 3.2 Trapdoor One-Way Functions

Asymmetric cryptography relies on **trapdoor one-way functions** — functions that are:
- Easy to compute in one direction
- Hard to invert *without* special secret knowledge (the trapdoor)

```{prf:definition} One-Way Function (informal)
:label: def-owf

A function $f : \{0,1\}^* \to \{0,1\}^*$ is a **one-way function** if:
- $f(x)$ is computable in polynomial time
- For any probabilistic polynomial-time algorithm $\mathcal{A}$, the probability $\Pr[\mathcal{A}(f(x)) \in f^{-1}(f(x))]$ is negligible

A **trapdoor one-way function** additionally allows efficient inversion given a secret trapdoor $t$.
```

### 3.3 The Three Asymmetric Constructions

| Construction | Hard Problem | Key Operation | Chapter |
|:---|:---|:---|:---:|
| **RSA** | Integer factorisation: given $n = pq$, find $p, q$ | Modular exponentiation | 10 |
| **Diffie-Hellman / ElGamal** | Discrete logarithm: given $g^x \bmod p$, find $x$ | Modular exponentiation | 9 |
| **Elliptic Curve Cryptography** | ECDLP: discrete log on an elliptic curve group | Point multiplication | 11 |

```{admonition} Why Asymmetric Is Slow
:class: note
Asymmetric operations involve exponentiation with numbers that are 2048–4096 bits long. AES operates on 128-bit blocks with simple XOR and byte-substitution steps. The speed difference is roughly **1000×** — which is why we use asymmetric crypto only to establish a shared key, then hand off to symmetric encryption.
```

---

## 4. Hash Functions

### 4.1 Definition

```{prf:definition} Cryptographic Hash Function
:label: def-hash

A **cryptographic hash function** is an efficient algorithm:

$$H : \{0,1\}^* \to \{0,1\}^n$$

that maps an input of **arbitrary length** to a fixed-length **digest** of $n$ bits, satisfying three security properties:

1. **Pre-image resistance:** Given $h$, it is computationally infeasible to find any $x$ such that $H(x) = h$
2. **Second pre-image resistance:** Given $x$, it is computationally infeasible to find $x' \neq x$ with $H(x') = H(x)$
3. **Collision resistance:** It is computationally infeasible to find *any* pair $(x, x')$ with $x \neq x'$ and $H(x) = H(x')$
```

```{admonition} Hash Functions Are Not Encryption
:class: warning
Hash functions have **no key** and are **not reversible**. They do not provide confidentiality. Their purpose is **integrity** — any change to the input, however small, produces a completely different digest (the avalanche effect).
```

### 4.2 Applications of Hash Functions

| Application | How hashing is used | Chapter |
|:---|:---|:---:|
| **File integrity** | Hash the file; compare digests | 12 |
| **Password storage** | Store $H(\text{salt} \| \text{password})$, never plaintext | 12 |
| **Digital signatures** | Sign $H(m)$ instead of $m$ (much shorter) | 13 |
| **HMAC (authentication)** | $H(k \| m)$ proves message integrity + origin | 12 |
| **Key derivation (KDF)** | Derive encryption keys from passwords or shared secrets | 14 |
| **Merkle trees** | Efficient integrity of large datasets (blockchain, Git) | 12 |

### 4.3 SHA Family at a Glance

| Algorithm | Digest size | Status |
|:---:|:---:|:---:|
| MD5 | 128 bits | **Broken** — collisions found |
| SHA-1 | 160 bits | **Broken** — collisions found (2017) |
| **SHA-256** | 256 bits | **Secure** — current standard |
| **SHA-3 (Keccak)** | 224 – 512 bits | **Secure** — alternative standard |

---

## 5. How the Three Families Work Together

Modern secure systems always combine all three primitives. The diagram below shows a typical **hybrid encryption** flow — the model used by TLS, PGP, Signal, and every major protocol.

```{mermaid}
graph TD
    A["Alice wants to<br/>send M to Bob"] --> B["1. Fetch Bob's public key pk_Bob"]
    B --> C["2. Generate random<br/>symmetric key K"]
    C --> D["3. Encrypt K with pk_Bob<br/>(asymmetric — RSA / ECDH)"]
    C --> E["4. Encrypt M with K<br/>(symmetric — AES-256-GCM)"]
    D --> F["Send: Enc_pk(K) ∥ Enc_K(M) ∥ HMAC"]
    E --> F
    C --> G["5. Compute HMAC_K(M)<br/>(hash-based authentication)"]
    G --> F
    F --> H["Bob decrypts K with sk_Bob,<br/>then decrypts M, then verifies HMAC"]
```

```{prf:algorithm} Hybrid Encryption
:label: algo-hybrid-ch05

**Input:** Message $M$, recipient's public key $pk$

**Output:** Ciphertext that only the recipient can decrypt

1. Generate a fresh random symmetric key $K \xleftarrow{R} \{0,1\}^{256}$
2. $c_{\text{key}} \leftarrow \text{Enc}_{pk}(K)$ — asymmetric encryption of the session key
3. $c_{\text{msg}} \leftarrow \text{AES-GCM}_K(M)$ — symmetric encryption of the message
4. $\tau \leftarrow \text{HMAC-SHA256}_K(M)$ — authentication tag
5. Transmit $(c_{\text{key}},\ c_{\text{msg}},\ \tau)$

**Decryption (recipient):**

1. $K \leftarrow \text{Dec}_{sk}(c_{\text{key}})$
2. Verify $\tau = \text{HMAC-SHA256}_K(\text{Dec}_K(c_{\text{msg}}))$
3. $M \leftarrow \text{AES-GCM-Dec}_K(c_{\text{msg}})$
```

---

## 6. Chapter Road Map

The following table maps every remaining chapter to the primitive it covers and the core concept introduced:

| Chapter | Primitive | Core Topic |
|:---:|:---|:---|
| **6** | Symmetric | Formal definitions of SKE, security goals (IND-CPA), key distribution problem |
| **7** | Symmetric → Stream | Randomness, PRNGs, OTP, stream ciphers (ChaCha20) |
| **8** | Symmetric → Block | Feistel networks, DES, AES, modes of operation |
| **9** | Asymmetric | Public-key framework, trapdoor functions, Diffie-Hellman key exchange |
| **10** | Asymmetric → RSA | RSA encryption and signatures, security reductions |
| **11** | Asymmetric → ECC | Elliptic curve groups, ECDH, ECDSA |
| **12** | Hash | SHA family, collision resistance, HMAC, applications |
| **13** | Applied | Digital signatures (RSA-PSS, DSA, ECDSA) |
| **14** | Applied | Key exchange protocols, TLS handshake |
| **15** | Practical | Python implementations, interactive demos |

---

## 7. Security Comparison

```{prf:criterion} Choosing the Right Primitive
:label: crit-primitive-choice

| Requirement | Use |
|:---|:---|
| Encrypt large data fast | **Symmetric** (AES-256-GCM) |
| Exchange a key with a stranger | **Asymmetric** (ECDH or RSA-OAEP) |
| Verify file integrity | **Hash** (SHA-256) |
| Authenticate a message | **HMAC** (hash + symmetric key) |
| Sign a document | **Asymmetric** signature (ECDSA, RSA-PSS) |
| Store passwords safely | **Hash** with salt (Argon2, bcrypt) |
```

::::{question} Modern Cryptography Taxonomy
:type: multiple-choice
:variant: single-select
:showanswer:

HTTPS uses AES-256 to encrypt web traffic after the initial handshake. Which category does AES-256 belong to?
---
[x] Symmetric encryption
> Correct! AES uses the same key for encryption and decryption — the defining property of symmetric cryptography. It is a block cipher that encrypts 128-bit blocks.
[ ] Asymmetric encryption
> Asymmetric encryption uses a key pair (public + private). AES uses a single shared key.
[ ] Hash function
> Hash functions are keyless and one-way. AES is reversible with the key.
[ ] Digital signature
> Digital signatures use asymmetric key pairs to prove authorship. AES provides confidentiality.
---
::::

::::{question} Role of Each Primitive
:type: multiple-choice
:variant: multiple-select
:showanswer:

Which of the following tasks require a **hash function**? (Select all that apply.)
---
[x] Detecting whether a downloaded file has been tampered with
> Correct! Hashing the file and comparing digests is the standard integrity check (e.g. SHA-256 checksum).
[ ] Encrypting a 4 GB video file
> Encryption requires a cipher (symmetric). Hash functions cannot encrypt — they are one-way.
[x] Storing user passwords in a database
> Correct! Passwords are stored as salted hashes (Argon2, bcrypt) — never in plaintext.
[x] Creating a digital signature over a large document
> Correct! The signer hashes the document first (SHA-256), then signs the short digest — not the entire document.
[ ] Establishing a shared secret key between two computers
> Key establishment uses asymmetric cryptography (ECDH or RSA). Hashing alone cannot do this.
---
::::

---

## 8. Summary

| Primitive | Key | Direction | Speed | Primary Use |
|:---|:---:|:---:|:---:|:---|
| **Symmetric cipher** | Single shared key | Reversible | ⚡⚡⚡ Fast | Bulk encryption |
| **Stream cipher** | Shared key + nonce | Reversible | ⚡⚡⚡ Very fast | Real-time streams |
| **Block cipher** | Shared key | Reversible | ⚡⚡ Fast | File/disk encryption |
| **Asymmetric cipher** | Public/private pair | Reversible | ⚡ Slow | Key exchange, signatures |
| **Hash function** | None | **One-way** | ⚡⚡⚡ Fast | Integrity, passwords |

```{admonition} Key Insight
:class: tip
The **key distribution problem** is the central challenge that asymmetric cryptography solves. Without it, two parties who have never met cannot establish a shared secret — and therefore cannot use symmetric encryption — over a public network. Chapters 9–11 show exactly how this miracle is achieved using mathematical trapdoor functions.
```

---

```{bibliography}
:filter: docname in docnames
```
