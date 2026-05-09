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

# Chapter 6: Symmetric Encryption — Foundations

```{figure} ../figures/ch01/symmetric_encryption.png
:align: center
:width: 65%
:alt: Symmetric encryption — same key used for encryption and decryption
```

## Introduction

Symmetric encryption is the workhorse of modern cryptography. Every HTTPS session, every encrypted file on disk, every secure messaging app uses a symmetric cipher to protect the actual data. This chapter builds the formal foundations — precise definitions, security goals, and the key distribution challenge — before the next two chapters dive into the two concrete families: **stream ciphers** (Chapter 7) and **block ciphers** (Chapter 8).

::::{grid} 1 2 2 3
:gutter: 3

:::{grid-item-card} 📐 Formal Definitions
The SKE framework: Gen, Enc, Dec. Correctness and security stated precisely.
:::

:::{grid-item-card} 🎯 Security Goals
IND-EAV, IND-CPA, IND-CCA — a ladder of increasingly strong guarantees.
:::

:::{grid-item-card} 🔑 Key Distribution
The fundamental challenge of symmetric cryptography — and why public-key crypto was invented to solve it.
:::

::::

```{admonition} What You Will Learn
:class: tip
By the end of this chapter you will be able to:
- State the formal definition of a symmetric-key encryption scheme
- Explain the correctness requirement
- Distinguish the three main security notions (EAV, CPA, CCA) and know which applies when
- Describe the key distribution problem and why it matters
- Compare stream ciphers and block ciphers at a high level
```

---

## Warm-Up: Is This Scheme Secure?

Alice and Bob share the key $k = 42$. To encrypt a number $m \in \{1, \ldots, 100\}$, Alice computes $c = m + k \pmod{100}$ and sends $c$. Eve intercepts many messages over time and notices that the ciphertext 73 appears far more often than others.

What has Eve learned, and what does this tell us about the scheme?

```{admonition} Solution
:class: dropdown
Eve has learned that the corresponding plaintext is also frequent — the distribution of ciphertext values mirrors the distribution of plaintext values. This violates **semantic security**: observing the ciphertext leaks partial information about the plaintext.

A secure cipher must make the ciphertext distribution **independent** of the plaintext distribution. Eve's observation is only possible because:
1. The key is reused for every message
2. The scheme is deterministic (same $m$ → same $c$ every time)

Both of these flaws are addressed by the formal definitions in this chapter.
```

---

## 1. The Symmetric-Key Encryption Framework

### 1.1 Syntax

```{prf:definition} Symmetric-Key Encryption Scheme
:label: def-ske-formal

A **symmetric-key encryption scheme** over message space $\mathcal{M}$, key space $\mathcal{K}$, and ciphertext space $\mathcal{C}$ is a triple of efficient algorithms $\Pi = (\text{Gen}, \text{Enc}, \text{Dec})$:

$$\text{Gen}(1^n) \to k \in \mathcal{K}$$

$$\text{Enc}_k : \mathcal{M} \to \mathcal{C}$$

$$\text{Dec}_k : \mathcal{C} \to \mathcal{M}$$

The **security parameter** $n$ controls key length: larger $n$ means higher security (and slower performance).
```

```{prf:definition} Correctness
:label: def-ske-correctness

A scheme $(\text{Gen}, \text{Enc}, \text{Dec})$ is **correct** if for every key $k$ output by $\text{Gen}$ and every message $m \in \mathcal{M}$:

$$\text{Dec}_k\!\left(\text{Enc}_k(m)\right) = m$$

Decryption always recovers the original plaintext.
```

```{admonition} Notation: Randomised Encryption
:class: note
$\text{Enc}$ may be **randomised** — the same key and plaintext can produce different ciphertexts on different calls (using a fresh random nonce each time). Correctness still holds because $\text{Dec}$ recovers $m$ regardless of which random coins $\text{Enc}$ used.

This randomness is *essential* for semantic security: a deterministic cipher with a fixed key always maps the same plaintext to the same ciphertext, leaking equality information.
```

```{prf:example} One-Time Pad as an SKE Scheme
:label: ex-otp-ske

The **one-time pad** over $\{0,1\}^n$ is the simplest symmetric-key encryption scheme:

- $\text{Gen}(1^n)$: choose $k \xleftarrow{R} \{0,1\}^n$ uniformly at random
- $\text{Enc}_k(m) = m \oplus k$
- $\text{Dec}_k(c) = c \oplus k$

**Correctness check:**

$$\text{Dec}_k(\text{Enc}_k(m)) = (m \oplus k) \oplus k = m \oplus (k \oplus k) = m \oplus 0^n = m \checkmark$$

**Key space:** $\mathcal{K} = \{0,1\}^n$ — the key is as long as the message.

**Security:** The OTP achieves *perfect secrecy* ({prf:ref}`def-perfect-secrecy` in Chapter 4) — but requires a fresh key for every message. This makes it impractical for most applications, motivating the computational security notions in §2.
```

::::{question} SKE Correctness
:type: multiple-choice
:variant: single-select
:showanswer:

A scheme defines $\text{Enc}_k(m) = m \oplus k$ and $\text{Dec}_k(c) = c \oplus k$. Is it correct?
---
[x] Yes — $\text{Dec}_k(\text{Enc}_k(m)) = (m \oplus k) \oplus k = m$
> Correct! XOR is its own inverse: $(m \oplus k) \oplus k = m \oplus (k \oplus k) = m \oplus 0 = m$.
[ ] No — XOR does not cancel itself.
> XOR is self-inverse: $x \oplus x = 0$ for any $x$, so $(m \oplus k) \oplus k = m$.
[ ] Only if $n = 128$ bits.
> Correctness is independent of key length — it follows only from the algebraic properties of XOR.
[ ] Only when $m \neq k$.
> There is no restriction on $m$ and $k$ — the identity holds for all bit strings of equal length.
---
::::

### 1.2 The Shared-Key Model

```{mermaid}
sequenceDiagram
    participant Alice
    participant Eve
    participant Bob
    Alice->>Bob: (secure channel, one time) Share key k
    Alice->>Eve: Intercepts: c = Enc_k(m)
    Alice->>Bob: c = Enc_k(m)
    Bob->>Bob: m = Dec_k(c)
    Note over Eve: Sees c but not k — cannot recover m
```

The model assumes:
- The **key was exchanged securely** (how? — see §4 and Chapters 9–11)
- The **algorithm is public** (Kerckhoffs's principle, {prf:ref}`crit-kerckhoffs`)
- The **key is the only secret**

---

## 2. Security Definitions

Informally, a cipher is "secure" if an attacker cannot learn anything about the plaintext from the ciphertext. Formally, we define security by specifying an **adversarial game**: if no efficient adversary can win (better than guessing), the scheme is secure.

### 2.1 Eavesdropper Security (IND-EAV)

The weakest meaningful notion — security against a **passive eavesdropper** who only observes ciphertexts (ciphertext-only attack, COA from Chapter 4).

```{prf:definition} IND-EAV Security
:label: def-ind-eav

A scheme $\Pi$ is **IND-EAV secure** (indistinguishable under eavesdropping) if for every probabilistic polynomial-time adversary $\mathcal{A}$:

$$\Pr\!\left[\mathcal{A}(1^n,\, c^*) = b \;\middle|\; c^* = \text{Enc}_k(m_b),\; b \xleftarrow{R}\{0,1\}\right] \leq \frac{1}{2} + \varepsilon(n)$$

for a negligible $\varepsilon$, where $\mathcal{A}$ chooses $m_0, m_1$ and must guess which was encrypted.
```

### 2.2 Chosen-Plaintext Security (IND-CPA)

The standard notion for symmetric ciphers in practice. The adversary can **encrypt any messages of her choice** (e.g. by tricking a server into encrypting data she uploads).

```{prf:definition} IND-CPA Security
:label: def-ind-cpa

A scheme $\Pi$ is **IND-CPA secure** if $\mathcal{A}$ wins the following game with probability $\leq \frac{1}{2} + \varepsilon(n)$:

1. $k \leftarrow \text{Gen}(1^n)$
2. $\mathcal{A}$ is given oracle access: $\mathcal{O}_{\text{Enc}}(m) = \text{Enc}_k(m)$ for any $m$ of her choice
3. $\mathcal{A}$ outputs two equal-length messages $m_0, m_1$
4. Challenger picks $b \xleftarrow{R} \{0,1\}$, returns $c^* = \text{Enc}_k(m_b)$
5. $\mathcal{A}$ continues to query $\mathcal{O}_{\text{Enc}}$ (but not on $m_0$ or $m_1$)
6. $\mathcal{A}$ outputs a guess $b'$; she wins if $b' = b$
```

```{prf:algorithm} IND-CPA Security Experiment
:label: algo-ind-cpa-game

The **IND-CPA experiment** $\text{Exp}_{\Pi,\mathcal{A}}^{\text{CPA}}(n)$ formalises what it means for an adversary to attack a symmetric cipher under chosen-plaintext access.

**Input:** Security parameter $1^n$, scheme $\Pi = (\text{Gen}, \text{Enc}, \text{Dec})$, adversary $\mathcal{A}$

**Output:** $1$ if $\mathcal{A}$ wins (correctly guesses $b$), $0$ otherwise

1. Sample $k \leftarrow \text{Gen}(1^n)$; sample challenge bit $b \xleftarrow{R} \{0,1\}$
2. Run $\mathcal{A}^{\mathcal{O}_{\text{Enc}}(\cdot)}(1^n)$: give $\mathcal{A}$ oracle access to $\mathcal{O}_{\text{Enc}}(m) = \text{Enc}_k(m)$
3. $\mathcal{A}$ outputs two equal-length messages $(m_0, m_1)$
4. Compute challenge ciphertext: $c^* \leftarrow \text{Enc}_k(m_b)$; send $c^*$ to $\mathcal{A}$
5. Continue giving $\mathcal{A}$ oracle access to $\mathcal{O}_{\text{Enc}}$ (queries on $m_0, m_1$ are allowed post-challenge)
6. $\mathcal{A}$ outputs guess $b'$; return $1$ if $b' = b$, else return $0$

**Advantage:**

$$\text{Adv}_{\Pi,\mathcal{A}}^{\text{CPA}}(n) = \left|\Pr\!\left[\text{Exp}_{\Pi,\mathcal{A}}^{\text{CPA}}(n) = 1\right] - \frac{1}{2}\right|$$

$\Pi$ is IND-CPA secure iff $\text{Adv}_{\Pi,\mathcal{A}}^{\text{CPA}}(n) \leq \varepsilon(n)$ for all PPT $\mathcal{A}$ and a negligible $\varepsilon$.
```

```{prf:theorem} Deterministic Encryption Cannot Be IND-CPA
:label: thm-det-not-cpa

No **deterministic** symmetric-key encryption scheme can be IND-CPA secure.

**Proof sketch:** Let $\Pi$ be deterministic. The adversary $\mathcal{A}$ proceeds as follows:

1. Choose any two distinct messages $m_0, m_1$.
2. Query the encryption oracle: $c_0 \leftarrow \text{Enc}_k(m_0)$.
3. Receive challenge ciphertext $c^*$.
4. If $c^* = c_0$ output $b' = 0$; otherwise output $b' = 1$.

Because $\Pi$ is deterministic, $\text{Enc}_k(m_0)$ always produces the same $c_0$. Therefore $\mathcal{A}$ wins with probability **1**, not $\frac{1}{2}$. $\square$
```

```{admonition} Why This Matters in Cryptography
:class: important
This theorem shows that **nonces and IVs are not optional**. Any mode of operation used in practice (CBC, CTR, GCM) must inject fresh randomness into each encryption call. Forgetting to randomise — or reusing a nonce — is one of the most common implementation mistakes in cryptographic systems.
```

```{prf:criterion} Nonce Uniqueness Requirement
:label: crit-nonce-uniqueness

For any randomised symmetric cipher (AES-CBC, AES-CTR, AES-GCM, ChaCha20-Poly1305): **a (key, nonce) pair must never be reused across different messages**.

- Nonce reuse under AES-CTR or ChaCha20 allows an attacker to XOR two ciphertexts and cancel the keystream, recovering the XOR of the two plaintexts.
- Nonce reuse under AES-GCM additionally destroys the authentication guarantee and can expose the authentication key.

**Recommended practice:** generate each nonce as a fresh random value (96 bits for GCM) or a strictly-incrementing counter that is never reset for a given key.
```

::::{question} Security Notion Hierarchy
:type: multiple-choice
:variant: single-select
:showanswer:

A cipher is proven IND-CPA secure. Which other security notions does this guarantee?
---
[x] IND-EAV security
> Correct! IND-CPA is strictly stronger than IND-EAV. Since IND-EAV only gives the adversary a single challenge ciphertext (no encryption oracle), any adversary that wins IND-EAV could be used against IND-CPA — so IND-CPA security implies IND-EAV security.
[ ] IND-CCA security
> IND-CCA is strictly stronger than IND-CPA. An IND-CPA secure cipher may still be malleable and lose to a chosen-ciphertext adversary (e.g., AES-CTR without authentication).
[ ] Perfect secrecy
> Perfect secrecy is an information-theoretic notion that requires $|\mathcal{K}| \geq |\mathcal{M}|$. IND-CPA is a computational notion and does not imply it.
[ ] Neither IND-EAV nor IND-CCA
> The hierarchy is IND-EAV ⊂ IND-CPA ⊂ IND-CCA — IND-CPA is strictly stronger than IND-EAV.
---
::::

### 2.3 Chosen-Ciphertext Security (IND-CCA)

The strongest standard notion — the adversary can also **submit ciphertexts for decryption** (except the challenge itself). Required for authenticated encryption.

```{prf:definition} IND-CCA Security
:label: def-ind-cca

A scheme $\Pi$ is **IND-CCA secure** if $\mathcal{A}$ wins the analogous game with probability $\leq \frac{1}{2} + \varepsilon(n)$, where $\mathcal{A}$ additionally has access to a decryption oracle $\mathcal{O}_{\text{Dec}}(c) = \text{Dec}_k(c)$ for any $c \neq c^*$.
```

```{admonition} The Security Ladder
:class: tip

$$\text{IND-EAV} \;\subset\; \text{IND-CPA} \;\subset\; \text{IND-CCA}$$

**AES-CTR** (no authentication): IND-CPA secure, but **not** IND-CCA (malleable — flipping a bit in the ciphertext flips the corresponding plaintext bit).

**AES-GCM** (authenticated encryption): IND-CCA secure — the authentication tag detects any ciphertext modification.
```

### 2.4 Authenticated Encryption (AE)

Modern best practice is to use a scheme that provides **both confidentiality and integrity** simultaneously.

```{prf:definition} Authenticated Encryption with Associated Data (AEAD)
:label: def-aead

An **AEAD scheme** $(\text{Gen}, \text{Enc}, \text{Dec})$ takes an additional **associated data** input $a$ (e.g. packet headers):

$$\text{Enc}_k(m, a) \to (c, \tau)$$

$$\text{Dec}_k(c, \tau, a) \to m \text{ or } \bot$$

$\text{Dec}$ returns $\bot$ (reject) if the tag $\tau$ does not verify — detecting any tampering with $c$ or $a$.

Standard AEAD ciphers: **AES-GCM**, **ChaCha20-Poly1305**.
```

```{prf:example} AEAD in Action — Tamper Detection (Binary Walk-Through)
:label: ex-aead-tamper

We use **4-bit values** throughout to keep every step fully visible. Real AEAD (e.g. AES-GCM) works identically at 128 bits.

**Setup:**

| Symbol | Value | Meaning |
|:---|:---:|:---|
| $m$ | $\mathtt{1011}$ | plaintext — Alice's message ("pay \$3") |
| $a$ | $\mathtt{0101}$ | associated data — header ("session-id: 5"), sent in the clear |
| $k_{\text{enc}}$ | $\mathtt{1100}$ | encryption key (shared secret) |
| $k_{\text{tag}}$ | $\mathtt{0110}$ | authentication key (shared secret) |

**Step 1 — Alice encrypts and tags:**

Encryption is XOR with the key (like a one-time pad):

$$c \;=\; m \oplus k_{\text{enc}} \;=\; \mathtt{1011} \oplus \mathtt{1100} \;=\; \mathtt{0111}$$

The **authentication tag** is a keyed checksum computed over both the ciphertext and the associated data:

$$\tau \;=\; (c \oplus a) \oplus k_{\text{tag}} \;=\; (\mathtt{0111} \oplus \mathtt{0101}) \oplus \mathtt{0110} \;=\; \mathtt{0010} \oplus \mathtt{0110} \;=\; \mathtt{0100}$$

Alice sends the triple $(c,\, \tau,\, a) = (\mathtt{0111},\, \mathtt{0100},\, \mathtt{0101})$.

**Step 2 — Eve intercepts and flips one bit:**

Eve wants to change the payment amount. She flips the first bit of $c$:

$$c' \;=\; \mathtt{1111}$$

Eve hopes this decrypts to a larger value. She has no key, so she re-uses Alice's original tag:

$$(c',\, \tau,\, a) \;=\; (\mathtt{1111},\, \mathtt{0100},\, \mathtt{0101}) \quad \leftarrow \text{Eve's forged packet}$$

**Step 3 — Server verifies the tag:**

The server recomputes the expected tag from the received ciphertext:

$$\tau' \;=\; (c' \oplus a) \oplus k_{\text{tag}} \;=\; (\mathtt{1111} \oplus \mathtt{0101}) \oplus \mathtt{0110} \;=\; \mathtt{1010} \oplus \mathtt{0110} \;=\; \mathtt{1100}$$

Comparison:

$$\tau' = \mathtt{1100} \;\neq\; \tau = \mathtt{0100} \;\implies\; \text{Dec}_k(c', \tau, a) = \bot \quad \text{(REJECT)}$$

The server **discards the packet** — the modified ciphertext is never decrypted.

**Why Eve cannot forge the tag:** without $k_{\text{tag}}$ she would have to guess $\tau'$ correctly. With a 4-bit tag the chance is $\tfrac{1}{16}$; with a real 128-bit tag it drops to $\tfrac{1}{2^{128}} \approx 10^{-38}$.

**Key takeaway:** the tag binds $\tau$ to every bit of both $c$ and $a$. Changing either one — even by a single bit — produces a different tag, and $\text{Dec}$ outputs $\bot$ instead of a forged plaintext.
```

---

```{admonition} Two Families: Stream Ciphers and Block Ciphers
:class: note
Symmetric ciphers split into two families based on how they process data:

- **Stream ciphers** (Chapter 7) — encrypt bit-by-bit or byte-by-byte using a pseudorandom keystream; ideal for real-time, low-latency data (e.g., ChaCha20 in TLS).
- **Block ciphers** (Chapter 8) — encrypt fixed-size blocks (128 bits for AES) using a keyed permutation; used for bulk storage encryption and as building blocks for MACs.
```

## 4. The Key Distribution Problem

Symmetric encryption requires both parties to share a secret key **before** they can communicate. This creates a fundamental bootstrapping problem.

```{prf:definition} Key Distribution Problem
:label: def-key-distribution

The **key distribution problem** is: given two parties $A$ and $B$ who share **no prior secret** and communicate only over a **public, adversarially monitored channel**, how can they establish a shared symmetric key $k$ that remains secret from an eavesdropper?
```

```{admonition} The Pre-Internet Approach
:class: note
Before public-key cryptography (1976), the only solutions were logistical:
- **Physical key exchange** — courier delivers a key book (NATO, diplomatic cables)
- **Key Distribution Centre (KDC)** — a trusted third party pre-distributes pairwise keys (Kerberos still uses this model for enterprise networks)

Both require trusting infrastructure that can be compromised — courier captured, KDC breached.
```

```{admonition} The Modern Solution
:class: important
Diffie and Hellman (1976) showed that **mathematical trapdoor functions** can solve key distribution without any prior shared secret. Two parties exchange public values over an open channel and each independently computes the same shared secret — an eavesdropper who sees all the exchanges cannot efficiently compute it.

This is **asymmetric / public-key cryptography** — covered in Chapters 9–11.
```

::::{question} Key Distribution
:type: multiple-choice
:variant: single-select
:showanswer:

Alice and Bob have never met. They want to use AES-256 to encrypt their email. What is the main problem they face?
---
[ ] AES-256 is too slow for email encryption.
> AES-256 is very fast — speed is not the issue.
[x] They need to share a secret 256-bit key, but have no secure channel to exchange it.
> Correct! This is the key distribution problem. Without a prior shared secret, they cannot use symmetric encryption directly — they need public-key cryptography first.
[ ] AES-256 is not secure enough for email.
> AES-256 is considered secure against all known attacks including quantum computers.
[ ] Email servers cannot forward encrypted messages.
> Email servers transparently forward arbitrary data; this is not the issue.
---
::::

---

## 5. Pseudorandom Functions and Permutations

Block ciphers are modelled as **pseudorandom permutations (PRPs)**. Stream ciphers and MACs are modelled as **pseudorandom functions (PRFs)**. These abstractions allow security proofs.

```{prf:definition} Pseudorandom Function (PRF)
:label: def-prf

A keyed function $F : \mathcal{K} \times \{0,1\}^n \to \{0,1\}^n$ is a **pseudorandom function** if no efficient adversary can distinguish oracle access to $F_k(\cdot)$ (for a random $k$) from oracle access to a truly random function $f : \{0,1\}^n \to \{0,1\}^n$.
```

```{prf:definition} Pseudorandom Permutation (PRP)
:label: def-prp

A keyed function $E : \mathcal{K} \times \{0,1\}^n \to \{0,1\}^n$ is a **pseudorandom permutation** if it is a PRF and additionally $E_k(\cdot)$ is a **bijection** (permutation) for every key $k$, with an efficiently computable inverse $E_k^{-1}$.

A **strong PRP (SPRP)** remains indistinguishable even when the adversary can also query the inverse $E_k^{-1}(\cdot)$.
```

```{admonition} Why This Matters in Cryptography
:class: important
The PRP assumption is the formal statement of what it means for AES to be "secure". Under this assumption, we can prove that AES-CTR mode is IND-CPA secure and AES-GCM is IND-CCA secure. Without this abstraction, every proof would require reasoning about AES's internals directly — which is intractable.
```

::::{question} PRF vs PRP
:type: multiple-choice
:variant: multiple-select
:showanswer:

Which of the following statements about PRFs and PRPs are correct? (Select all that apply.)
---
[x] Every PRP is also a PRF.
> Correct! A PRP is a PRF that is additionally a bijection. The indistinguishability requirement for PRFs is implied by the PRP definition.
[ ] Every PRF is also a PRP.
> False — a PRF need not be a bijection. Many PRFs map inputs to outputs with collisions possible.
[x] AES is modelled as a PRP, not merely a PRF.
> Correct! AES is a keyed permutation on 128-bit blocks — every key produces a bijection — so the PRP model is the appropriate abstraction.
[x] A Strong PRP (SPRP) remains secure even when the adversary can also query the inverse permutation.
> Correct! SPRP extends PRP security to include inverse queries, which is the assumption needed to prove IND-CCA security of modes like AES-GCM.
[ ] A PRF can be used to encrypt directly without a mode of operation.
> A PRF is a building block, not itself an encryption scheme. It must be used within a mode (CTR, GCM) that handles message length, nonces, and authentication.
---
::::

---

## 6. Summary

| Concept | Definition | Cryptographic Role |
|:---|:---|:---|
| **SKE scheme** | $(\text{Gen}, \text{Enc}, \text{Dec})$ with correctness | Framework for symmetric encryption |
| **IND-EAV** | Eavesdropper cannot distinguish encryptions | Minimum passive security |
| **IND-CPA** | Attacker with encryption oracle cannot distinguish | Standard security for symmetric ciphers |
| **IND-CCA** | Attacker with enc + dec oracle cannot distinguish | Required for authenticated encryption |
| **AEAD** | Confidentiality + integrity in one primitive | AES-GCM, ChaCha20-Poly1305 |
| **Stream cipher** | Keystream XOR'd with plaintext, bit by bit | Real-time, low-latency encryption (Ch 7) |
| **Block cipher** | Keyed permutation on fixed blocks | Bulk encryption, MACs (Ch 8) |
| **PRF / PRP** | Computational models for ciphers | Enable formal security proofs |
| **Key distribution** | Sharing a key over a public channel | Solved by public-key crypto (Ch 9–11) |

---

## Exercises

```{exercise} Correctness Check
:label: ch06-ex-correctness

A proposed scheme defines:
- $\text{Gen}$: pick random $k \in \{0,1\}^{128}$
- $\text{Enc}_k(m) = m \oplus k$
- $\text{Dec}_k(c) = c \oplus k \oplus 1$ (XOR with $k$ and then flip all bits)

1. Is this scheme correct? Justify with algebra.
2. If not, propose the minimal fix.
```

```{solution} ch06-ex-correctness
:label: sol-ch06-ex-correctness
:class: dropdown

**1. Correctness check:**

$\text{Dec}_k(\text{Enc}_k(m)) = (m \oplus k) \oplus k \oplus 1 = m \oplus 1$

This is **not** correct — the decrypted value is $m$ with all bits flipped, not $m$ itself.

**2. Fix:**

Change $\text{Dec}_k(c) = c \oplus k$ (remove the XOR with 1). Then:

$\text{Dec}_k(\text{Enc}_k(m)) = (m \oplus k) \oplus k = m \oplus (k \oplus k) = m \oplus 0 = m$ ✓

The corrected scheme is the **one-time pad** (OTP).
```

```{exercise} Security Notion Matching
:label: ch06-ex-security-notion

For each scenario, identify the most appropriate security notion (IND-EAV, IND-CPA, or IND-CCA):

1. A cipher encrypts log files that are never sent over the network — an attacker can only read the ciphertext on disk.
2. A web server encrypts user-uploaded profile pictures with a fixed key — an attacker can upload arbitrary images and observe the encrypted outputs.
3. A TLS session uses a cipher to protect bidirectional traffic — an attacker can inject malformed ciphertext packets and observe whether the server rejects them.
```

```{solution} ch06-ex-security-notion
:label: sol-ch06-ex-security-notion
:class: dropdown

1. **IND-EAV** — the attacker is purely passive (ciphertext-only). They cannot cause anything to be encrypted or decrypted.

2. **IND-CPA** — the attacker controls what gets encrypted (chosen-plaintext) by choosing which images to upload. The encryption oracle is the server.

3. **IND-CCA** — the attacker can submit crafted ciphertexts and observe decryption outcomes (accept/reject), constituting a chosen-ciphertext attack. TLS must be IND-CCA secure; this is why AES-GCM (AEAD) replaced unauthenticated AES-CBC in TLS 1.3.
```

---

```{bibliography}
:filter: docname in docnames
```
