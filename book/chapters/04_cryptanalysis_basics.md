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

# Chapter 4: Cryptanalysis Basics

## Introduction

Cryptanalysis is the science of breaking cryptographic systems — recovering plaintext from ciphertext without possessing the secret key. Understanding how ciphers are broken is just as important as understanding how they are built: every cipher designer must think like an attacker.

::::{grid} 1 2 2 3
:gutter: 3

:::{grid-item-card} 🎯 Attack Models
Learn what an attacker can observe — ciphertext-only, known-plaintext, chosen-plaintext, and chosen-ciphertext scenarios.
:::

:::{grid-item-card} 📊 Frequency Analysis
Exploit statistical patterns in natural language to break monoalphabetic substitution ciphers.
:::

:::{grid-item-card} 🔍 Index of Coincidence
Identify the type of cipher from a ciphertext sample — a powerful diagnostic tool.
:::

:::{grid-item-card} 🔑 Kasiski Test
Determine the key length of a Vigenère cipher by finding repeated patterns.
:::

:::{grid-item-card} ♾️ Perfect Secrecy
Understand the information-theoretic definition of unbreakable encryption.
:::

:::{grid-item-card} 💻 Computational Security
See how modern cryptography defines security in terms of computational hardness.
:::

::::

```{admonition} Why Cryptanalysis Matters
:class: important
A cipher is only trustworthy if it has resisted serious attempts to break it. Studying attacks teaches us:
- Which design choices lead to exploitable weaknesses
- What "secure" really means — and how to measure it
- How the field has evolved from simple pattern-matching to complex algebraic attacks
```

```{admonition} Learning Objectives
:class: important
By the end of this chapter, you will be able to:
- Classify the four attack models (COA, KPA, CPA, CCA) and explain their hierarchy
- Perform frequency analysis on monoalphabetic ciphertext using the ETAOIN SHRDLU ranking
- Compute the Index of Coincidence and interpret its value for a given ciphertext
- Apply the Kasiski test to estimate the key length of a Vigenère cipher
- State Shannon's definition of perfect secrecy and his necessary conditions
- Distinguish perfect secrecy from computational security
```

---

## Warm-Up: Name That Attack

An analyst intercepts ciphertext **NWAJH DKNNJ**. She also manages to learn that a portion of the original message began with the word **HELLO**. Using only that partial knowledge, she recovers the full key and decrypts the rest. What type of attack is she performing?

```{admonition} Solution
:class: dropdown
This is a **Known-Plaintext Attack (KPA)**. The analyst does not choose the plaintext; she merely *knows* some plaintext–ciphertext pairs and exploits them to deduce the key.

For a Caesar cipher, knowing H→N gives the shift: $N - H = 13 - 7 = 6 \pmod{26}$. With key $k = 6$, the full ciphertext decrypts as **HELLO WORLD**.

By the end of this chapter you will be able to classify, mount, and defend against all four standard attack models.
```

---

## 1. What Is Cryptanalysis?

As defined in {prf:ref}`def-cryptanalysis`, cryptanalysis is the study of recovering plaintext from ciphertext (or finding the key) without authorised knowledge of the secret. More broadly, it includes:

- Finding structural weaknesses that reduce a cipher's effective security
- Distinguishing ciphertext from random data
- Forging signatures or authentication tags

A successful cryptanalytic attack does not need to be *practical* to be significant — even a theoretical improvement over brute force is a break.

```{prf:definition} Attack Goal
:label: def-attack-goal

Given a cipher $\mathcal{E} = (\text{Gen}, \text{Enc}, \text{Dec})$, a cryptanalytic attack aims to achieve one or more of the following goals (listed from strongest to weakest):

1. **Total break** — recover the secret key $k$
2. **Global deduction** — decrypt any ciphertext without $k$
3. **Local deduction** — decrypt a specific ciphertext
4. **Information deduction** — learn *any* partial information about the plaintext
5. **Distinguishability** — tell ciphertext from random noise better than chance
```

```{admonition} Why Distinguishability Matters
:class: note
Even goal 5 constitutes a break in modern cryptography. An ideal cipher should produce ciphertext that is computationally indistinguishable from a uniformly random string — any detectable pattern is a potential foothold for a deeper attack.
```

---

## 2. Attack Models

The strength of an attack depends heavily on what the adversary can observe or control. Cryptographers classify attacks by the **resources available to the attacker**.

### 2.1 The Four Standard Models

```{prf:definition} Ciphertext-Only Attack (COA)
:label: def-coa

The adversary has access only to one or more ciphertexts. No plaintext is known.

$$\text{Attacker knows:} \quad c_1, c_2, \ldots, c_n$$

This is the *weakest* assumption about the attacker and therefore the *minimum* security any cipher must provide.
```

```{prf:definition} Known-Plaintext Attack (KPA)
:label: def-kpa

The adversary has access to some plaintext–ciphertext pairs $(m_1, c_1), \ldots, (m_n, c_n)$ encrypted under the same unknown key.

$$\text{Attacker knows:} \quad (m_1, c_1), \ldots, (m_n, c_n)$$

This models realistic scenarios: standard message headers, protocol banners, or file magic bytes are *known* structure.
```

```{prf:definition} Chosen-Plaintext Attack (CPA)
:label: def-cpa

The adversary can submit arbitrary plaintexts of her choice and obtain their encryptions under the target key.

$$\text{Attacker can query:} \quad m \;\longrightarrow\; c = \text{Enc}_k(m)$$

This models an attacker who can trick an encryption oracle (e.g., a server) into encrypting chosen data. It is the standard security model for symmetric encryption.
```

```{prf:definition} Chosen-Ciphertext Attack (CCA)
:label: def-cca

The adversary can submit arbitrary ciphertexts and obtain their decryptions, *except* for the challenge ciphertext itself.

$$\text{Attacker can query:} \quad c \;\longrightarrow\; m = \text{Dec}_k(c) \quad (c \neq c^*)$$

This is the strongest standard model and is required for public-key cryptography and authenticated encryption.
```

```{admonition} Hierarchy of Attack Models
:class: tip
The four models form a strict hierarchy of adversarial power:

$$\text{COA} \;\subset\; \text{KPA} \;\subset\; \text{CPA} \;\subset\; \text{CCA}$$

Security against a stronger model implies security against all weaker ones. Modern ciphers (AES-GCM, ChaCha20-Poly1305) are designed to withstand CCA.
```

### 2.2 Kerckhoffs's Principle Revisited

Recall {prf:ref}`crit-kerckhoffs` from Chapter 1: **the security of a cipher must rest entirely in the key, not in the secrecy of the algorithm**. All four attack models implicitly assume the attacker *knows the algorithm* — only the key is secret.

::::{question} Attack Model Classification
:type: multiple-choice
:variant: single-select
:showanswer:

A web server automatically encrypts every uploaded file. An attacker uploads carefully crafted files and studies the resulting ciphertexts. Which attack model best describes this scenario?
---
[ ] Ciphertext-only attack (COA)
> The attacker is not passively observing — she is actively choosing what gets encrypted.
[x] Chosen-plaintext attack (CPA)
> Correct! The attacker selects the plaintexts (uploaded files) and obtains the corresponding ciphertexts from the server — the defining feature of a CPA.
[ ] Known-plaintext attack (KPA)
> In a KPA the attacker does not choose the plaintexts; they are merely known after the fact.
[ ] Chosen-ciphertext attack (CCA)
> A CCA requires the attacker to also submit chosen ciphertexts for decryption.
---
::::

---

## 3. Frequency Analysis

### 3.1 Letter Frequencies in English

Every natural language has a characteristic statistical signature. In English, the most common letters are:

| Rank | Letter | Frequency |
|:---:|:---:|:---:|
| 1 | E | ~12.7 % |
| 2 | T | ~9.1 % |
| 3 | A | ~8.2 % |
| 4 | O | ~7.5 % |
| 5 | I | ~7.0 % |
| 6 | N | ~6.7 % |
| 7 | S | ~6.3 % |
| 8 | H | ~6.1 % |
| 9 | R | ~6.0 % |
| 10 | D | ~4.3 % |

```{admonition} Mnemonic: ETAOIN SHRDLU
:class: tip
The sequence **ETAOIN SHRDLU** is a traditional mnemonic for the 12 most common English letters in order. Memorising it speeds up manual frequency analysis.
```

### 3.2 Breaking a Monoalphabetic Cipher

```{prf:algorithm} Frequency Analysis Attack
:label: algo-freq-analysis

**Input:** Ciphertext $c$ (monoalphabetic substitution, English plaintext)

**Output:** Plaintext $m$

1. Count the frequency of each letter $A$–$Z$ in $c$.
2. Sort ciphertext letters by descending frequency.
3. Map the most frequent ciphertext letter to **E**, the next to **T**, and so on following the ETAOIN SHRDLU order.
4. Substitute the mapping into $c$ to obtain a candidate plaintext.
5. Refine the mapping by examining digraphs (TH, HE, IN, ER, AN) and trigraphs (THE, AND, ING).
6. Verify against common short words (the, of, to, a, is).
7. Repeat steps 5–6 until the plaintext makes sense.
```

```{admonition} Why This Works
:class: important
A monoalphabetic substitution cipher is a **bijection** on the 26-letter alphabet. It transforms every occurrence of letter $x$ to the same letter $\sigma(x)$. The substitution does **not** alter frequencies — E in the plaintext still appears most often; its ciphertext equivalent is just relabelled. Frequency analysis reverses the relabelling.
```

```{prf:example} Frequency Analysis on a Short Ciphertext
:label: ex-freq-analysis

**Ciphertext:** `YDB VJGCB WN YDB NTXZBY ZCKBTY`

**Step 1 — Count frequencies:**

| Ciphertext letter | Count |
|:---:|:---:|
| B | 6 |
| Y | 3 |
| D | 3 |
| N | 2 |
| Z | 2 |
| T | 2 |
| others | 1 each |

**Step 2 — Map to English frequencies:**

Hypothesis: B → E (most frequent), Y → T, D → H

**Step 3 — Apply and check digraphs:**

Substituting B→E, Y→T, D→H: `THE VJGCE WN THE NTXZET ZCKETH`

The word `THE` appears twice — this strongly confirms the mapping.

**Step 4 — Deduce remaining letters from structure:**

`WN` → likely `OF`, `IS`, or `IN`; context "? OF THE ?" fits. Continuing:

**Recovered plaintext:** `THE ORDER OF THE SECRET AGENCY`
```

### 3.3 Interactive Frequency Analysis

```{code-cell} python
:tags: [thebe-init]

from collections import Counter

def frequency_analysis(ciphertext):
    """Count letter frequencies in ciphertext."""
    text = ciphertext.upper()
    counts = Counter(c for c in text if c.isalpha())
    total = sum(counts.values())
    print(f"{'Letter':>6} | {'Count':>5} | {'Frequency':>9}")
    print("-" * 28)
    for letter, count in counts.most_common():
        print(f"{letter:>6} | {count:>5} | {count/total*100:>8.2f}%")

# Try your own ciphertext below:
ciphertext = "YBNHM YJHBN FXLFW ITQIY BCUTB LNJHB QCBHM YJHBN"
frequency_analysis(ciphertext)
```

::::{question} Frequency Analysis Insight
:type: multiple-choice
:variant: single-select
:showanswer:

Frequency analysis works perfectly against monoalphabetic ciphers but fails completely against the one-time pad. What is the fundamental reason for the difference?
---
[x] A monoalphabetic cipher maps each plaintext letter to a single fixed ciphertext letter, preserving frequencies; the one-time pad maps each plaintext letter to a *different* letter each time it appears, producing a uniform distribution.
> Correct! The one-time pad uses a fresh random key for every position, so the same letter encrypts to different values each occurrence — the frequency signature is completely destroyed.
[ ] The one-time pad has a much longer key, making brute force harder.
> Key length alone does not explain the frequency immunity; even a very long repeating key still preserves letter frequencies.
[ ] Frequency analysis requires at least 1 000 characters; the one-time pad always produces shorter ciphertexts.
> Ciphertext length has no bearing in this context, and the one-time pad produces ciphertext of the same length as the plaintext.
[ ] Monoalphabetic ciphers use only 26 letters; the one-time pad uses 256 byte values.
> Both can operate on the same alphabet; the distinction is whether each position is independently randomised.
---
::::

---

## 4. Index of Coincidence

The **Index of Coincidence (IC)** is a statistical measure that quantifies how non-uniform the letter distribution of a text is. It distinguishes monoalphabetic ciphers from polyalphabetic ones at a glance.

```{prf:definition} Index of Coincidence
:label: def-ioc

For a text of length $n$ with letter counts $f_A, f_B, \ldots, f_Z$, the Index of Coincidence is:

$$IC = \frac{\displaystyle\sum_{i=A}^{Z} f_i(f_i - 1)}{n(n-1)}$$

Equivalently, $IC$ is the probability that two randomly chosen letters from the text are identical.
```

```{admonition} Reference Values
:class: tip

| Text type | Expected IC |
|:---|:---:|
| Random (uniform distribution) | $\approx 0.0385$ |
| English plaintext | $\approx 0.0667$ |
| Monoalphabetic ciphertext (English) | $\approx 0.0667$ (same as plaintext) |
| Vigenère (long key) | closer to $0.0385$ |
```

```{admonition} Why This Works
:class: important
A monoalphabetic substitution is a relabelling — it is a permutation of the alphabet. Such a permutation does **not** change the multiset of letter frequencies, only the names of the letters. Therefore the IC of monoalphabetic ciphertext equals that of the plaintext (~0.065 for English).

A polyalphabetic cipher (Vigenère with period $d$) mixes $d$ different frequency distributions. As $d$ grows the combined distribution approaches uniform, and IC approaches $1/26 \approx 0.0385$.
```

```{prf:example} Computing the IC
:label: ex-ioc

**Ciphertext (26 letters):** `YBSXZ YXBZS YXBSZ YXBSZ YXBS`

Suppose the letter counts are: Y=5, B=5, X=5, S=5, Z=4, all others=0, total $n=24$.

$$IC = \frac{5(4) + 5(4) + 5(4) + 5(4) + 4(3)}{24 \cdot 23} = \frac{20+20+20+20+12}{552} = \frac{92}{552} \approx 0.167$$

This value is **much higher** than English text ($\approx 0.067$), signalling that only a few distinct letters appear — a strong hint of a **very short key** or a highly patterned cipher.
```

```{prf:algorithm} IC-Based Cipher Identification
:label: algo-ic-identify

**Input:** Ciphertext $c$ of length $n \geq 100$

**Output:** Classification of the likely cipher type

1. Compute $IC(c)$.
2. If $IC(c) \approx 0.065$ → likely **monoalphabetic** (or transposition); apply frequency analysis.
3. If $IC(c) \approx 0.045$–$0.060$ → likely **Vigenère with short key**; proceed to Kasiski test.
4. If $IC(c) \approx 0.038$ → likely **Vigenère with long key** or **stream cipher**.
5. If $IC(c) \approx 0.039$ → consistent with a **one-time pad** or a modern block cipher in CTR/CBC mode.
```

::::{question} Interpreting the Index of Coincidence
:type: multiple-choice
:variant: single-select
:showanswer:

You compute the IC of a 500-letter ciphertext and obtain $IC = 0.0661$. What does this tell you?
---
[x] The ciphertext was almost certainly produced by a monoalphabetic substitution cipher; frequency analysis is the next step.
> Correct! An IC close to 0.0667 is the hallmark of a monoalphabetic cipher — the letter distribution mirrors that of English plaintext.
[ ] The ciphertext was produced by a Vigenère cipher with a very long key.
> A long Vigenère key produces an IC near 0.0385, not 0.0667.
[ ] The ciphertext was produced by the one-time pad.
> The one-time pad produces IC ≈ 0.0385, consistent with a uniform distribution.
[ ] No conclusion can be drawn without knowing the plaintext.
> The IC is a property of the ciphertext alone; no plaintext is needed.
---
::::

---

## 5. The Kasiski Test

For the Vigenère cipher, frequency analysis on the full ciphertext fails because different positions use different Caesar shifts. The **Kasiski test** recovers the key length first, after which each Caesar shift can be broken independently.

```{prf:algorithm} Kasiski Test
:label: algo-kasiski

**Input:** Vigenère ciphertext $c$

**Output:** Estimated key length $d$

1. Search $c$ for **repeated substrings** of length $\geq 3$.
2. For each repeated substring, record the **distance** between its occurrences (positions $i$ and $j$, distance $= j - i$).
3. Compute the **GCD** of all recorded distances.
4. The key length $d$ divides the GCD with high probability.
5. Test $d$ and its small divisors: for each candidate length, split the ciphertext into $d$ streams (positions $1, d+1, 2d+1, \ldots$ form stream 1; positions $2, d+2, \ldots$ form stream 2; etc.) and compute the IC of each stream. The correct $d$ gives streams with IC $\approx 0.067$.
```

```{admonition} Why Repetitions Occur
:class: note
If the same plaintext fragment happens to be encrypted starting at a position that is a multiple of $d$ apart from another occurrence, both fragments use **the same cyclic key bytes** and produce identical ciphertext. By finding these repetitions and computing distances we effectively reverse-engineer $d$.
```

```{prf:example} Kasiski Test Walk-Through
:label: ex-kasiski

**Ciphertext (fragment):** `...VHVSS...VHVSS...` (partial)

The trigram `VHVSS` appears at positions 4 and 24.

Distance $= 24 - 4 = 20$.

$\gcd(20) = 20$. Divisors of 20: $\{1, 2, 4, 5, 10, 20\}$.

We test $d = 4$ and $d = 5$ (the most cryptographically plausible small values). Computing IC for each split:

| Candidate $d$ | Average IC across $d$ streams |
|:---:|:---:|
| 4 | 0.044 |
| **5** | **0.065** |
| 10 | 0.051 |

$d = 5$ gives streams with IC close to English — the key length is **5**.

Now break 5 independent Caesar ciphers using frequency analysis on each stream.
```

::::{question} Kasiski Test Application
:type: multiple-choice
:variant: multiple-select
:showanswer:

When applying the Kasiski test, which of the following increase the reliability of the estimated key length? (Select all that apply.)
---
[x] Using longer ciphertexts (more than 500 characters)
> Correct! More text means more repeated trigrams, providing more distance samples whose GCD is more reliable.
[x] Requiring repeated substrings of length ≥ 3 rather than length 2
> Correct! Longer repeated substrings are less likely to reoccur by chance, reducing false positives.
[ ] Encrypting with a key that contains repeated letters
> A key with repeated letters does not help the Kasiski test — it only slightly reduces the effective key space.
[x] Computing the GCD over many independent distances
> Correct! More distances whose GCD converges to the same value gives stronger evidence for the key length.
---
::::

---

## 6. Perfect Secrecy

### 6.1 Shannon's Definition

In 1949, Claude Shannon gave a rigorous information-theoretic definition of what it means for a cipher to be *unconditionally secure* — secure against an adversary with unlimited computational power {cite}`stinson2018cryptography`.

```{prf:definition} Perfect Secrecy
:label: def-perfect-secrecy

A cipher $(\text{Gen}, \text{Enc}, \text{Dec})$ over message space $\mathcal{M}$ achieves **perfect secrecy** if, for every probability distribution over $\mathcal{M}$, every message $m \in \mathcal{M}$, and every ciphertext $c \in \mathcal{C}$:

$$\Pr[M = m \mid C = c] = \Pr[M = m]$$

Observing the ciphertext provides **zero information** about the plaintext.
```

```{prf:theorem} Shannon's Theorem on Perfect Secrecy
:label: thm-perfect-secrecy

A cipher achieves perfect secrecy **if and only if**:

1. $|\mathcal{K}| \geq |\mathcal{M}|$ — the key space is at least as large as the message space, **and**
2. Every key is used with equal probability, **and**
3. For every message $m$ and ciphertext $c$, there exists exactly one key $k$ such that $\text{Enc}_k(m) = c$.
```

```{admonition} Why This Matters in Cryptography
:class: important
Shannon's theorem proves that the **one-time pad** achieves perfect secrecy. It also proves that **no cipher can be perfectly secret with a key shorter than the message**. This is a fundamental information-theoretic lower bound — no algorithm, no matter how clever, can circumvent it.
```

### 6.2 The One-Time Pad

```{prf:definition} One-Time Pad (OTP)
:label: def-otp

For messages over $\{0,1\}^n$, the one-time pad is defined as:

- $\text{Gen}$: choose $k \xleftarrow{R} \{0,1\}^n$ uniformly at random
- $\text{Enc}_k(m) = m \oplus k$
- $\text{Dec}_k(c) = c \oplus k$

where $\oplus$ denotes bitwise XOR.
```

```{admonition} OTP Limitations
:class: warning
Despite achieving perfect secrecy, the one-time pad is impractical for most applications:

1. **Key length equals message length** — you need as many key bits as plaintext bits
2. **Keys must never be reused** — encrypting two messages $m_1, m_2$ with the same key $k$ leaks $m_1 \oplus m_2$ because $c_1 \oplus c_2 = m_1 \oplus m_2$
3. **Secure key distribution** — if you have a secure channel to transmit the key, why not transmit the message directly?
```

```{prf:example} Two-Time Pad Attack
:label: ex-two-time-pad

Suppose an adversary intercepts two ciphertexts encrypted with the *same* one-time pad key $k$:

$$c_1 = m_1 \oplus k, \qquad c_2 = m_2 \oplus k$$

XOR-ing the two ciphertexts:

$$c_1 \oplus c_2 = (m_1 \oplus k) \oplus (m_2 \oplus k) = m_1 \oplus m_2$$

The attacker now has $m_1 \oplus m_2$. If she knows (or guesses) any bytes of $m_1$, she can recover corresponding bytes of $m_2$, and vice versa — key completely compromised.

This exact attack was used against Soviet intelligence (VENONA project, 1940s–50s) after they reused one-time pad key pages under logistical pressure.
```

::::{question} Perfect Secrecy Trade-Offs
:type: multiple-choice
:variant: single-select
:showanswer:

Which of the following statements about perfectly secret ciphers is TRUE?
---
[ ] A perfectly secret cipher cannot be broken even if the attacker knows part of the plaintext.
> False — Shannon's definition of perfect secrecy assumes the attacker sees only ciphertext. A known-plaintext attack on the OTP immediately reveals the key for those positions.
[x] A perfectly secret cipher requires a key at least as long as the message.
> Correct! Shannon's theorem proves this is a necessary condition — no perfectly secret cipher can use a shorter key.
[ ] AES-256 achieves perfect secrecy because its key space is astronomically large.
> AES uses a 256-bit key to encrypt arbitrarily long messages, so $|\mathcal{K}| < |\mathcal{M}|$ in general — it does not achieve perfect secrecy, only computational security.
[ ] Perfect secrecy guarantees security against chosen-ciphertext attacks.
> Perfect secrecy is an information-theoretic notion and does not address integrity or malleability — the one-time pad is trivially malleable.
---
::::

---

## 7. Computational Security

Perfect secrecy is too demanding for practical systems. Modern cryptography relaxes the requirement using two pragmatic assumptions:

1. Computationally bounded adversaries (polynomial-time algorithms)
2. Security holds **with overwhelming probability**, not absolutely

```{prf:definition} Negligible Function
:label: def-negligible

A function $\varepsilon : \mathbb{N} \to \mathbb{R}_{\geq 0}$ is **negligible** if for every positive polynomial $p$ there exists $N$ such that for all $n > N$:

$$\varepsilon(n) < \frac{1}{p(n)}$$

Informally, $\varepsilon(n)$ decreases faster than any inverse polynomial. Security parameter $n$ controls key length; larger $n$ makes $\varepsilon$ vanishingly small.
```

The practical relaxation of perfect secrecy is **IND-CPA (Indistinguishability under Chosen-Plaintext Attack)**, where security holds against computationally bounded adversaries rather than unbounded ones. The formal IND-CPA game, negligible advantage bounds, and construction requirements are fully defined in **Chapter 6**.

### 7.1 Security Levels

Computational security is quantified in **bits**:

| Security Level | Key Size (symmetric equivalent) | Current Status |
|:---:|:---:|:---:|
| 56-bit | DES (56-bit key) | **Broken** (since 1998) |
| 80-bit | | **Marginal** — not recommended |
| 112-bit | 3DES | **Deprecated** |
| 128-bit | AES-128, ChaCha20 | **Secure** (2026 standard) |
| 192-bit | AES-192 | **Secure** |
| 256-bit | AES-256 | **Secure, post-quantum margin** |

---

## 8. Advanced Attack Techniques (Overview)

Modern block ciphers are designed to resist the following families of attacks:

### 8.1 Differential Cryptanalysis

```{prf:definition} Differential Cryptanalysis
:label: def-differential

Differential cryptanalysis (Biham & Shamir, 1990) is a **chosen-plaintext** technique that analyzes how differences $\Delta x = x \oplus x'$ in the input propagate through the cipher:

$$\Delta y = \text{Enc}_k(x) \oplus \text{Enc}_k(x')$$

By choosing pairs $(x, x')$ with a specific $\Delta x$ and observing $\Delta y$, an attacker gathers statistical information about the last-round subkey.
```

```{admonition} Differential Attack on DES
:class: note
DES was secretly *designed* with resistance to differential cryptanalysis built into its S-boxes — IBM knew about the technique in the 1970s but it was not published until 1990. A full 16-round DES attack requires $2^{47}$ chosen plaintexts.
```

### 8.2 Linear Cryptanalysis

```{prf:definition} Linear Cryptanalysis
:label: def-linear

Linear cryptanalysis (Matsui, 1993) is a **known-plaintext** technique. It finds a linear approximation:

$$m_{i_1} \oplus m_{i_2} \oplus \cdots \oplus c_{j_1} \oplus c_{j_2} \oplus \cdots = k_{l_1} \oplus k_{l_2} \oplus \cdots$$

that holds with probability $\frac{1}{2} + \varepsilon$ for a non-trivial bias $\varepsilon$. Collecting $O(1/\varepsilon^2)$ plaintext–ciphertext pairs yields key bits with statistical significance.
```

### 8.3 Meet-in-the-Middle Attack

```{prf:definition} Meet-in-the-Middle Attack
:label: def-mitm

For a double-encryption scheme $c = E_{k_2}(E_{k_1}(m))$, an adversary with one known plaintext–ciphertext pair $(m, c)$ can:

1. Compute $E_{k_1}(m)$ for **all** $2^{|k_1|}$ values of $k_1$; store in a table.
2. Compute $D_{k_2}(c)$ for **all** $2^{|k_2|}$ values of $k_2$.
3. Find matching middle values — this gives the key pair $(k_1, k_2)$ in $O(2^{|k_1|} + 2^{|k_2|})$ time (not $O(2^{|k_1|+|k_2|})$).

Double-DES has an effective security of only 57 bits (barely better than single DES), not 112 bits.
```

### 8.4 Side-Channel Attacks

```{prf:definition} Side-Channel Attack
:label: def-side-channel

A side-channel attack exploits **physical information** leaked during computation rather than mathematical weaknesses in the cipher:

- **Timing attacks** — execution time varies with key bits (Kocher, 1996)
- **Power analysis (SPA/DPA)** — power consumption curves reveal key-dependent operations
- **Electromagnetic (EM) attacks** — EM radiation from hardware leaks internal state
- **Cache-timing attacks** — memory access patterns on shared hardware reveal secrets
```

```{admonition} Practical Relevance
:class: warning
Side-channel attacks are among the most practical threats to real implementations. Correct mathematical design is necessary but not sufficient — implementations must also be **constant-time** (no branching or memory access patterns that depend on secret data).
```

::::{question} Attack Classification
:type: multiple-choice
:variant: multiple-select
:showanswer:

Which of the following are examples of side-channel attacks? (Select all that apply.)
---
[x] Measuring the time taken by an RSA decryption operation to infer key bits
> Correct! This is a classic timing attack (Kocher 1996), exploiting the key-dependent execution path in square-and-multiply exponentiation.
[ ] Factoring the RSA modulus $n$ using the Number Field Sieve
> This is a mathematical attack on the underlying hard problem, not a side channel.
[x] Analysing power consumption spikes in a smartcard during AES encryption
> Correct! This is a Differential Power Analysis (DPA) attack — a classic side-channel technique.
[x] Exploiting cache timing to recover AES key bytes on a shared server
> Correct! Cache-timing attacks (e.g., Flush+Reload) are a side-channel attack exploiting shared hardware state.
[ ] Using differential cryptanalysis with $2^{47}$ chosen plaintexts on DES
> Differential cryptanalysis is a mathematical, chosen-plaintext attack — not a side-channel attack.
---
::::

---

## 9. Summary

| Concept | Definition | Key Takeaway |
|:---|:---|:---|
| **Ciphertext-Only Attack** | Adversary sees only ciphertext | Minimum bar any cipher must clear |
| **Known-Plaintext Attack** | Adversary knows some $(m, c)$ pairs | Real-world banners/headers give free KPA leverage |
| **Chosen-Plaintext Attack** | Adversary encrypts chosen messages | Standard IND-CPA model for symmetric ciphers |
| **Chosen-Ciphertext Attack** | Adversary also decrypts chosen ciphertexts | Required for public-key and authenticated encryption |
| **Frequency Analysis** | Exploit letter frequency distributions | Breaks all monoalphabetic ciphers |
| **Index of Coincidence** | Probability two random letters match | Identifies cipher family from ciphertext alone |
| **Kasiski Test** | Find repeated trigrams; GCD gives key length | Reduces Vigenère to independent Caesar ciphers |
| **Perfect Secrecy** | $\Pr[M=m \mid C=c] = \Pr[M=m]$ | Requires key $\geq$ message length (OTP) |
| **Computational Security** | Polynomial-time attacker wins with negligible advantage | Practical standard: AES, ChaCha20 |
| **Differential / Linear** | Statistical attack on cipher structure | Guided the design of modern S-boxes |
| **Side-Channel** | Physical leakage attacks | Requires constant-time implementations |

---

## Exercises

```{exercise} Frequency Analysis by Hand
:label: ch04-ex-freq

The following ciphertext was produced by a monoalphabetic substitution cipher applied to English text. Use frequency analysis to recover the plaintext.

```
CZSGJ ZQQZB AWGZD DSCZJ AQAZJ QOCAB AWZQO CGDZA
```

*Hint:* Count letter frequencies, map the top three to E, T, A (or similar), then use common digraphs to refine.
```

```{solution} ch04-ex-freq
:label: sol-ch04-ex-freq
:class: dropdown

**Step 1 — Count frequencies (40 letters):**
Z = 8 (20%), A = 6 (15%), Q = 6 (15%), C = 4 (10%), D = 3 (8%), G = 3 (8%), J = 3 (8%), O = 2 (5%), W = 2 (5%), B = 2 (5%), S = 1 (2%)

**Step 2 — Initial mapping:**

Z (20%) → E, A (15%) → T, Q (15%) → A (third most common)

**Step 3 — Apply and examine:**

Partial substitution: `_ES_J E__EB T_GE_ _S_J T_TEJ _O_TB T_E_O _G_ET`

The digraph `ZQ` appears as `EA`-pattern → consistent with `EA` in "EACH", "EAST". Also `QA` → "AT" is very common.

**Step 4 — Refine from digraphs:**

Mapping ZQ → EA, JQ → HA keeps `J → H`:

Partial read: `EACH HEART TGEDS EACH TATEH OCH TB TEHO CGSET`

Trying C → S, G → R: `EACH HEART SREDS EACH TATEH OSRTB TEHO SRGET`

Final resolved mapping from complete analysis:
Z→E, Q→A, A→T, J→H, C→S, G→R, D→I, O→N, B→D, W→O, S→F

**Recovered plaintext:** `FRESH HEART TRIED EACH FATHER NOT DO FRIEND`

*(Exact recovery depends on the full mapping — the key point is the method.)*
```

```{exercise} Index of Coincidence Calculation
:label: ch04-ex-ioc

The following 30-letter text was extracted from an encrypted message:

```
AAABB BCCCC DDDEE EEFFF GGHHI IJJKK
```

1. Compute the Index of Coincidence.
2. What does the IC value suggest about the cipher used?
```

```{solution} ch04-ex-ioc
:label: sol-ch04-ex-ioc
:class: dropdown

**Letter counts (30 letters total):**

| Letter | Count $f_i$ | $f_i(f_i - 1)$ |
|:---:|:---:|:---:|
| A | 3 | 6 |
| B | 3 | 6 |
| C | 4 | 12 |
| D | 3 | 6 |
| E | 4 | 12 |
| F | 3 | 6 |
| G | 2 | 2 |
| H | 2 | 2 |
| I | 2 | 2 |
| J | 2 | 2 |
| K | 2 | 2 |
| **Total** | **30** | **58** |

$$IC = \frac{58}{30 \cdot 29} = \frac{58}{870} \approx 0.0667$$

**Interpretation:** IC ≈ 0.067 is very close to the expected value for English plaintext (0.0667) and monoalphabetic ciphertext. This strongly suggests the ciphertext was produced by a **monoalphabetic substitution cipher** (or a transposition cipher). Frequency analysis is the recommended next step.
```

```{exercise} Kasiski Test Key Length
:label: ch04-ex-kasiski

A Vigenère-encrypted ciphertext contains the trigram `XKQ` at positions 5, 35, and 65.

1. Compute the distances between occurrences.
2. Compute the GCD of the distances.
3. List all plausible key lengths and state which is most likely.
```

```{solution} ch04-ex-kasiski
:label: sol-ch04-ex-kasiski
:class: dropdown

**Distances:**

- Between positions 5 and 35: $35 - 5 = 30$
- Between positions 5 and 65: $65 - 5 = 60$
- Between positions 35 and 65: $65 - 35 = 30$

**GCD:**

$$\gcd(30, 60, 30) = 30$$

**Divisors of 30:** $\{1, 2, 3, 5, 6, 10, 15, 30\}$

**Plausible key lengths:** 3, 5, 6, 10, 15, 30 (excluding 1 and 2 as trivial/impractical)

**Most likely:** The cryptographically common key lengths are **5** and **6** (short, memorable, historically realistic for Vigenère). To narrow down further, split the ciphertext into streams for each candidate length and compute the IC — the correct key length gives streams with IC ≈ 0.067.
```

---

```{bibliography}
:filter: docname in docnames
```
