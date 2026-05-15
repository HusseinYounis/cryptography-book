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

# Chapter 8: Block Ciphers

## Introduction

A block cipher is a **keyed permutation** on fixed-size blocks of data. For one secret key, it maps each plaintext block to exactly one ciphertext block, and decryption applies the inverse mapping to recover the original block.

Block ciphers are not usually used alone. A real message is longer than one block, and a secure system must also hide repeated patterns, handle nonces or IVs correctly, and usually authenticate the ciphertext. For that reason, this chapter studies block ciphers in three layers:

1. The design ideas that make a block cipher look random.
2. Two major block-cipher structures: Feistel networks and substitution-permutation networks.
3. Modes of operation, which turn a one-block primitive into secure encryption for real messages.

::::{grid} 1 2 2 3
:gutter: 3

:::{grid-item-card} 🏗️ Cipher Structures
Feistel networks (DES) and SPNs (AES) — the two dominant design paradigms.
:::

:::{grid-item-card} 🔒 DES & AES
The historical standard (broken) and its modern replacement (still secure).
:::

:::{grid-item-card} ⚙️ Modes of Operation
ECB, CBC, CTR, GCM — how to encrypt more than one block safely.
:::

::::

```{admonition} Learning Objectives
:class: tip
By the end of this chapter you will be able to:
- Define a block cipher as a keyed permutation and explain why block size matters
- Explain Shannon's confusion and diffusion principles
- Describe Feistel and SPN cipher structures and compare their invertibility requirements
- State the key parameters of DES and explain why it is insecure
- Describe the four AES round operations and their roles
- Distinguish ECB, CBC, CTR, and GCM, and explain why authenticated encryption is preferred
```

---

## Warm-Up: The Same Image, Twice

The famous "ECB penguin" demonstrates that encrypting a bitmap image with AES but in ECB mode produces a ciphertext in which the penguin's outline is still clearly visible. How is this possible if AES is a secure cipher?

```{admonition} Solution
:class: dropdown
AES in ECB mode encrypts each 128-bit block **independently**. Large uniform regions of the image (the white belly, the black back) consist of many identical 16-byte blocks. Because the cipher is **deterministic** — same block + same key → same ciphertext block — all identical plaintext blocks produce identical ciphertext blocks. The pattern survives encryption.

The fix is to use a **mode of operation** (CBC, CTR, GCM) that ensures identical plaintext blocks produce different ciphertext blocks. This requires either chaining (CBC) or a counter/nonce (CTR, GCM).
```

---

```{admonition} How to Study This Chapter
:class: note
Read Sections 1-3 for the core ideas: block size, confusion, diffusion, Feistel networks, and SPNs. Section 4 is a detailed DES case study; use the S-DES examples to learn the mechanics, then treat the long DES tables as reference material. Section 5 explains AES as the modern standard, and Section 6 is the practical security layer: the mode of operation often determines whether an implementation is safe.
```

---

## 1. What a Block Cipher Must Achieve

At a high level, a block cipher should behave like a randomly chosen permutation that only the key holder can evaluate and invert. This gives us three immediate design requirements.

```{prf:definition} Block Cipher
:label: def-block-cipher

A **block cipher** is a pair of efficient algorithms $(E, D)$ parameterised by a secret key $K$:

$$E_K : \{0,1\}^n \to \{0,1\}^n$$

$$D_K : \{0,1\}^n \to \{0,1\}^n$$

such that for every $n$-bit block $P$:

$$D_K(E_K(P)) = P$$

For each fixed key $K$, $E_K$ must be a **permutation**: no two plaintext blocks may encrypt to the same ciphertext block.
```

| Requirement | Meaning | Why students should care |
|:---|:---|:---|
| **Fixed block size** | AES always encrypts 128-bit blocks; DES encrypts 64-bit blocks | Long messages need a mode of operation |
| **Large key space** | Brute force should require about $2^k$ trials | DES failed mainly because $k=56$ was too small |
| **Random-looking output** | Small input/key changes should affect about half the output bits | Prevents statistical and algebraic shortcuts |

```{admonition} Deterministic Primitive, Randomised Encryption
:class: important
A block cipher itself is deterministic: same key and same block always give the same ciphertext block. Secure encryption of real messages therefore requires a mode of operation that adds an IV, nonce, counter, or authentication tag. This is exactly why AES can be secure while AES-ECB is not.
```

### 1.1 Confusion and Diffusion

Shannon's two principles from 1949 underpin modern block cipher design.

```{prf:criterion} Confusion and Diffusion
:label: crit-confusion-diffusion

**Confusion:** Each ciphertext bit should depend on the key in a manner so complex and involved that even knowing the ciphertext and the plaintext, the attacker cannot deduce the key bits. *Implemented by substitution (S-boxes).*

**Diffusion:** Each plaintext bit should influence as many ciphertext bits as possible — ideally all of them — and each ciphertext bit should be influenced by as many plaintext bits as possible. *Implemented by permutation (P-boxes, MixColumns, ShiftRows).*

A cipher must have **both** properties to resist statistical attacks:
- Confusion alone makes frequency analysis hard but linear structures remain.
- Diffusion alone spreads dependencies but leaves exploitable patterns.
```

| Property | Goal | Threat resisted | Mechanism |
|:---:|:---|:---|:---:|
| **Confusion** | Hide relationship between key and ciphertext | Known-plaintext, key-recovery attacks | S-boxes |
| **Diffusion** | Spread each plaintext/key bit across the full ciphertext | Statistical attacks, differential/linear cryptanalysis | P-boxes, MixColumns |

---

### 1.2 S-boxes: Confusion by Substitution

An **S-box** (substitution box) is the main source of non-linearity in many block ciphers. It replaces a small input word with a different output word according to a fixed lookup table.

The table is public. The secrecy of the cipher does **not** come from hiding the S-box; it comes from mixing secret round keys with the state before and between substitution layers.

```{prf:definition} S-box
:label: def-sbox

An **S-box** is a fixed lookup table that maps an $n$-bit input to an $m$-bit output, usually in a deliberately non-linear way:

$$S : \{0,1\}^n \to \{0,1\}^m$$

Good S-boxes are designed so that there is no useful linear equation relating input bits to output bits. This makes linear and differential cryptanalysis much harder.
```

| S-box width | Used in | Note |
|:---:|:---:|:---|
| 4-bit in, 4-bit out | PRESENT, lightweight ciphers | Compact, suited for hardware |
| 6-bit in, 4-bit out | DES S1-S8 | Non-square mapping; not individually invertible |
| 8-bit in, 8-bit out | AES SubBytes | Bijective; required for AES decryption |

````{prf:example} A Correct 4-bit S-box Lookup
:label: ex-sbox-lookup

Consider the following toy S-box. The input is a 4-bit value, interpreted as a hexadecimal digit; the output is another 4-bit value.

| Input $x$ | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | A | B | C | D | E | F |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| $S(x)$ | E | 4 | D | 1 | 2 | F | B | 8 | 3 | A | 6 | C | 5 | 9 | 0 | 7 |

If the input nibble is $x=\mathtt{1010}_2=\mathtt{A}_{16}$, then the table gives:

$$S(\mathtt{A}) = \mathtt{6} = \mathtt{0110}_2$$

This is a substitution of the **input value** by a fixed table entry. The S-box does not select bits from the key. In a real round, the key first changes the state through XOR or another key-mixing operation, and then the S-box substitutes the resulting state bits.
````

```{admonition} S-boxes in AES
:class: note
AES uses one public 8-bit S-box in the **SubBytes** operation. Every byte of the 16-byte AES state is independently replaced by its S-box value. The AES S-box is constructed from multiplicative inversion in $GF(2^8)$ followed by an affine transformation. This gives strong non-linearity while still being invertible.
```

#### Linearity vs Non-Linearity in S-Boxes

One of the most important properties of a good S-box is **non-linearity**. A function $f$ is linear over XOR if:

$$f(a \oplus b) = f(a) \oplus f(b)$$

for all inputs $a$ and $b$. If a cipher used only linear operations, an attacker could describe encryption as a system of linear equations and solve for key information from enough plaintext-ciphertext pairs.

```{admonition} Key Intuition
:class: tip
Linear layers are useful for spreading bits, but a cipher also needs non-linear substitution. Without S-box non-linearity, repeated rounds usually produce a larger linear transformation, not real cryptographic confusion.
```

```{figure} ../figures/ch08/sbox_linear_vs_nonlinear.png
:align: center
:width: 90%
:alt: Linear vs Non-Linear S-box substitution plots

Linear and non-linear substitution compared. A good S-box avoids visible input-output structure and makes bit differences propagate unpredictably.
```

---

### 1.3 P-boxes: Diffusion by Rearrangement

A **P-box** (permutation box, sometimes called a diffusion box) rearranges bit positions. By itself, a P-box is linear; its purpose is to spread the output bits of one substitution layer into many positions before the next substitution layer.

```{prf:definition} P-box
:label: def-pbox

A **P-box** takes an $n$-bit input and produces an $m$-bit output by rearranging (and optionally duplicating or dropping) bits according to a fixed table. The table entry at position $j$ specifies which input bit position maps to output position $j$.
```

There are three useful cases.

| P-box type | Relation | Invertible? | DES/AES example |
|:---:|:---:|:---:|:---|
| **Straight** | $n=m$ | Yes, if every input appears exactly once | AES ShiftRows; DES final P-box |
| **Expansion** | $m>n$ | No; some bits are duplicated | DES E-box, 32 bits to 48 bits |
| **Compression** | $m<n$ | No; some bits are dropped | DES PC-1 and PC-2 key selections |

```{figure} ../figures/ch08/pbox_types_overview.png
:name: fig-pbox-types
:width: 70%
:align: center

**Three types of P-boxes.** Straight (n = m), Compression (m < n), and Expansion (m > n).
```

---

#### 1.3.1 Straight P-box ($n = m$)

A **straight P-box** has the same number of inputs and outputs. Every input bit appears in the output exactly once, just at a different position.

```{figure} ../figures/ch08/pbox_straight.png
:name: fig-pbox-straight
:width: 65%
:align: center

**Straight P-box.** The number of inputs equals the number of outputs. Each bit is mapped to a new position — no bit is dropped or duplicated. This is the only type of P-box that is **invertible** (its inverse is simply the reverse permutation).
```

- **Invertible:** yes — the reverse permutation undoes it exactly.
- **Used in:** DES final P-box (after S-boxes in each round), AES ShiftRows.

````{admonition} Solved Example — Straight P-box
:class: tip

**Given:** 8-bit input `0 1 0 1 0 1 0 1` (positions 1–8) and the permutation table below.

| Output position | Takes input bit |
|:---:|:---:|
| 1 | 4 |
| 2 | 1 |
| 3 | 6 |
| 4 | 3 |
| 5 | 8 |
| 6 | 5 |
| 7 | 2 |
| 8 | 7 |

**Step-by-step:**

```
Input:   pos  1  2  3  4  5  6  7  8
         bit  0  1  0  1  0  1  0  1

Output pos 1  ← input bit 4  = 1
Output pos 2  ← input bit 1  = 0
Output pos 3  ← input bit 6  = 1
Output pos 4  ← input bit 3  = 0
Output pos 5  ← input bit 8  = 1
Output pos 6  ← input bit 5  = 0
Output pos 7  ← input bit 2  = 1
Output pos 8  ← input bit 7  = 0

Output:  1  0  1  0  1  0  1  0
```

**Result:** `01010101` → `10101010`  
Every bit moved to a new position; **no bit was lost or duplicated**.
````

---

#### 1.3.2 Expansion P-box ($m > n$)

An **expansion P-box** has more outputs than inputs. Some input bits are **duplicated** to fill the extra output positions.

```{figure} ../figures/ch08/pbox_expansion.png
:name: fig-pbox-expansion
:width: 65%
:align: center

**Expansion P-box.** More outputs than inputs — certain input bits appear at multiple output positions. One input can map to more than one output.
```

- **Invertible:** **no** — because one input maps to multiple outputs, the decryption algorithm cannot determine the unique original input from the output alone.
- **Used in:** DES E-box (expands the 32-bit right half to 48 bits before XOR with the subkey).

````{admonition} Solved Example — Expansion P-box
:class: tip

**Given:** 4-bit input `0 1 0 1` expanded to 6 bits using the table below.

| Output position | Takes input bit |
|:---:|:---:|
| 1 | 4 |
| 2 | 1 |
| 3 | 2 |
| 4 | 3 |
| 5 | 4 |
| 6 | 1 |

**Step-by-step:**

```
Input:   pos  1  2  3  4
         bit  0  1  0  1

Output pos 1  ← input bit 4  = 1
Output pos 2  ← input bit 1  = 0
Output pos 3  ← input bit 2  = 1
Output pos 4  ← input bit 3  = 0
Output pos 5  ← input bit 4  = 1   ← bit 4 used again (duplicated)
Output pos 6  ← input bit 1  = 0   ← bit 1 used again (duplicated)

Output:  1  0  1  0  1  0
```

**Result:** `0101` (4 bits) → `101010` (6 bits)  
Input bits **1** and **4** each appear **twice** in the output — that is what makes this non-invertible.
````

---

#### 1.3.3 Compression P-box ($m < n$)

A **compression P-box** has fewer outputs than inputs. Some input bits are **dropped** entirely.

```{figure} ../figures/ch08/pbox_compression.png
:name: fig-pbox-compression
:width: 65%
:align: center

**Compression P-box.** Fewer outputs than inputs — certain input bits are discarded. One output maps to exactly one input, but some inputs are not included.
```

- **Invertible:** **no** — dropped bits are lost; decryption cannot recover them.
- **Used in:** DES PC-1 (64-bit key → 56 bits by dropping 8 parity bits) and PC-2 (56 bits → 48-bit subkey).

````{admonition} Solved Example — Compression P-box
:class: tip

**Given:** 8-bit input `0 1 0 1 0 1 0 1` compressed to 5 bits using the table below (3 bits are dropped).

| Output position | Takes input bit |
|:---:|:---:|
| 1 | 2 |
| 2 | 5 |
| 3 | 1 |
| 4 | 7 |
| 5 | 4 |

**Step-by-step:**

```
Input:   pos  1  2  3  4  5  6  7  8
         bit  0  1  0  1  0  1  0  1

Output pos 1  ← input bit 2  = 1
Output pos 2  ← input bit 5  = 0
Output pos 3  ← input bit 1  = 0
Output pos 4  ← input bit 7  = 0
Output pos 5  ← input bit 4  = 1

Dropped:  bits at positions 3, 6, 8  (values 0, 1, 1 — permanently lost)

Output:  1  0  0  0  1
```

**Result:** `01010101` (8 bits) → `10001` (5 bits)  
Bits at positions **3, 6, 8** are discarded — the original 8-bit input **cannot** be recovered from the 5-bit output.
````

---

#### 1.3.4 Invertibility Summary

```{admonition} Which P-boxes are invertible?
:class: important

| P-box type | $n$ vs $m$ | Invertible? | Reason |
|:---:|:---:|:---:|:---|
| **Straight** | $n = m$ | ✓ **Yes** | Every bit appears exactly once; reverse table undoes the permutation |
| **Expansion** | $m > n$ | ✗ **No** | One input maps to multiple outputs — decryption cannot resolve the original |
| **Compression** | $m < n$ | ✗ **No** | Some input bits are discarded — cannot be recovered during decryption |

This is why **Feistel networks** (DES) use non-invertible components freely — the XOR structure of the network provides invertibility for the cipher as a whole, even when individual building blocks like the E-box and PC-2 are not invertible.
```

---

### 1.4 How Confusion and Diffusion Work Together

A single round of S-box followed by P-box achieves local confusion and diffusion. After just **two rounds**, changes propagate through the full block — the **avalanche effect**:

1. **Round 1:** One plaintext bit enters an S-box → multiple output bits differ (confusion).
2. **Round 1 P-box:** Those differing bits are spread across different S-boxes (diffusion).
3. **Round 2:** Each affected S-box amplifies the change further (more confusion).
4. **After a few rounds:** Every output bit depends on every input bit and every key bit.

```{admonition} The Avalanche Effect
:class: tip
A cipher exhibits the **avalanche effect** when changing a single input bit (plaintext or key) changes approximately half of all output bits. This property — a consequence of repeated confusion and diffusion — is required for a cipher to be secure against statistical attacks.

DES achieves a full avalanche after approximately 5 rounds; AES after 2 rounds (due to MixColumns providing very strong diffusion per round).
```

::::{question} P-box Types
:type: multiple-choice
:variant: single-select
:showanswer:

DES's **E-box** expands the 32-bit right half into 48 bits before XOR with the subkey. Which type of P-box is this, and is it invertible?
---
[ ] Straight P-box; yes, it is invertible.
> A straight P-box has equal input and output counts. The E-box expands 32 bits to 48 — the counts differ.
[x] Expansion P-box; no, it is not invertible.
> Correct! The E-box has 32 inputs and 48 outputs (m > n), making it an expansion P-box. Because some bits are duplicated in the output, the original input cannot be uniquely recovered — it is not invertible. DES does not need E-box invertibility because the Feistel XOR structure provides overall invertibility.
[ ] Compression P-box; no, it is not invertible.
> A compression P-box has fewer outputs than inputs. The E-box goes 32 → 48 bits, which is an increase.
[ ] Straight P-box; no, it is not invertible.
> Straight P-boxes (n = m) are always invertible — their reverse permutation undoes the mapping.
---
::::

---

## 2. Feistel Networks

Most block ciphers built before 2000 (including DES) use the **Feistel structure**, which elegantly unifies encryption and decryption into the same circuit.

### 2.1 Key Design Parameters

```{prf:definition} Feistel Cipher Parameters
:label: def-feistel-params

A general Feistel cipher is fully characterised by six design parameters:

| Parameter | Description | Typical value |
|:---|:---|:---:|
| **Block size** ($2n$) | Width of the plaintext/ciphertext block in bits. Larger blocks resist statistical attacks. | 64 – 128 bits |
| **Key size** ($k$) | Length of the master secret key. Determines the brute-force work factor $2^k$. | 56 – 256 bits |
| **Number of rounds** ($r$) | How many times the round function is iterated. More rounds → stronger security but slower speed. | 8 – 32 rounds |
| **Subkey generation algorithm** | Derives $r$ subkeys $K_1, \ldots, K_r$ (each $m$ bits wide) from the master key via permutations, shifts, and XOR. | Cipher-specific |
| **Round function** $F$ | A keyed function $F: \{0,1\}^n \times \{0,1\}^m \to \{0,1\}^n$ applied to the right half in each round. Provides confusion and (partial) diffusion. **Need not be invertible.** | S-box + P-box combo |
| **Swap rule** | After the last round the halves are exchanged so that encryption and decryption share the same circuit. | Always applied |
```

### 2.2 Encryption Structure

```{prf:definition} Feistel Network — Encryption
:label: def-feistel

A **Feistel network** with $r$ rounds processes a $2n$-bit block by splitting it into two $n$-bit halves $(L_0, R_0)$:

**Encryption round $i$ ($1 \leq i \leq r$):**

$$L_i = R_{i-1}$$
$$R_i = L_{i-1} \oplus F(R_{i-1},\; K_i)$$

where $F$ is the **round function** and $K_i$ is the $i$-th **subkey** produced by the key schedule.

**Final swap (after round $r$):**

$$C_L = R_r, \quad C_R = L_r$$

The halves are exchanged one final time so that the decryption circuit is **identical** to encryption — only the subkey order changes.
```

```{figure} ../figures/ch08/feistel_encrypt.avif
:name: fig-feistel-encrypt
:width: 60%
:align: center

**Feistel Cipher — Encryption.** The plaintext block is split into left half $L_0$ and right half $R_0$. In each round, the right half passes through the round function $F$ together with a subkey $K_i$; the result is XORed into the left half, and the halves swap. After $r$ rounds a **final swap** produces the ciphertext $(R_r, L_r)$ — note the swapped order.
```

```{admonition} Two Feistel Conventions
:class: note

Two conventions appear in the literature:

| | After last round | Ciphertext output | Key property |
|:---|:---|:---|:---|
| **Convention A — no final swap** | Output $(L_r, R_r)$ directly | $L_r \| R_r$ | Simpler to describe |
| **Convention B — final swap** (DES-style) | Swap halves once more | $R_r \| L_r$ | Encryption and decryption are **the exact same circuit** |

**This book uses Convention B**, matching the diagrams above. The one extra swap after the last round means you can run the identical hardware circuit in both directions — only the subkey order changes. Without the final swap, decryption would require an extra un-swap step not present in the encryption path.
```

### 2.3 Decryption Structure

```{prf:definition} Feistel Network — Decryption
:label: def-feistel-dec

**Decryption** uses the **identical circuit** and the **same round equations**, applying subkeys in **reverse order** $(K_r, K_{r-1}, \ldots, K_1)$:

$$L_i = R_{i-1}$$
$$R_i = L_{i-1} \oplus F(R_{i-1},\; K_i)$$

**Final swap (after round $r$):** Plaintext $P = (R_r,\; L_r)$

The round function $F$ is **never inverted** — the XOR structure of the network provides invertibility for free.
```

```{figure} ../figures/ch08/feistel_decrypt.avif
:name: fig-feistel-decrypt
:width: 60%
:align: center

**Feistel Cipher — Decryption.** The ciphertext $(R_r, L_r)$ is fed into the same circuit. Note that the ciphertext's left half is $R_r$ and right half is $L_r$ — the mirror image of encryption's final swap. After $r$ rounds with reversed subkeys, a final swap recovers the plaintext $(L_0, R_0)$.
```

```{admonition} Why Feistel Networks Are Elegant
:class: important
The round function $F$ does **not** need to be invertible. Inversion is achieved by the XOR structure of the network itself. This means the same hardware/software circuit encrypts and decrypts — only the key schedule is reversed. DES's entire 16-round structure is symmetric; the chip from 1977 decrypts by reversing the key order.
```

```{prf:remark} Why the Previous Round Can Be Recovered
:label: rem-feistel-inversion

Suppose one encryption round produced:

$$L_i = R_{i-1}, \qquad R_i = L_{i-1} \oplus F(R_{i-1}, K_i)$$

From $(L_i, R_i)$, the previous right half is already known because $R_{i-1}=L_i$. Then the previous left half is recovered by XORing the same round-function value again:

$$L_{i-1} = R_i \oplus F(L_i, K_i)$$

The important point is that decryption recomputes $F(L_i,K_i)$; it never needs to invert $F$.
```

### 2.4 Subkey Generation (Key Schedule)

```{prf:algorithm} Generic Feistel Key Schedule
:label: algo-feistel-keyschedule

**Input:** Master key $K$ of $k$ bits

**Output:** $r$ subkeys $K_1, K_2, \ldots, K_r$, each of $m$ bits ($m \leq 2n$)

**Typical steps (illustrated by DES):**

1. Apply an initial **permuted choice** (PC-1) that selects 56 of the 64 key bits and splits them into two 28-bit halves $C_0, D_0$.
2. For each round $i = 1, \ldots, r$:
   a. **Left-rotate** both halves by $s_i$ positions: $C_i \leftarrow \text{LS}_{s_i}(C_{i-1})$, $D_i \leftarrow \text{LS}_{s_i}(D_{i-1})$.
   b. Apply a second **permuted choice** (PC-2) to the 56-bit concatenation $C_i \| D_i$ to select $m = 48$ bits as subkey $K_i$.
3. Output $K_1, \ldots, K_{16}$.

Decryption uses $K_{16}, K_{15}, \ldots, K_1$ (same schedule, reversed).
```

### 2.5 Solved Example — Encryption and Decryption

```{prf:example} Complete 3-Round Feistel Cipher
:label: ex-feistel-full

**Given parameters:**
- Block size: $2n = 8$ bits ($n = 4$)
- Key: $K = 1010\;1100$ (8 bits)
- Rounds: $r = 3$
- Subkeys (derived from key schedule): $K_1 = 1010$, $K_2 = 0110$, $K_3 = 1100$
- Round function: $F(R, K_i) = R \oplus K_i$ (XOR, for simplicity)
- Plaintext: $P = L_0 \| R_0 = 0011\;1010$



**ENCRYPTION**

Starting state: $L_0 = 0011$, $R_0 = 1010$

**Round 1** (subkey $K_1 = 1010$):

$$L_1 = R_0 = 1010$$
$$R_1 = L_0 \oplus F(R_0, K_1) = 0011 \oplus (1010 \oplus 1010) = 0011 \oplus 0000 = 0011$$

**Round 2** (subkey $K_2 = 0110$):

$$L_2 = R_1 = 0011$$
$$R_2 = L_1 \oplus F(R_1, K_2) = 1010 \oplus (0011 \oplus 0110) = 1010 \oplus 0101 = 1111$$

**Round 3** (subkey $K_3 = 1100$):

$$L_3 = R_2 = 1111$$
$$R_3 = L_2 \oplus F(R_2, K_3) = 0011 \oplus (1111 \oplus 1100) = 0011 \oplus 0011 = 0000$$

**Final swap:**

$$C_L = R_3 = 0000, \quad C_R = L_3 = 1111$$

**Ciphertext:** $C = R_3 \| L_3 = \mathbf{0000\;1111}$



**DECRYPTION** (exact same circuit, subkeys reversed: $K_3, K_2, K_1$)

The ciphertext $C = 0000\;1111$ is fed into the same Feistel circuit. Label its halves as the decryption starting state:

$$L_0 = C_L = 0000, \quad R_0 = C_R = 1111$$

**Round 1** (subkey $K_3 = 1100$):

$$L_1 = R_0 = 1111$$
$$R_1 = L_0 \oplus F(R_0, K_3) = 0000 \oplus (1111 \oplus 1100) = 0000 \oplus 0011 = 0011$$

**Round 2** (subkey $K_2 = 0110$):

$$L_2 = R_1 = 0011$$
$$R_2 = L_1 \oplus F(R_1, K_2) = 1111 \oplus (0011 \oplus 0110) = 1111 \oplus 0101 = 1010$$

**Round 3** (subkey $K_1 = 1010$):

$$L_3 = R_2 = 1010$$
$$R_3 = L_2 \oplus F(R_2, K_1) = 0011 \oplus (1010 \oplus 1010) = 0011 \oplus 0000 = 0011$$

**Final swap:** $P = R_3 \| L_3 = 0011 \| 1010 = \mathbf{0011\;1010}$ ✓

The original plaintext is perfectly recovered.
```

::::{question} Feistel Network Properties
:type: multiple-choice
:variant: single-select
:showanswer:

In a Feistel network, the round function $F$ does not need to be invertible. Why?
---
[x] Inversion is achieved by the XOR structure of the network itself — the same circuit decrypts when subkeys are applied in reverse order.
> Correct! $R_{i-1} = L_i$, and $L_{i-1} = R_i \oplus F(L_i, K_i)$. Since $F(L_i, K_i)$ is fully recomputable from known values, inversion never requires $F^{-1}$.
[ ] $F$ is always invertible in practice because cipher designers choose bijective functions.
> This is false — DES's S-boxes are not bijections (they map 6 bits to 4 bits).
[ ] Decryption uses a completely different algorithm, not the Feistel structure.
> False — one of Feistel's key property is that encryption and decryption use the identical logic.
[ ] The XOR in the network cancels out all outputs of $F$, making it irrelevant.
> The XOR does not cancel $F$ — it uses $F$'s output to scramble the left half.
---
::::

---

## 3. Substitution-Permutation Networks (SPN)

AES uses a different structure: the **Substitution-Permutation Network**, which directly applies invertible substitution and permutation layers to the full block.

```{prf:definition} Substitution-Permutation Network
:label: def-spn

An **SPN** with $r$ rounds applies three alternating layers to an $n$-bit block in each round:

1. **SubBytes (S-layer):** Apply a fixed invertible S-box to each byte independently — provides *confusion*
2. **Permutation / mixing (P-layer):** Rearrange and mix bytes across the block — provides *diffusion*
3. **AddRoundKey (K-layer):** XOR the block with the round subkey

Both SubBytes and the P-layer must be **invertible** (unlike in Feistel networks) so that decryption can undo each step.
```

---

## 4. Data Encryption Standard (DES)

DES was the main US federal block-cipher standard from 1977 until AES replaced it in 2001. It is no longer secure for new systems, but it remains one of the best teaching examples for understanding Feistel networks, key schedules, S-boxes, and diffusion.

```{prf:definition} DES
:label: def-des

**Data Encryption Standard (DES)** is a 64-bit Feistel-network block cipher with:

| Parameter | Value |
|:---:|:---:|
| Block size | 64 bits |
| Key size | 56 effective key bits (encoded as 64 bits with 8 parity bits) |
| Rounds | 16 |
| Round function | Expansion + S-box substitution + permutation |
| Key schedule | Generates 16 subkeys of 48 bits each |
```

```{admonition} Why DES Is Broken
:class: warning
DES's 56-bit key allows only $2^{56} \approx 72$ trillion possible keys. In 1998, the EFF built **DES Cracker** ("Deep Crack") for USD 250,000 and broke a DES key in 56 hours using exhaustive search. Today, commodity GPU clusters can break DES in **under 24 hours** for negligible cost.

The algorithm's **structure** is still considered sound — it was the small key size mandated by the US government that made it vulnerable.
```

---

### 4.1 DES Full Architecture

Standard DES always processes a **64-bit plaintext block** using a **64-bit encoded key**. Only 56 key bits are cryptographic key material; the remaining 8 bits are parity bits. The **data path** and **key path** run in parallel:

```{figure} ../figures/ch08/des_full_architecture.webp
:name: fig-des-architecture
:width: 85%
:align: center

**DES Full Architecture.** The 64-bit plaintext enters the Initial Permutation (IP); the 64-bit key enters PC-1, which drops parity bits to produce a 56-bit working key. Both paths feed into 16 Feistel rounds, each using a fresh 48-bit subkey. After the 16th round, a 32-bit swap and the Inverse Initial Permutation (IP⁻¹) yield the 64-bit ciphertext.
```

| Phase | Data path | Key path |
|:---:|:---|:---|
| **Pre-processing** | IP shuffles the 64-bit plaintext | PC-1 reduces 64-bit key to 56 bits |
| **Round $i$ (×16)** | $L_i = R_{i-1}$; $\;R_i = L_{i-1} \oplus F(R_{i-1}, K_i)$ | Shift $+$ PC-2 produces $K_i$ (48 bits) |
| **Post-processing** | 32-bit swap then IP⁻¹ yields ciphertext | — |

---

### 4.1.1 Road Map — Standard DES and Teaching Examples

The standard algorithm is the **Standard DES** column: 64-bit blocks, 56 effective key bits, and 16 Feistel rounds. The **S-DES** column is not part of the DES standard; it is a small teaching model that uses the same kind of operations on 8-bit blocks so students can compute the steps by hand.

| Step | What happens | Teaching example: S-DES | Standard DES |
|:---:|:---|:---|:---|
| **Key pre-processing** | Remove parity, permute key bits | No parity bits — all 10 key bits used; apply **P10** | 8 parity bits dropped; 56 bits permuted by **PC-1** |
| **Step 1: IP** | Scramble plaintext bits | **IP** permutes 8 bits with $[2,6,3,1,4,8,5,7]$; split → $L_0$ (4 bits) + $R_0$ (4 bits) | **IP** permutes 64 bits with 8×8 table; split → $L_0$ (32 bits) + $R_0$ (32 bits) |
| **Step 2: Key Schedule** | Generate one subkey per round | P10 → split → LS-1/LS-2 → **P8** → $K_1,K_2$ (8 bits each) | PC-1 → split → 16 shifts → **PC-2** → $K_1\ldots K_{16}$ (48 bits each) |
| **Step 3: Rounds** | Mix plaintext with key | **2 rounds**: EP (4→8 bits) → XOR → S0+S1 (8→4 bits) → P4 | **16 rounds**: E (32→48 bits) → XOR → S1–S8 (48→32 bits) → P32 |
| **Swap** | Re-order halves | Swap $L_2 \leftrightarrow R_2$ after round 2 | Swap $L_{16} \leftrightarrow R_{16}$ after round 16 |
| **Step 4: IP⁻¹** | Undo IP scrambling | **IP⁻¹** with $[4,1,3,5,7,2,8,6]$ → 8-bit ciphertext | **IP⁻¹** with 8×8 table → 64-bit ciphertext |

```{admonition} How to read §4.2-§4.6
:class: tip
Study the **standard DES** description first: this is the real 64-bit algorithm. Use the S-DES boxes only as hand-computable examples that illustrate the same kind of permutation, rotation, expansion, substitution, and Feistel update.
```

---

### 4.2 Step 1 — Initial Permutation (IP)

Before the first Feistel round, DES applies a fixed, publicly known **Initial Permutation (IP)** to the 64-bit plaintext block. IP simply reorders the bits — no XOR, no key material, no S-box. The permuted block is then split into two 32-bit halves, $L_0$ and $R_0$, which feed into the 16 rounds.

The permutation is defined by an 8×8 lookup table. Each cell is the **input bit number** whose value is placed at that output position. Read the table left-to-right, top-to-bottom for output bits 1 → 64.

| Output bits | 1st | 2nd | 3rd | 4th | 5th | 6th | 7th | 8th |
|:-----------:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **1 – 8**   | 58  | 50  | 42  | 34  | 26  | 18  | 10  |  2  |
| **9 – 16**  | 60  | 52  | 44  | 36  | 28  | 20  | 12  |  4  |
| **17 – 24** | 62  | 54  | 46  | 38  | 30  | 22  | 14  |  6  |
| **25 – 32** | 64  | 56  | 48  | 40  | 32  | 24  | 16  |  8  |
| **33 – 40** | 57  | 49  | 41  | 33  | 25  | 17  |  9  |  1  |
| **41 – 48** | 59  | 51  | 43  | 35  | 27  | 19  | 11  |  3  |
| **49 – 56** | 61  | 53  | 45  | 37  | 29  | 21  | 13  |  5  |
| **57 – 64** | 63  | 55  | 47  | 39  | 31  | 23  | 15  |  7  |

**How to read the table:** Row "1 – 8", 1st column → output bit 1 takes input bit **58**. Row "1 – 8", 2nd column → output bit 2 takes input bit **50**, and so on across all 64 output positions.

```{admonition} Worked Example — tracing IP on plaintext 123456ABCD132536
:class: seealso

> **Plaintext:** `123456ABCD132536` (hex)

---

**Step 1 — Convert hex to binary and label every bit 1 through 64**

Each hex digit = 4 bits, so two hex digits = one byte = 8 bits.

| Bit positions | 1 – 8 | 9 – 16 | 17 – 24 | 25 – 32 | 33 – 40 | 41 – 48 | 49 – 56 | 57 – 64 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Hex byte | `12` | `34` | `56` | `AB` | `CD` | `13` | `25` | `36` |
| Binary | `0001 0010` | `0011 0100` | `0101 0110` | `1010 1011` | `1100 1101` | `0001 0011` | `0010 0101` | `0011 0110` |

Write the full 64-bit string with each bit indexed:

| Position  |  1 |  2 |  3 |  4 |  5 |  6 |  7 |  8 |  9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
|:---------:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| Bit value |  0 |  0 |  0 |  1 |  0 |  0 |  1 |  0 |  0 |  0 |  1 |  1 |  0 |  1 |  0 |  0 |

| Position  | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 |
|:---------:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| Bit value |  0 |  1 |  0 |  1 |  0 |  1 |  1 |  0 |  1 |  0 |  1 |  0 |  1 |  0 |  1 |  1 |

| Position  | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 45 | 46 | 47 | 48 |
|:---------:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| Bit value |  1 |  1 |  0 |  0 |  1 |  1 |  0 |  1 |  0 |  0 |  0 |  1 |  0 |  0 |  1 |  1 |

| Position  | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 | 60 | 61 | 62 | 63 | 64 |
|:---------:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| Bit value |  0 |  0 |  1 |  0 |  0 |  1 |  0 |  1 |  0 |  0 |  1 |  1 |  0 |  1 |  1 |  0 |

---

**Step 2 — Apply the IP table: pick bits in the order the table specifies**

The IP table (row 1) says: output bits 1–8 come from input positions **58, 50, 42, 34, 26, 18, 10, 2**.
Look up each position in the numbered bit string above:

| Output bit | Takes input bit | Input bit value |
|:----------:|:---------------:|:---------------:|
| 1 | **58** | bit 58 = **0** |
| 2 | **50** | bit 50 = **0** |
| 3 | **42** | bit 42 = **0** |
| 4 | **34** | bit 34 = **1** |
| 5 | **26** | bit 26 = **0** |
| 6 | **18** | bit 18 = **1** |
| 7 | **10** | bit 10 = **0** |
| 8 |  **2** | bit  2 = **0** |

→ Output bits 1–8 = `0001 0100` = **`14` hex** ✓

Repeat the same lookup for rows 2–8 of the IP table. After all 64 output bits are filled, split at the midpoint:

$$\text{IP}(\mathtt{123456ABCD132536}) = \underbrace{\mathtt{14A7D678}}_{L_0\ (bits\ 1\text{–}32)} \;\; \underbrace{\mathtt{18CA18AD}}_{R_0\ (bits\ 33\text{–}64)}$$
```

```{figure} ../figures/ch08/des_initial_permutation.png
:name: fig-des-ip
:width: 75%
:align: center

**Initial Permutation (IP) wiring diagram.** Each line shows one input bit being routed to its output position. The upper half of outputs (1–32) form $L_0$; the lower half (33–64) form $R_0$.
```

```{admonition} Cryptographic Role of IP
:class: note
IP provides **no cryptographic security** — it is a fixed, publicly known permutation applied identically for every key. It was included in the 1977 chip design for hardware bus-alignment reasons. All security in DES derives from the S-boxes and key mixing in the 16 Feistel rounds.
```

The permuted 64-bit block is split into:
- $L_0$ = bits 1–32 of the permuted block
- $R_0$ = bits 33–64 of the permuted block

```{admonition} Teaching Analogy — IP on 8 Bits
:class: seealso

The teaching example applies the same type of operation at a smaller scale: a fixed 8-bit permutation before the first round.

$$\text{IP} = [2,\ 6,\ 3,\ 1,\ 4,\ 8,\ 5,\ 7]$$

For plaintext $P = p_1 p_2 p_3 p_4 p_5 p_6 p_7 p_8$, the output is $p_2\, p_6\, p_3\, p_1\, p_4\, p_8\, p_5\, p_7$.
The permuted 8 bits are split into: $L_0 = \text{bits }1\text{–}4$ and $R_0 = \text{bits }5\text{–}8$.

**Mini-example** — plaintext $\mathtt{11010111}$:

| Pos | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Bit | 1 | 1 | 0 | 1 | 0 | 1 | 1 | 1 |

IP picks positions $[2,6,3,1,4,8,5,7]$: bits $1,1,0,1,1,1,0,1$ → $\mathtt{11011101}$

$$L_0 = \mathtt{1101} \qquad R_0 = \mathtt{1101}$$

Same type of wiring as DES — just 8 positions instead of 64.
```

---

### 4.3 Step 2 — Key Schedule (Subkey Generation)

DES derives sixteen 48-bit subkeys $K_1, \ldots, K_{16}$ from the 64-bit master key through a sequence of permutations and circular shifts:

```{figure} ../figures/ch08/des_key_transformation.webp
:name: fig-des-key-transform
:width: 90%
:align: center

**DES Key Transformation.** PC-1 reduces the 64-bit master key to 56 bits (dropping parity), splits it into halves $C_0$ and $D_0$, and for each round applies a circular left-shift followed by PC-2 to produce a 48-bit subkey $K_i$.
```

```{figure} ../figures/ch08/des_circular_shift.png
:name: fig-des-circular-shift
:width: 85%
:align: center

**Circular Left-Shift Schedule.** Rounds 1, 2, 9, and 16 shift by 1 bit; all other rounds shift by 2 bits. The same shifted halves ($C_i$, $D_i$) are carried forward as inputs to the next round.
```

```{prf:algorithm} DES Key Schedule
:label: algo-des-keyschedule

**Input:** 64-bit master key $K$

**Output:** Subkeys $K_1, K_2, \ldots, K_{16}$, each 48 bits

1. **PC-1 (Permuted Choice 1):** Discard the 8 parity bits (positions 8, 16, 24, 32, 40, 48, 56, 64) and rearrange the remaining 56 bits into two 28-bit halves $C_0$ and $D_0$.

2. **For each round $i = 1, \ldots, 16$:**
   - Apply a **circular left-shift** of $s_i$ bits to both $C_{i-1}$ and $D_{i-1}$:

     | Rounds | 1, 2, 9, 16 | all others (3–8, 10–15) |
     |:---:|:---:|:---:|
     | Shift $s_i$ | **1 bit** | **2 bits** |

   - **PC-2 (Permuted Choice 2):** Concatenate $C_i \| D_i$ (56 bits); select and permute 48 of them to produce $K_i$.

3. **Decryption:** apply subkeys in **reverse order** $K_{16}, K_{15}, \ldots, K_1$.
```

```{admonition} What are parity bits and why are they discarded?
:class: note
**Purpose.** In the 1970s, keys were transmitted over unreliable hardware. Each byte of the 64-bit DES key has its 8th bit set so that the total number of 1s in that byte is **odd** (odd parity). This lets the receiving hardware detect a single-bit transmission error: if any byte ends up with an even number of 1s, something went wrong.

**Which bits.** Bit positions **8, 16, 24, 32, 40, 48, 56, 64** — the last bit of every byte — are the parity bits. The other 56 bits (positions 1–7, 9–15, 17–23, …) carry the actual key material.

**How to compute a parity bit.** For byte $j$ (bits $8j{-}7$ through $8j{-}1$ are the data bits), the parity bit is chosen so that:

$$b_{8j-7} \oplus b_{8j-6} \oplus b_{8j-5} \oplus b_{8j-4} \oplus b_{8j-3} \oplus b_{8j-2} \oplus b_{8j-1} \oplus p_j = 1$$

i.e. $p_j = 1 \oplus b_{8j-7} \oplus \cdots \oplus b_{8j-1}$ (XOR of the 7 data bits, flipped if needed to make the total odd). The key point is: **DES only uses 56 of the 64 bits for cryptography**; the parity bits add no entropy and are simply dropped by PC-1.
```

```{admonition} What is a circular left-shift?
:class: note
A **circular left-shift** (also called a *rotation*) moves every bit one position to the left, and the bit that falls off the left end **wraps around** to the rightmost position — nothing is lost. For a 28-bit half $C = b_1 b_2 \ldots b_{28}$, a 1-bit circular left-shift gives $C' = b_2 b_3 \ldots b_{28} b_1$. A 2-bit shift gives $C' = b_3 b_4 \ldots b_{28} b_1 b_2$. Because the total shift across all 16 rounds sums to exactly 28, the halves return to their original state after the full key schedule ($C_{16} = C_0$, $D_{16} = D_0$).
```

#### PC-1 Table — From 64 to 56 Bits

PC-1 is a **compression permutation**: it simultaneously drops all 8 parity bits and reorders the remaining 56 bits. Each cell contains the **input bit position** (from the 64-bit master key) that maps to that output position (read left-to-right, top-to-bottom for output bits 1 through 56):

Each cell is the **input** key bit number routed to that output position. Read left-to-right, top-to-bottom for output bits 1 → 56. Parity bit positions (8, 16, 24, 32, 40, 48, 56, 64) never appear — they are silently dropped.

| Output bits       | 1st | 2nd | 3rd | 4th | 5th | 6th | 7th |
|:-----------------:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **C₀: 1 – 7**    |  57 |  49 |  41 |  33 |  25 |  17 |   9 |
| **C₀: 8 – 14**   |   1 |  58 |  50 |  42 |  34 |  26 |  18 |
| **C₀: 15 – 21**  |  10 |   2 |  59 |  51 |  43 |  35 |  27 |
| **C₀: 22 – 28**  |  19 |  11 |   3 |  60 |  52 |  44 |  36 |
| **D₀: 29 – 35**  |  63 |  55 |  47 |  39 |  31 |  23 |  15 |
| **D₀: 36 – 42**  |   7 |  62 |  54 |  46 |  38 |  30 |  22 |
| **D₀: 43 – 49**  |  14 |   6 |  61 |  53 |  45 |  37 |  29 |
| **D₀: 50 – 56**  |  21 |  13 |   5 |  28 |  20 |  12 |   4 |

**How to read:** Row "C₀: 1 – 7", 1st column → output bit 1 of $C_0$ takes input bit **57**. 2nd column → output bit 2 takes input bit **49**, and so on.

```{admonition} Worked Example — Key Schedule on master key AABB09182736CCDD
:class: seealso

> **Master key:** `AABB09182736CCDD` (hex)

---

**Step 1 — Convert hex key to binary and label bits 1 through 64**

| Bit positions | 1–8 | 9–16 | 17–24 | 25–32 | 33–40 | 41–48 | 49–56 | 57–64 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Hex byte | `AA` | `BB` | `09` | `18` | `27` | `36` | `CC` | `DD` |
| Binary | `1010 1010` | `1011 1011` | `0000 1001` | `0001 1000` | `0010 0111` | `0011 0110` | `1100 1100` | `1101 1101` |

---

**Step 2 — Apply PC-1: drop parity bits, permute the remaining 56 bits, split into C₀ and D₀**

PC-1 row 1 selects positions 57, 49, 41, 33, 25, 17, 9 → those key bits become $C_0$ bits 1–7:

| $C_0$ output bit | From input bit | Bit value |
|:----------------:|:--------------:|:---------:|
| 1 | 57 (byte 8 `DD`, bit 1) | **1** |
| 2 | 49 (byte 7 `CC`, bit 1) | **1** |
| 3 | 41 (byte 6 `36`, bit 1) | **0** |
| 4 | 33 (byte 5 `27`, bit 1) | **0** |
| 5 | 25 (byte 4 `18`, bit 1) | **0** |
| 6 | 17 (byte 3 `09`, bit 1) | **0** |
| 7 |  9 (byte 2 `BB`, bit 1) | **1** |

Applying all 8 rows of PC-1 to all 56 selected bits gives:

$$C_0 = \mathtt{1111000\;1100110\;0101010\;1011101} \quad\text{(28 bits)}$$
$$D_0 = \mathtt{0101010\;1011001\;1001111\;0001111} \quad\text{(28 bits)}$$

---

**Step 3 — Round 1: circular-left-shift both halves by 1 bit, then apply PC-2**

Shift schedule says round 1 → **LS-1** (shift by 1):

$$C_1 = \text{LS-1}(C_0): \text{bit 1 wraps to position 28}$$
$$D_1 = \text{LS-1}(D_0): \text{bit 1 wraps to position 28}$$

PC-2 then picks 48 of the 56 bits from $C_1 \| D_1$:

$$\boxed{K_1 = \mathtt{194C D072 DE8C}}$$

---

**Step 4 — Repeat for rounds 2–16 with the appropriate shift amount**

| Round | Shift | Cumulative shift |
|:-----:|:-----:|:----------------:|
| 1 | 1 | 1 |
| 2 | 1 | 2 |
| 3–8 | 2 each | 14 |
| 9 | 1 | 15 |
| 10–15 | 2 each | 27 |
| 16 | 1 | **28** |

After round 16, both halves have rotated a full 28 positions → $C_{16} = C_0$, $D_{16} = D_0$. Decryption applies the same schedule but uses $K_{16}, K_{15}, \ldots, K_1$ in reverse order.
```

```{admonition} Teaching Analogy — Key Schedule on 10 Bits
:class: seealso

The teaching key schedule uses the same kind of three-stage structure at a smaller scale:

| Stage | Teaching example | Standard DES |
|:---:|:---|:---|
| **Initial permutation** | **P10** permutes all 10 key bits | **PC-1** permutes 64 bits, drops 8 parity bits, keeps 56 |
| **Split** | $C_0$ = left 5 bits, $D_0$ = right 5 bits | $C_0$ = left 28 bits, $D_0$ = right 28 bits |
| **Per-round shift** | Round 1 → LS-1; later practice rotations → LS-2 | Rounds 1,2,9,16 → LS-1; others → LS-2 |
| **Extract subkey** | **P8** selects 8 of 10 bits from $C_i\|D_i$ | **PC-2** selects 48 of 56 bits from $C_i\|D_i$ |
| **Subkey size** | 8 bits | 48 bits |
| **Number of subkeys** | 2 ($K_1$, $K_2$) | 16 ($K_1 \ldots K_{16}$) |

The complete teaching key schedule worked example is in **§4.3.2**.
```

#### 4.3.1 DES Key Schedule — Standalone Examples

Each example below is **self-contained**: it starts from a 64-bit DES key value, applies PC-1 to get $C_0$ and $D_0$, shifts the halves, then applies PC-2 to produce a round subkey. The examples are written in bit strings because DES tables operate on bit positions, not because binary notation is a separate algorithm.

**What you need to solve each example:**

| Tool | What it does |
|:---|:---|
| **PC-1 table** | Tells you which 56 of the 64 key bits to keep, and their new order. Read it like a map: cell value = input bit position, cell location = output position. |
| **Shift schedule** | Rounds 1, 2, 9, 16 → shift by **1**. All other rounds → shift by **2**. |
| **PC-2 table** | Selects 48 of the 56 bits from $C_i \| D_i$ to form the subkey $K_i$. |
| **Circular shift rule** | The bit(s) that fall off the left wrap to the right end — nothing is lost. |

---

`````{admonition} Example 1 — Round-1 subkey for DES key 0123456789ABCDEF
:class: tip

**Given master key (64 bits, written in binary, bits 1–64 left to right):**

```
Bit:  1        8  9       16 17      24 25      32
      0000 0001  0010 0011  0100 0101  0110 0111
Bit: 33       40 41      48 49      56 57      64
      1000 1001  1010 1011  1100 1101  1110 1111
```

This is the hex key `0123456789ABCDEF`.



**Step 1 — Apply PC-1: pick 56 bits, drop parity bits (positions 8,16,24,32,40,48,56,64)**

PC-1 selects these 56 positions (in this order):

$C_0$ (positions): 57 49 41 33 25 17 9 | 1 58 50 42 34 26 18 | 10 2 59 51 43 35 27 | 19 11 3 60 52 44 36

$D_0$ (positions): 63 55 47 39 31 23 15 | 7 62 54 46 38 30 22 | 14 6 61 53 45 37 29 | 21 13 5 28 20 12 4

Reading bit values from the master key above:

| $C_0$ bit | Src pos | Key bit | | $D_0$ bit | Src pos | Key bit |
|:---------:|:-------:|:-------:|-|:---------:|:-------:|:-------:|
| 1 | 57 | **1** | | 1 | 63 | **1** |
| 2 | 49 | **1** | | 2 | 55 | **1** |
| 3 | 41 | **1** | | 3 | 47 | **1** |
| 4 | 33 | **1** | | 4 | 39 | **1** |
| 5 | 25 | **0** | | 5 | 31 | **0** |
| 6 | 17 | **0** | | 6 | 23 | **0** |
| 7 | 9  | **0** | | 7 | 15 | **0** |
| 8 | 1  | **0** | | 8 | 7  | **1** |
| 9 | 58 | **1** | | 9 | 62 | **1** |
| 10 | 50 | **1** | | 10 | 54 | **1** |
| 11 | 42 | **1** | | 11 | 46 | **1** |
| 12 | 34 | **1** | | 12 | 38 | **1** |
| 13 | 26 | **0** | | 13 | 30 | **0** |
| 14 | 18 | **1** | | 14 | 22 | **0** |
| 15 | 10 | **0** | | 15 | 14 | **0** |
| 16 | 2  | **0** | | 16 | 6  | **1** |
| 17 | 59 | **1** | | 17 | 61 | **1** |
| 18 | 51 | **1** | | 18 | 53 | **1** |
| 19 | 43 | **1** | | 19 | 45 | **0** |
| 20 | 35 | **0** | | 20 | 37 | **1** |
| 21 | 27 | **1** | | 21 | 29 | **0** |
| 22 | 19 | **0** | | 22 | 21 | **0** |
| 23 | 11 | **0** | | 23 | 13 | **0** |
| 24 | 3  | **0** | | 24 | 5  | **1** |
| 25 | 60 | **1** | | 25 | 28 | **0** |
| 26 | 52 | **1** | | 26 | 20 | **1** |
| 27 | 44 | **0** | | 27 | 12 | **0** |
| 28 | 36 | **1** | | 28 | 4  | **0** |

$$C_0 = \mathtt{1111\,0000\,1111\,0010\,1110\,0001\,1001}$$
$$D_0 = \mathtt{1111\,0001\,1110\,0110\,1000\,1011\,0100}$$



**Step 2 (Round 1) — Circular left-shift by 1 bit:**

$$C_1 = \mathtt{1110\,0001\,1110\,0101\,1100\,0011\,0011} \quad\text{(leftmost bit 1 moves to position 28)}$$
$$D_1 = \mathtt{1110\,0011\,1100\,1101\,0001\,0110\,1001}$$



**Step 3 (Round 1) — Apply PC-2: select 48 of the 56 bits of $C_1 \| D_1$:**

PC-2 positions (from combined 56-bit string $C_1\|D_1$, where $C_1$ = positions 1–28, $D_1$ = positions 29–56):

`14 17 11 24 1 5 | 3 28 15 6 21 10 | 23 19 12 4 26 8 | 16 7 27 20 13 2`
`41 52 31 37 47 55 | 30 40 51 45 33 48 | 44 49 39 56 34 53 | 46 42 50 36 29 32`

$$\boxed{K_1 = \mathtt{0001\,1011\,0000\,0010\,0110\,0111\,1001\,1011\,0100\,1001\,1010\,0101} = \mathtt{1B02674B94A5}}$$
`````

---

`````{admonition} Example 2 — Pattern key with all selected bits equal to 1
:class: tip

**Given teaching key pattern:** all 64 displayed bits are `1` (hex `FFFFFFFFFFFFFFFF`). This is used only to show how PC-1, rotation, and PC-2 behave when every selected bit is the same.



**Step 1 — Apply PC-1 (drop parity bits, select 56):**

Every selected bit is `1`, so:

$$C_0 = \mathtt{1111\,1111\,1111\,1111\,1111\,1111\,1111} \quad\text{(28 ones)}$$
$$D_0 = \mathtt{1111\,1111\,1111\,1111\,1111\,1111\,1111} \quad\text{(28 ones)}$$



**Step 2 (Round 1) — Circular left-shift by 1 bit:**

All bits are 1, so rotating changes nothing:

$$C_1 = \mathtt{1111\,1111\,1111\,1111\,1111\,1111\,1111}$$
$$D_1 = \mathtt{1111\,1111\,1111\,1111\,1111\,1111\,1111}$$



**Step 3 (Round 1) — Apply PC-2:**

Every selected bit is `1`, so:

$$\boxed{K_1 = \mathtt{1111\,1111\,1111\,1111\,1111\,1111\,1111\,1111\,1111\,1111\,1111\,1111} = \mathtt{FFFFFFFFFFFF}}$$

**Round 2 — Shift by 1 again:** still all 1s → $K_2 = \mathtt{FFFFFFFFFFFF}$

**Round 3 — Shift by 2:** still all 1s → $K_3 = \mathtt{FFFFFFFFFFFF}$

> **Insight:** If the selected key bits are all identical, every subkey is identical. Real DES has known weak-key classes, and secure systems avoid DES entirely rather than trying to manage those edge cases.
`````

---

`````{admonition} Example 3 — Pattern key with all selected bits equal to 0
:class: tip

**Given teaching key pattern:** all 64 displayed bits are `0` (hex `0000000000000000`). This is a simple pattern example; in formal DES key encodings, parity bits are normally set to odd parity.



**Step 1 — Apply PC-1:**

Every selected bit is `0`:

$$C_0 = \mathtt{0000\,0000\,0000\,0000\,0000\,0000\,0000}$$
$$D_0 = \mathtt{0000\,0000\,0000\,0000\,0000\,0000\,0000}$$



**Step 2 (Round 1) — Circular left-shift by 1 bit:**

Rotating all zeros gives all zeros:

$$C_1 = \mathtt{0000\,0000\,0000\,0000\,0000\,0000\,0000}$$
$$D_1 = \mathtt{0000\,0000\,0000\,0000\,0000\,0000\,0000}$$



**Step 3 (Round 1) — Apply PC-2:**

Every selected bit is `0`:

$$\boxed{K_1 = \mathtt{0000\,0000\,0000\,0000\,0000\,0000\,0000\,0000\,0000\,0000\,0000\,0000} = \mathtt{000000000000}}$$

**Round 2 and Round 3:** identical — all-zero subkeys for every round.

> **Insight:** If the selected key bits are all zero, all round subkeys are zero. This illustrates why repeated or low-diversity subkeys are undesirable. Modern practice is to use AES, not DES.
`````

---

#### 4.3.2 Teaching Example: Simplified DES Key Schedule

**Simplified DES (S-DES)** is a teaching cipher, not the DES standard. It mirrors the *shape* of the DES key schedule but operates on a **10-bit master key** and produces **8-bit subkeys**. Use it to learn the steps by hand, then map the same ideas back to standard DES: PC-1, split, rotate, PC-2.

**Teaching key schedule parameters:**

| Item | Value |
|:---|:---|
| Master key | 10 bits, labelled $k_1 k_2 \ldots k_{10}$ (left = most significant) |
| **P10** | Initial permutation of all 10 key bits |
| **Split** | Left half $C_0$ = bits 1–5; Right half $D_0$ = bits 6–10 |
| **Shift schedule used here** | Round 1 → LS-1 (rotate left by **1**); later practice rotations → LS-2 (rotate left by **2**) |
| **P8** | Selects 8 of the 10 bits from $C_i \| D_i$ to form each 8-bit subkey |

**Fixed permutation tables used in every teaching example:**

$$\text{P10:} \quad [3,\ 5,\ 2,\ 7,\ 4,\ 10,\ 1,\ 9,\ 8,\ 6]$$

Read as: output bit 1 = input bit 3, output bit 2 = input bit 5, …, output bit 10 = input bit 6.

$$\text{P8:} \quad [6,\ 3,\ 7,\ 4,\ 8,\ 5,\ 10,\ 9]$$

Read as: output bit 1 = position 6 of $C_i\|D_i$, output bit 2 = position 3, …, output bit 8 = position 9.

**Circular left-shift reminder:** For a 5-bit register $b_1 b_2 b_3 b_4 b_5$,
- LS-1 gives $b_2 b_3 b_4 b_5 b_1$
- LS-2 gives $b_3 b_4 b_5 b_1 b_2$

Nothing is discarded — bits wrap around from the left end to the right end.

**How $C$ and $D$ fit into the teaching key schedule:**

```{figure} ../figures/ch08/sdes_key_schedule.svg
:name: fig-sdes-key-schedule
:width: 85%
:align: center

**S-DES Key Schedule.** The 10-bit teaching key is permuted by P10 and split into left half $C_0$ (bits 1–5) and right half $D_0$ (bits 6–10). Each half is independently rotated. After each rotation, the two halves are concatenated as $C_i \| D_i$ and P8 selects 8 of the 10 bits to form a teaching subkey $K_i$.
```

```{admonition} $C$ and $D$ — Why two separate halves?
:class: note

After P10 the 10 permuted bits are cut exactly in the middle:

$$\underbrace{b_1\ b_2\ b_3\ b_4\ b_5}_{C_i\ \text{(left 5 bits)}}\ \Big|\ \underbrace{b_6\ b_7\ b_8\ b_9\ b_{10}}_{D_i\ \text{(right 5 bits)}}$$

Each half **rotates independently** — $C_i$ wraps only within its own 5-bit window, and so does $D_i$. This keeps the two halves from influencing each other during shifting, which is what produces a *different* key mixture each round.

Only at the very end of each round are they **joined back** ($C_i \| D_i$, giving a 10-bit string) so that P8 can pick any 8 of those 10 positions to form the subkey.

| Symbol | Meaning | Width |
|:---:|:---|:---:|
| $C_0$ | Left half of key bits **before** any round | 5 bits |
| $D_0$ | Right half of key bits **before** any round | 5 bits |
| $C_i$ | Left half **after** round $i$'s shift | 5 bits |
| $D_i$ | Right half **after** round $i$'s shift | 5 bits |
| $C_i \| D_i$ | Concatenation fed into P8 | 10 bits |
| $K_i$ | Subkey output of P8 for round $i$ | 8 bits |

The same $C/D$ naming convention appears in standard DES, where each half is **28 bits** wide.
```

---

`````{admonition} Example 4 — S-DES style key schedule: master key 1010000010
:class: tip

The first two subkeys, $K_1$ and $K_2$, are the ones used in the complete S-DES encryption example in §4.6.1. The third rotation is included only to show how circular shifts continue and how the halves return after a full cycle.

**Given master key (10 bits, positions 1–10 left to right):**

$$k = \mathtt{1010000010}$$

| Pos | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Bit | **1** | **0** | **1** | **0** | **0** | **0** | **0** | **0** | **1** | **0** |



**Step 1 — Apply P10: reorder all 10 key bits**

P10 = $[3,5,2,7,4,10,1,9,8,6]$

| Output pos | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Src pos | 3 | 5 | 2 | 7 | 4 | 10 | 1 | 9 | 8 | 6 |
| Bit value | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 0 | 0 |

After P10: $\mathtt{1000001100}$

$$C_0 = \mathtt{10000} \qquad D_0 = \mathtt{01100}$$



**Step 2 (Round 1) — LS-1: rotate each half left by 1**

$$C_1 = \text{LS-1}(\mathtt{10000}) = \mathtt{00001} \quad \text{(the leading 1 wraps to position 5)}$$
$$D_1 = \text{LS-1}(\mathtt{01100}) = \mathtt{11000} \quad \text{(the leading 0 wraps to position 5)}$$

Combined: $C_1 \| D_1 = \mathtt{0000111000}$

| Pos in $C_1\|D_1$ | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Bit | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |

Apply P8 = $[6,3,7,4,8,5,10,9]$:

| $K_1$ bit | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Src pos | 6 | 3 | 7 | 4 | 8 | 5 | 10 | 9 |
| Bit value | 1 | 0 | 1 | 0 | 0 | 1 | 0 | 0 |

$$\boxed{K_1 = \mathtt{10100100}}$$



**Step 3 (Round 2) — LS-2: rotate $C_1$, $D_1$ left by 2**

$$C_2 = \text{LS-2}(\mathtt{00001}) = \mathtt{00100} \quad \text{(bits } b_3 b_4 b_5 b_1 b_2 \text{)}$$
$$D_2 = \text{LS-2}(\mathtt{11000}) = \mathtt{00011}$$

Combined: $C_2 \| D_2 = \mathtt{0010000011}$

| Pos in $C_2\|D_2$ | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Bit | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 1 |

Apply P8 = $[6,3,7,4,8,5,10,9]$:

| $K_2$ bit | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Src pos | 6 | 3 | 7 | 4 | 8 | 5 | 10 | 9 |
| Bit value | 0 | 1 | 0 | 0 | 0 | 0 | 1 | 1 |

$$\boxed{K_2 = \mathtt{01000011}}$$



**Step 4 (Round 3) — LS-2: rotate $C_2$, $D_2$ left by 2**

$$C_3 = \text{LS-2}(\mathtt{00100}) = \mathtt{10000}$$
$$D_3 = \text{LS-2}(\mathtt{00011}) = \mathtt{01100}$$

Combined: $C_3 \| D_3 = \mathtt{1000001100}$

| Pos in $C_3\|D_3$ | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Bit | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 0 | 0 |

Apply P8 = $[6,3,7,4,8,5,10,9]$:

| $K_3$ bit | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Src pos | 6 | 3 | 7 | 4 | 8 | 5 | 10 | 9 |
| Bit value | 0 | 0 | 1 | 0 | 1 | 0 | 0 | 0 |

$$\boxed{K_3 = \mathtt{00101000}}$$



**Summary:**

| Subkey | 8-bit value | C half before P8 | D half before P8 |
|:---:|:---:|:---:|:---:|
| $K_1$ | $\mathtt{10100100}$ | $C_1 = \mathtt{00001}$ | $D_1 = \mathtt{11000}$ |
| $K_2$ | $\mathtt{01000011}$ | $C_2 = \mathtt{00100}$ | $D_2 = \mathtt{00011}$ |
| $K_3$ | $\mathtt{00101000}$ | $C_3 = \mathtt{10000}$ | $D_3 = \mathtt{01100}$ |

> **Observation:** After round 3 the halves have returned to $C_0, D_0$ (total rotation = $1+2+2 = 5$ bits, and the register width is 5 bits — a full cycle). This mirrors the standard DES property where the total 16-round shift is 28 positions, so $C_{16} = C_0$ and $D_{16} = D_0$.
`````

---

`````{admonition} Practice Problem — S-DES style key schedule
:class: seealso

**Given master key (10 bits):**

$$k = \mathtt{1100011010}$$

**Permutation tables (same as the worked example):**

$$\text{P10} = [3,5,2,7,4,10,1,9,8,6] \qquad \text{P8} = [6,3,7,4,8,5,10,9]$$

**Shift schedule:** Round 1 → LS-1, Rounds 2 & 3 → LS-2.

Using the four-step procedure above, find $K_1$, $K_2$, and the optional practice value $K_3$.

```{admonition} Solution
:class: dropdown

**Step 1 — Apply P10 to master key $\mathtt{1100011010}$:**

Key bits: pos 1=1, 2=1, 3=0, 4=0, 5=0, 6=1, 7=1, 8=0, 9=1, 10=0

P10 = $[3,5,2,7,4,10,1,9,8,6]$ → reads out bits: 0, 0, 1, 1, 0, 0, 1, 1, 0, 1

After P10: $\mathtt{0011001101}$

$$C_0 = \mathtt{00110} \qquad D_0 = \mathtt{01101}$$



**Round 1 — LS-1:**

$$C_1 = \text{LS-1}(\mathtt{00110}) = \mathtt{01100}$$
$$D_1 = \text{LS-1}(\mathtt{01101}) = \mathtt{11010}$$

$C_1\|D_1 = \mathtt{0110011010}$ (pos: 1=0, 2=1, 3=1, 4=0, 5=0, 6=1, 7=1, 8=0, 9=1, 10=0)

P8 $[6,3,7,4,8,5,10,9]$: picks bits at positions 6,3,7,4,8,5,10,9 → 1, 1, 1, 0, 0, 0, 0, 1

$$\boxed{K_1 = \mathtt{11100001}}$$



**Round 2 — LS-2 from $C_1, D_1$:**

$$C_2 = \text{LS-2}(\mathtt{01100}) = \mathtt{10001}$$
$$D_2 = \text{LS-2}(\mathtt{11010}) = \mathtt{01011}$$

$C_2\|D_2 = \mathtt{1000101011}$ (pos: 1=1, 2=0, 3=0, 4=0, 5=1, 6=0, 7=1, 8=0, 9=1, 10=1)

P8 $[6,3,7,4,8,5,10,9]$: picks 0, 0, 1, 0, 0, 1, 1, 1

$$\boxed{K_2 = \mathtt{00100111}}$$



**Round 3 — LS-2 from $C_2, D_2$:**

$$C_3 = \text{LS-2}(\mathtt{10001}) = \mathtt{00110}$$
$$D_3 = \text{LS-2}(\mathtt{01011}) = \mathtt{01101}$$

$C_3\|D_3 = \mathtt{0011001101}$ (pos: 1=0, 2=0, 3=1, 4=1, 5=0, 6=0, 7=1, 8=1, 9=0, 10=1)

P8 $[6,3,7,4,8,5,10,9]$: picks 0, 1, 1, 1, 1, 0, 1, 0

$$\boxed{K_3 = \mathtt{01111010}}$$



**Final answer:**

| Subkey | Value |
|:---:|:---:|
| $K_1$ | $\mathtt{11100001}$ |
| $K_2$ | $\mathtt{00100111}$ |
| $K_3$ | $\mathtt{01111010}$ |
```
`````

---

### 4.4 Step 3 — The Feistel Round Function

```{admonition} Teaching Analogy — Round Function on 4-bit Halves
:class: seealso

The S-DES round function uses DES-like sub-steps on smaller teaching data. It is smaller than real DES, but it helps students see the order of operations without 32-bit and 48-bit tables:

| Sub-step | Teaching example | Standard DES |
|:---:|:---|:---|
| **① Expand** | **EP**: $R$ (4 bits) → 8 bits via $[4,1,2,3,2,3,4,1]$ | **E-box**: $R$ (32 bits) → 48 bits |
| **② XOR key** | 8-bit EP output ⊕ 8-bit subkey | 48-bit expansion ⊕ 48-bit subkey |
| **③ Substitute** | Left 4 bits → **S0** (→ 2 bits); Right 4 bits → **S1** (→ 2 bits); combine → 4 bits | Eight 6-bit chunks → **S1–S8** (4 bits each); combine → 32 bits |
| **④ Permute** | **P4**: permute 4 bits with $[2,4,3,1]$ | **P32**: permute 32 bits with fixed table |

**S-DES S0 and S1 tables** (row = outer bits $b_1 b_4$, col = inner bits $b_2 b_3$; values in decimal → convert to 2-bit binary):

| Row \ Col | **S0** 00 | **S0** 01 | **S0** 10 | **S0** 11 | | **S1** 00 | **S1** 01 | **S1** 10 | **S1** 11 |
|:---:|:---:|:---:|:---:|:---:|-|:---:|:---:|:---:|:---:|
| **00** | 1 | 0 | 3 | 2 | | 0 | 1 | 2 | 3 |
| **01** | 3 | 2 | 1 | 0 | | 2 | 0 | 1 | 3 |
| **10** | 0 | 2 | 1 | 3 | | 3 | 0 | 1 | 0 |
| **11** | 3 | 1 | 3 | 2 | | 2 | 1 | 0 | 3 |

**S-DES S-box indexing rule:** for a 4-bit input $b_1 b_2 b_3 b_4$: $\text{row} = (b_1 b_4)_2$, $\text{col} = (b_2 b_3)_2$.
```

The round function $F(R_{i-1}, K_i)$ transforms the 32-bit right half using four internal steps:

```{figure} ../figures/ch08/des_single_round.webp
:name: fig-des-single-round
:width: 75%
:align: center

**Single Feistel Round in DES.** The 32-bit right half $R_{i-1}$ is expanded to 48 bits, XORed with the 48-bit subkey $K_i$, split into eight 6-bit chunks for S-box substitution (producing 32 bits), and then permuted by the P-box. The result is XORed with $L_{i-1}$ to form $R_i$; the old $R_{i-1}$ becomes $L_i$.
```

```{figure} ../figures/ch08/des_all_rounds.webp
:name: fig-des-all-rounds
:width: 95%
:align: center

**All 16 Rounds — Round Function and Key Transformation Together.** The left column shows the parallel key schedule producing $K_1, \ldots, K_{16}$; the right column shows the Feistel data path. Each round consumes one subkey and swaps the left and right halves.
```

**① Expansion (E-box):** The 32-bit $R_{i-1}$ is expanded to 48 bits by duplicating 16 boundary bits so that adjacent S-box inputs overlap. This creates **cross-S-box diffusion** — a 1-bit change in $R_{i-1}$ affects two S-box inputs simultaneously.

**② XOR with $K_i$:** The 48-bit expanded block is XORed with the 48-bit subkey — the primary **key-mixing** step that makes DES key-dependent.

**③ S-box Substitution:** The 48-bit XOR result is split into eight 6-bit chunks. Each chunk enters a different **S-box** (S1–S8), a fixed 4-row × 16-column lookup table that maps 6 input bits to 4 output bits. This is DES's main source of **confusion** and non-linearity.

```{figure} ../figures/ch08/des_sbox.webp
:name: fig-des-sbox
:width: 80%
:align: center

**S-box Structure.** For each 6-bit input the outer two bits select the row (0–3) and the inner four bits select the column (0–15). The cell value — written as a 4-bit number — is the S-box output, reducing the 48-bit block to 32 bits overall.
```

```{admonition} How to Use an S-box
:class: note
For a 6-bit input $b_1 b_2 b_3 b_4 b_5 b_6$:

$$\text{row} = (b_1 \, b_6)_2, \qquad \text{col} = (b_2 \, b_3 \, b_4 \, b_5)_2$$

- **Row (0–3):** the two *outer* bits $b_1$ and $b_6$, read as a 2-bit integer
- **Column (0–15):** the four *inner* bits $b_2 b_3 b_4 b_5$, read as a 4-bit integer
- **Output:** 4-bit value at S$_j$[row][col]

**DES S-box S1 — the full 4 × 16 lookup table (values are decimal, each represents 4 bits):**

| Row \ Col | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **0** | 14 | 4 | 13 | 1 | 2 | 15 | 11 | 8 | 3 | 10 | 6 | 12 | 5 | 9 | 0 | 7 |
| **1** | 0 | 15 | 7 | 4 | 14 | 2 | 13 | 1 | 10 | 6 | 12 | 11 | 9 | 5 | 3 | 8 |
| **2** | 4 | 1 | 14 | 8 | 13 | 6 | 2 | 11 | 15 | 12 | 9 | 7 | 3 | 10 | 5 | 0 |
| **3** | 15 | 12 | 8 | 2 | 4 | 9 | 1 | 7 | 5 | 11 | 3 | 14 | 10 | 0 | 6 | 13 |

*Example using S1 and input* `101010`:

| Outer bits $b_1 b_6$ | Inner bits $b_2 b_3 b_4 b_5$ | Row | Col | S1 value | 4-bit output |
|:---:|:---:|:---:|:---:|:---:|:---:|
| $\mathtt{1},\,\mathtt{0}$ | $\mathtt{0101}$ | 2 | 5 | **6** | `0110` |

*Reading from the table:* row 2, column 5 → value **6** → binary `0110`. ✓
```

**④ P-box Permutation:** The concatenated 32-bit S-box output is rearranged by a fixed P-box table. This spreads each S-box's output bits across multiple S-box inputs in the **next** round, achieving **diffusion** across the block.

```{admonition} Worked Example — Completing Round 1
:class: tip

Picking up from §4.2 ($L_0 = \mathtt{14A7D678}$, $R_0 = \mathtt{18CA18AD}$) and §4.3 ($K_1 = \mathtt{194CD072DE8C}$):

| Sub-step | Input | Output |
|:---|:---|:---:|
| **① E-box** — expand $R_0$ from 32 to 48 bits | `18CA18AD` | 48-bit expanded block |
| **② XOR** with $K_1$ — split into 8 × 6-bit chunks | $E(R_0) \oplus K_1$ | `101010` · `010001` · `011110` · `111010` · `100001` · `100110` · `010100` · `100111` |
| **③ S-boxes** S1–S8, one chunk each | 8 × 6 bits in | 8 × 4 bits = 32-bit S-box result |
| **④ P-box** — fixed 32-bit permutation | 32-bit S output | $F(R_0, K_1) = \mathtt{4EDF35EC}$ |

Detail for the first chunk $c_1 = \mathtt{101010}$ entering **S1**: outer bits $b_1 b_6 = (1,0)_2 = 2$ → row 2; inner bits $b_2 b_3 b_4 b_5 = 0101_2 = 5$ → column 5; S1[2][5] = **6** → `0110`.

**Feistel update — Round 1 output:**

$$\boxed{L_1 = R_0 = \mathtt{18CA18AD}}$$

$$\boxed{R_1 = L_0 \oplus F(R_0,\,K_1) = \mathtt{14A7D678} \oplus \mathtt{4EDF35EC} = \mathtt{5A78E394}}$$
```

---

### 4.5 Step 4 — Final Permutation (IP⁻¹)

After 16 rounds, the two 32-bit halves are **swapped** — concatenated as $R_{16} \| L_{16}$ — and then passed through the **Inverse Initial Permutation**:

$$\text{Ciphertext} = \text{IP}^{-1}(R_{16} \; \| \; L_{16})$$

IP⁻¹ is defined so that $\text{IP}^{-1}(\text{IP}(x)) = x$ for all $x$. Like IP, it provides zero cryptographic security and exists solely for hardware symmetry.

```{admonition} Why the 32-Bit Swap Enables Symmetric Decryption
:class: tip
Without the swap before IP⁻¹, the last round would be asymmetric and DES would need separate encrypt/decrypt circuits. The swap makes decryption identical to encryption: feed ciphertext through IP, run the same 16 Feistel rounds with subkeys in **reverse** order $K_{16}, \ldots, K_1$, swap, then apply IP⁻¹ — the same hardware decrypts.
```

---

### 4.6 Solved Examples — Teaching Model and Standard DES

::::{question} DES S-box Lookup
:type: multiple-choice
:variant: single-select
:showanswer:

A 6-bit input `011011` is fed into S-box **S1**. What are the row and column used to look up the output?
---
[ ] Row = 0, Column = 11
> The row is formed from the *outer* bits $b_1$ and $b_6$, not $b_1$ alone. Re-read the indexing rule.
[x] Row = 1, Column = 13
> Correct! Outer bits: $b_1 b_6 = (0,1)_2 = 1$. Inner bits: $b_2 b_3 b_4 b_5 = (1101)_2 = 13$. Looking up S1[1][13] = 5, so the 4-bit output is `0101`.
[ ] Row = 3, Column = 6
> Row uses $b_1$ and $b_6$ (the first and last bits), not $b_5$ and $b_6$.
[ ] Row = 1, Column = 6
> The column index uses the four *inner* bits $b_2 b_3 b_4 b_5 = 1101_2 = 13$, not only the lower nibble.
---
::::

---

### 4.6.1 Teaching Example — Complete S-DES Encryption

This example chains the same style of steps used by DES into one small end-to-end encryption. It is **not** a DES-standard encryption; it is a hand-computable teaching model that prepares you for the full 64-bit DES round trace in §4.6.2.

**Given:**
- Master key: $K = \mathtt{1010000010}$
- Plaintext: $P = \mathtt{11010111}$
- Subkeys (from §4.3.2): $K_1 = \mathtt{10100100}$, $K_2 = \mathtt{01000011}$
- IP $= [2,6,3,1,4,8,5,7]$, IP⁻¹ $= [4,1,3,5,7,2,8,6]$, EP $= [4,1,2,3,2,3,4,1]$, P4 $= [2,4,3,1]$

```{admonition} Quick Reference — S0 and S1 Lookup Tables
:class: note

**Indexing rule:** for a 4-bit input $b_1 b_2 b_3 b_4$: row $= (b_1 b_4)_2$, col $= (b_2 b_3)_2$. Output is a decimal value — convert to 2-bit binary.

| Row \ Col | **S0** 00 | **S0** 01 | **S0** 10 | **S0** 11 | | **S1** 00 | **S1** 01 | **S1** 10 | **S1** 11 |
|:---:|:---:|:---:|:---:|:---:|-|:---:|:---:|:---:|:---:|
| **00** | 1 | 0 | 3 | 2 | | 0 | 1 | 2 | 3 |
| **01** | 3 | 2 | 1 | 0 | | 2 | 0 | 1 | 3 |
| **10** | 0 | 2 | 1 | 3 | | 3 | 0 | 1 | 0 |
| **11** | 3 | 1 | 3 | 2 | | 2 | 1 | 0 | 3 |
```

---

`````{admonition} Step 1 — Apply IP to plaintext
:class: tip

$$P = \mathtt{1\ 1\ 0\ 1\ 0\ 1\ 1\ 1} \quad (\text{positions } 1\text{–}8)$$

IP $= [2,6,3,1,4,8,5,7]$ picks bits at those positions:

| Output pos | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Src pos | 2 | 6 | 3 | 1 | 4 | 8 | 5 | 7 |
| Bit value | **1** | **1** | **0** | **1** | **1** | **1** | **0** | **1** |

$$\text{IP}(P) = \mathtt{11011101}$$

$$\boxed{L_0 = \mathtt{1101} \qquad R_0 = \mathtt{1101}}$$
`````

---

`````{admonition} Step 2 — Round 1: compute $F(R_0, K_1)$ then update halves
:class: tip

**① Expand $R_0 = \mathtt{1101}$ using EP $= [4,1,2,3,2,3,4,1]$:**

| Output pos | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Src pos | 4 | 1 | 2 | 3 | 2 | 3 | 4 | 1 |
| Bit value | 1 | 1 | 1 | 0 | 1 | 0 | 1 | 1 |

$$\text{EP}(R_0) = \mathtt{11101011}$$

**② XOR with $K_1 = \mathtt{10100100}$:**

$$\mathtt{11101011} \oplus \mathtt{10100100} = \mathtt{01001111}$$

**③ S-box substitution — split into two 4-bit halves:**

| Half | Bits | $b_1$ | $b_2$ | $b_3$ | $b_4$ | Row $(b_1 b_4)_2$ | Col $(b_2 b_3)_2$ | Table value | 2-bit output |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Left → S0 | $\mathtt{0100}$ | 0 | 1 | 0 | 0 | 00=0 | 10=2 | S0[0][2] = **3** | $\mathtt{11}$ |
| Right → S1 | $\mathtt{1111}$ | 1 | 1 | 1 | 1 | 11=3 | 11=3 | S1[3][3] = **3** | $\mathtt{11}$ |

Combined S-box output: $\mathtt{1111}$

**④ Permute with P4 $= [2,4,3,1]$:**

$$\text{P4}(\mathtt{1111}): \text{pos }1{\leftarrow}b_2{=}1,\ \text{pos }2{\leftarrow}b_4{=}1,\ \text{pos }3{\leftarrow}b_3{=}1,\ \text{pos }4{\leftarrow}b_1{=}1$$

$$\boxed{F(R_0, K_1) = \mathtt{1111}}$$

**Feistel update:**

$$L_1 = R_0 = \mathtt{1101}$$
$$R_1 = L_0 \oplus F(R_0, K_1) = \mathtt{1101} \oplus \mathtt{1111} = \mathtt{0010}$$
`````

---

`````{admonition} Step 3 — Round 2: compute $F(R_1, K_2)$ then update halves
:class: tip

**① Expand $R_1 = \mathtt{0010}$ using EP $= [4,1,2,3,2,3,4,1]$:**

| Output pos | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Src pos | 4 | 1 | 2 | 3 | 2 | 3 | 4 | 1 |
| Bit value | 0 | 0 | 0 | 1 | 0 | 1 | 0 | 0 |

$$\text{EP}(R_1) = \mathtt{00010100}$$

**② XOR with $K_2 = \mathtt{01000011}$:**

$$\mathtt{00010100} \oplus \mathtt{01000011} = \mathtt{01010111}$$

**③ S-box substitution — split into two 4-bit halves:**

| Half | Bits | $b_1$ | $b_2$ | $b_3$ | $b_4$ | Row $(b_1 b_4)_2$ | Col $(b_2 b_3)_2$ | Table value | 2-bit output |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Left → S0 | $\mathtt{0101}$ | 0 | 1 | 0 | 1 | 01=1 | 10=2 | S0[1][2] = **1** | $\mathtt{01}$ |
| Right → S1 | $\mathtt{0111}$ | 0 | 1 | 1 | 1 | 01=1 | 11=3 | S1[1][3] = **3** | $\mathtt{11}$ |

Combined S-box output: $\mathtt{0111}$

**④ Permute with P4 $= [2,4,3,1]$:**

$$\text{P4}(\mathtt{0111}): \text{pos }1{\leftarrow}b_2{=}1,\ \text{pos }2{\leftarrow}b_4{=}1,\ \text{pos }3{\leftarrow}b_3{=}1,\ \text{pos }4{\leftarrow}b_1{=}0$$

$$\boxed{F(R_1, K_2) = \mathtt{1110}}$$

**Feistel update:**

$$L_2 = R_1 = \mathtt{0010}$$
$$R_2 = L_1 \oplus F(R_1, K_2) = \mathtt{1101} \oplus \mathtt{1110} = \mathtt{0011}$$
`````

---

`````{admonition} Step 4 — Swap halves then apply IP⁻¹
:class: tip

**Swap $L_2 \leftrightarrow R_2$:** concatenate $R_2 \| L_2 = \mathtt{0011\,0010}$

**Apply IP⁻¹ $= [4,1,3,5,7,2,8,6]$** to $\mathtt{00110010}$:

| Input pos | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Input bit | 0 | 0 | 1 | 1 | 0 | 0 | 1 | 0 |

| Output pos | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Src pos | 4 | 1 | 3 | 5 | 7 | 2 | 8 | 6 |
| Bit value | **1** | **0** | **1** | **0** | **1** | **0** | **0** | **0** |

$$\boxed{\text{Ciphertext} = \mathtt{10101000}}$$
`````

---

**Complete S-DES encryption trace — all steps at a glance:**

| Step | Operation | Input | Output |
|:---|:---:|:---:|:---:|
| IP | Permute plaintext | $\mathtt{11010111}$ | $L_0{=}\mathtt{1101},\ R_0{=}\mathtt{1101}$ |
| Rnd 1 EP | Expand $R_0$ | $\mathtt{1101}$ | $\mathtt{11101011}$ |
| Rnd 1 XOR $K_1$ | Key mixing | $\cdot \oplus \mathtt{10100100}$ | $\mathtt{01001111}$ |
| Rnd 1 S0+S1 | Substitute | $\mathtt{0100},\mathtt{1111}$ | $\mathtt{11,11}\to\mathtt{1111}$ |
| Rnd 1 P4 | Permute | $\mathtt{1111}$ | $F{=}\mathtt{1111}$ |
| Rnd 1 update | Feistel | $L_0,R_0$ | $L_1{=}\mathtt{1101},\ R_1{=}\mathtt{0010}$ |
| Rnd 2 EP | Expand $R_1$ | $\mathtt{0010}$ | $\mathtt{00010100}$ |
| Rnd 2 XOR $K_2$ | Key mixing | $\cdot \oplus \mathtt{01000011}$ | $\mathtt{01010111}$ |
| Rnd 2 S0+S1 | Substitute | $\mathtt{0101},\mathtt{0111}$ | $\mathtt{01,11}\to\mathtt{0111}$ |
| Rnd 2 P4 | Permute | $\mathtt{0111}$ | $F{=}\mathtt{1110}$ |
| Rnd 2 update | Feistel | $L_1,R_1$ | $L_2{=}\mathtt{0010},\ R_2{=}\mathtt{0011}$ |
| Swap | $R_2\|L_2$ | $L_2,R_2$ | $\mathtt{00110010}$ |
| IP⁻¹ | Final permutation | $\mathtt{00110010}$ | $\mathtt{10101000}$ |

> **Key:** $K{=}\mathtt{1010000010}$ · **Plaintext:** $\mathtt{11010111}$ · **Ciphertext:** $\boxed{\mathtt{10101000}}$

---

### 4.6.2 Standard DES Round 1 — Numerical Trace (64-bit)

The table below traces every intermediate value through **Round 1** of standard DES on the running 64-bit example. Rounds 2–16 repeat identically with subkeys $K_2,\ldots,K_{16}$.

**Given:** Plaintext `123456ABCD132536` (hex) · Key `AABB09182736CCDD` (hex)

| Step | § | Operation | Value |
|:-----|:-:|:----------|------:|
| Input plaintext | — | given | `123456ABCD132536` |
| After **IP** | 4.2 | 64-bit permutation | `14A7D67818CA18AD` |
| $L_0$ (bits 1–32) | 4.2 | left split | `14A7D678` |
| $R_0$ (bits 33–64) | 4.2 | right split | `18CA18AD` |
| $K_1$ | 4.3 | PC-1 → 1-bit shift → PC-2 | `194CD072DE8C` |
| $E(R_0) \oplus K_1$ | 4.4-② | expand then XOR | `101010 010001 011110 111010` / `100001 100110 010100 100111` |
| $F(R_0, K_1)$ | 4.4-③④ | S-boxes S1–S8, then P-box | `4EDF35EC` |
| $L_1 = R_0$ | 4.4 | Feistel left update | `18CA18AD` |
| $R_1 = L_0 \oplus F$ | 4.4 | $\mathtt{14A7D678} \oplus \mathtt{4EDF35EC}$ | `5A78E394` |

```{admonition} Teaching Model vs Standard DES — Same Structure, Different Scale
:class: note

| | Teaching round (§4.6.1) | Standard DES round (above) |
|:---|:---:|:---:|
| Block/half size | 8 / 4 bits | 64 / 32 bits |
| Expansion output | 8 bits | 48 bits |
| Subkey size | 8 bits | 48 bits |
| S-boxes | S0 + S1 (2-bit out each) | S1–S8 (4-bit out each) |
| Feistel formula | $L_1{=}R_0,\ R_1{=}L_0{\oplus}F$ | identical |
```

---

### 4.7 Triple DES (3DES)

```{prf:definition} Triple DES (3DES)
:label: def-3des

**3DES** (officially TDEA) applies DES three times with independent keys to extend the effective key size:

$$C = E_{K_3}\!\left(D_{K_2}\!\left(E_{K_1}(P)\right)\right)$$

The **Encrypt-Decrypt-Encrypt (EDE)** structure ensures that setting $K_1 = K_2 = K_3$ recovers ordinary single DES (backward compatibility).

| Keying option | Keys | Effective security |
|:---:|:---:|:---:|
| 3-key (K1 ≠ K2 ≠ K3) | 168 bits total | ~112 bits (meet-in-the-middle) |
| 2-key (K1 = K3 ≠ K2) | 112 bits total | ~80 bits |
```

```{admonition} 3DES Status
:class: warning
3DES was deprecated by NIST in 2017 and **disallowed** after 2023. AES should be used for all new applications. 3DES is approximately **3× slower** than single DES and **~6× slower** than AES on modern hardware.
```

---

### 4.8 Strength and Weaknesses of DES

Understanding why DES was trusted for 25 years — and why it is now broken — teaches important lessons about how to evaluate any cipher.

#### Strengths

```{admonition} Simplicity and Efficiency
:class: tip

- **Easy to implement** in both hardware and software. DES's well-defined S-boxes, P-boxes, and permutation tables map directly to simple gate-level logic.
- **Low computational overhead.** The entire cipher fits in a small hardware chip (the original 1977 implementation used fewer than 10,000 transistors).
- **Fast encryption/decryption** compared to public-key schemes. DES processes 64 bits per round with only XOR, table-lookup, and bit-shift operations.
```

```{admonition} Strong Diffusion and Confusion per Round
:class: tip

- The **Feistel structure** guarantees that the cipher is automatically invertible even though the round function $F$ is not — reducing design complexity.
- The **S-boxes** were carefully designed to maximise non-linearity, providing strong confusion and resistance to linear cryptanalysis (in fact, NSA's design rules for the S-boxes were prescient — differential cryptanalysis was not publicly known until 1990).
- The **key schedule** generates 16 distinct 48-bit subkeys through a combination of permutation and circular shifts, so every subkey differs significantly from the master key.
- **Avalanche effect:** changing a single plaintext bit propagates to approximately 32 ciphertext bits after all 16 rounds.
```

```{admonition} Widespread Adoption and Public Scrutiny
:class: tip

- DES was the **first publicly specified** symmetric cipher endorsed by a national standards body (NIST/NBS, 1977), enabling independent academic review.
- Decades of analysis by thousands of cryptographers confirmed the structural soundness of the algorithm. No attack on the full 16-round DES significantly better than exhaustive key search was ever found against the *algorithm itself*.
- DES became the global default for **financial systems** (ATMs, PIN verification, inter-bank transfers via SWIFT) and secure communications throughout the 1980s–1990s.
```

```{admonition} Standardisation and Interoperability
:class: tip

- Standardised by **ANSI** (X3.92), **ISO** (ISO 8731-1), and **FIPS** (FIPS PUB 46), making it universally interoperable across hardware, operating systems, and international borders.
- The fixed 64-bit block size and 56-bit key made it straightforward to integrate into existing communication protocols and storage systems.
```

#### Weaknesses

```{admonition} Small Key Size — The Fatal Flaw
:class: danger

| Metric | Value |
|:---|:---:|
| Key space | $2^{56} \approx 7.2 \times 10^{16}$ keys |
| EFF Deep Crack (1998) | 56 hours, USD 250 000 |
| Distributed.net (1999) | 22 hours 15 minutes |
| Modern FPGA cluster | **< 1 hour** |
| Modern GPU cluster | **< 24 hours** at negligible cost |

The NSA reduced the original key proposal from 64 bits to 56 bits during standardisation. At the time, $2^{56}$ brute-force seemed infeasible. By 1998 it was not.

**Key lesson:** $n$-bit security requires $2^n$ operations for brute force. With hardware doubling in speed every 18 months (Moore's Law), a key size that is secure today may be broken in decade.
```

```{admonition} Short Block Size — Birthday-Bound Attacks
:class: warning

DES's 64-bit block size means that after encrypting $2^{32} \approx 4$ billion blocks (~32 GB of data) with the same key, **block collisions** become probable (birthday bound = $\sqrt{2^{64}} = 2^{32}$). An attacker who observes a collision can recover plaintext without breaking the key — this is the **Sweet32** attack (2016). This is independent of the key size problem.

AES uses 128-bit blocks, pushing the birthday bound to $2^{64}$ blocks (~147 million terabytes) — effectively unreachable.
```

```{admonition} Vulnerable to Meet-in-the-Middle (Double DES)
:class: warning

Naively applying DES twice with two independent 56-bit keys ($C = E_{K_2}(E_{K_1}(P))$) gives 112 bits of key material but only **~$2^{57}$ security** — barely more than single DES — due to the meet-in-the-middle attack:

1. Encrypt $P$ under all $2^{56}$ values of $K_1$ → table of $2^{56}$ intermediate values.
2. Decrypt $C$ under all $2^{56}$ values of $K_2$ → look up each result in the table.
3. Matching pair $(K_1, K_2)$ is the key, found in $O(2^{57})$ time with $O(2^{56})$ memory.

This is why **3DES** uses Encrypt–Decrypt–Encrypt (EDE) with three keys to achieve ~112-bit effective security.
```

```{admonition} Differential and Linear Cryptanalysis
:class: warning

- **Differential cryptanalysis** (Biham & Shamir, 1990): requires $2^{47}$ chosen plaintexts to break DES — still infeasible in practice but theoretically better than brute force for reduced-round versions. The S-box design suggests NSA was aware of this attack 15 years before its public discovery.
- **Linear cryptanalysis** (Matsui, 1993): requires $2^{43}$ known plaintexts — better than brute force in theory, but impractical for full 16-round DES with the $2^{56}$ key-search threshold already reachable by hardware.
```

#### Summary: Strength vs. Weakness at a Glance

| Aspect | Assessment | Detail |
|:---|:---:|:---|
| Algorithm structure | ✓ Sound | No structural break found after 50 years of analysis |
| S-box design | ✓ Strong | Resistant to differential cryptanalysis by design |
| Avalanche effect | ✓ Good | ~32 bits flip per 1-bit plaintext change after 16 rounds |
| Key size (56 bits) | ✗ **Fatal** | Brute-forceable in hours with 2026 hardware |
| Block size (64 bits) | ✗ Weak | Sweet32 attack after ~32 GB of data under same key |
| Double-DES | ✗ Weak | Meet-in-the-middle reduces 112-bit key to ~57-bit security |
| Differential cryptanalysis | △ Marginal | $2^{47}$ chosen plaintexts — impractical but sub-brute-force |
| Linear cryptanalysis | △ Marginal | $2^{43}$ known plaintexts — impractical but sub-brute-force |

::::{question} DES Strength Assessment
:type: multiple-choice
:variant: single-select
:showanswer:

Which of the following is the **primary** reason DES was retired, not a secondary weakness?
---
[ ] The S-boxes were found to contain a backdoor planted by the NSA.
> No backdoor was ever confirmed. The S-box design was later shown to have been deliberately hardened *against* differential cryptanalysis, which supports intentional strengthening rather than weakening.
[ ] DES is vulnerable to differential cryptanalysis requiring only a few plaintexts.
> Differential cryptanalysis of full 16-round DES requires $2^{47}$ chosen plaintexts — far more than brute-force search of the $2^{56}$ key space, so it was not the deciding factor.
[x] The 56-bit key can be exhaustively searched with commodity hardware in under 24 hours.
> Correct. The fundamental retirement reason was the **small key size**: $2^{56}$ exhaustive search became feasible with dedicated hardware by 1998 (EFF Deep Crack) and trivial by the 2000s. The algorithm's structure itself was never broken.
[ ] DES produces identical ciphertext for identical plaintext blocks (ECB problem).
> Block-repetition is a *mode of operation* problem (ECB mode), not a weakness of DES itself. DES used with CBC, CTR, or GCM does not have this issue.
---
::::

---

## 5. Advanced Encryption Standard (AES)

In 1997, NIST launched an open international competition to replace the aging DES. After five years of public cryptanalysis, NIST selected **Rijndael** — designed by Belgian cryptographers Vincent Rijmen and Joan Daemen — as the new standard, formalised in **FIPS 197** (November 2001). AES has been the world's dominant symmetric cipher ever since: it secures TLS/HTTPS, Wi-Fi (WPA2/WPA3), disk encryption (BitLocker, FileVault), VPNs, and mobile apps.

```{prf:definition} AES Parameters
:label: def-aes

**AES (Advanced Encryption Standard)** is a Substitution-Permutation Network (SPN) block cipher with the following parameters:

| Parameter | Value |
|:---|:---|
| Block size | 128 bits (16 bytes) |
| Key sizes | 128, 192, or 256 bits |
| Rounds | 10 (AES-128) · 12 (AES-192) · 14 (AES-256) |
| Internal state | 4 × 4 matrix of bytes (128 bits) |
| Operations per round | SubBytes · ShiftRows · MixColumns · AddRoundKey |

The last round **omits MixColumns**. An initial AddRoundKey step is applied before Round 1.
```

```{figure} ../figures/ch08/aes_algorithm_overview.png
:align: center
:width: 70%
:name: fig-aes-overview

AES algorithm — the 4×4 byte state matrix is transformed over 10/12/14 rounds using four operations and per-round subkeys.
```

```{admonition} How to read §5
:class: tip
Study AES as the **standard 128-bit block cipher**: every block is 16 bytes arranged as a 4×4 state matrix. The worked examples below do not define a smaller AES standard. They are teaching traces that show one byte, one column, or one round so the mechanics are easy to follow before reading a full implementation.
```

---

### 5.1 AES State Matrix

AES treats the 16-byte (128-bit) plaintext block as a **4 × 4 matrix of bytes**, filled **column by column**:

$$
\text{state} =
\begin{bmatrix}
b_0 & b_4 & b_8  & b_{12} \\
b_1 & b_5 & b_9  & b_{13} \\
b_2 & b_6 & b_{10} & b_{14} \\
b_3 & b_7 & b_{11} & b_{15}
\end{bmatrix}
$$

where $b_0 \dots b_{15}$ are the plaintext bytes in order. The same 4×4 structure holds the round key and is updated after each of the four round operations.

---

### 5.2 AES Encryption Process

The high-level AES encryption flow is:

1. **Initial AddRoundKey** — XOR the plaintext state with the first round key $K_0$.
2. **Rounds 1 … N−1** — Each full round applies: **SubBytes → ShiftRows → MixColumns → AddRoundKey**.
3. **Final Round N** — Same as above but **MixColumns is omitted**: **SubBytes → ShiftRows → AddRoundKey**.

```{figure} ../figures/ch08/aes_encryption_process.png
:align: center
:width: 60%
:name: fig-aes-process

AES encryption process — initial key XOR, followed by $N-1$ full rounds, and one final (shortened) round.
```

````{prf:example} Standard AES-128 Round 1 — Teaching Trace
:label: ex-aes-round1-trace

This example uses the standard AES-128 test input from FIPS 197. It is real AES: 128-bit plaintext block, 128-bit key, 4×4 byte state, and the normal Round 1 order.

**Plaintext block:**

$$P=\texttt{00112233445566778899aabbccddeeff}$$

**Cipher key:**

$$K=\texttt{000102030405060708090a0b0c0d0e0f}$$

AES fills the state **column by column**. The plaintext state and key state are therefore:

| Matrix | Row 0 | Row 1 | Row 2 | Row 3 |
|:---|:---:|:---:|:---:|:---:|
| Plaintext state | `00 44 88 cc` | `11 55 99 dd` | `22 66 aa ee` | `33 77 bb ff` |
| Cipher-key state $K_0$ | `00 04 08 0c` | `01 05 09 0d` | `02 06 0a 0e` | `03 07 0b 0f` |

**Initial AddRoundKey:** XOR each state byte with the matching key byte.

| Row | State after $P \oplus K_0$ |
|:---:|:---:|
| 0 | `00 40 80 c0` |
| 1 | `10 50 90 d0` |
| 2 | `20 60 a0 e0` |
| 3 | `30 70 b0 f0` |

**Round 1:** apply **SubBytes → ShiftRows → MixColumns → AddRoundKey**.

| Round-1 step | Row 0 | Row 1 | Row 2 | Row 3 |
|:---|:---:|:---:|:---:|:---:|
| After SubBytes | `63 09 cd ba` | `ca 53 60 70` | `b7 d0 e0 e1` | `04 51 e7 8c` |
| After ShiftRows | `63 09 cd ba` | `53 60 70 ca` | `e0 e1 b7 d0` | `8c 04 51 e7` |
| After MixColumns | `5f 57 f7 1d` | `72 f5 be b9` | `64 bc 3b f9` | `15 92 29 1a` |
| Round key $K_1$ | `d6 d2 da d6` | `aa af a6 ab` | `74 72 78 76` | `fd fa f1 fe` |
| After AddRoundKey | `89 85 2d cb` | `d8 5a 18 12` | `10 ce 43 8f` | `e8 68 d8 e4` |

So after Round 1, the AES state is:

$$
\begin{bmatrix}
89 & 85 & 2d & cb \\
d8 & 5a & 18 & 12 \\
10 & ce & 43 & 8f \\
e8 & 68 & d8 & e4
\end{bmatrix}
$$

**How to study this table:** first verify one byte in SubBytes, then one row in ShiftRows, then one column in MixColumns. For example, after ShiftRows the first column is:

$$[63,\ 53,\ e0,\ 8c]^T$$

MixColumns transforms it into:

$$[5f,\ 72,\ 64,\ 15]^T$$

Finally, AddRoundKey XORs that column with the first column of $K_1$:

$$
\begin{bmatrix}5f\\72\\64\\15\end{bmatrix}
\oplus
\begin{bmatrix}d6\\aa\\74\\fd\end{bmatrix}
=
\begin{bmatrix}89\\d8\\10\\e8\end{bmatrix}
$$

This is the AES version of the DES round trace: each operation is simple locally, but repeated rounds create strong confusion and diffusion across the whole 128-bit block.
````

---

#### 5.2.1 SubBytes — Confusion

SubBytes replaces each of the 16 bytes of the state with a new value looked up from a **pre-computed 16 × 16 S-box** table. The S-box is derived by:

1. Computing the **multiplicative inverse** of the byte in $\text{GF}(2^8)$ (with $0 \mapsto 0$).
2. Applying a fixed **affine transformation** over $\text{GF}(2)$.

This makes SubBytes the sole **non-linear** operation in AES — it is what generates confusion and makes AES resistant to linear attacks.

```{figure} ../figures/ch08/aes_subbytes.png
:align: center
:width: 65%
:name: fig-aes-subbytes

SubBytes — every byte of the 4×4 state is independently replaced using the AES S-box look-up table.
```

```{admonition} SubBytes is Bijective
:class: note
The AES S-box is a **bijection** (one-to-one and onto): every input byte maps to a unique output byte. This guarantees that SubBytes is invertible, which is required for decryption.
```

---

#### 5.2.2 ShiftRows — Inter-Column Diffusion

ShiftRows cyclically **left-shifts** each row of the state by a different number of byte positions:

| Row | Shift |
|:---:|:---:|
| Row 0 | 0 (unchanged) |
| Row 1 | 1 byte left |
| Row 2 | 2 bytes left |
| Row 3 | 3 bytes left |

Bytes that "fall off" the left end wrap around to the right. This moves bytes from one column into another, ensuring that after MixColumns each column mixes bytes from **all four original columns**.

```{figure} ../figures/ch08/aes_shiftrows.png
:align: center
:width: 70%
:name: fig-aes-shiftrows

ShiftRows — rows are cyclically shifted left by 0, 1, 2, and 3 positions respectively; bytes wrap around.
```

---

#### 5.2.3 MixColumns — Intra-Column Diffusion

MixColumns operates on each **column** independently. It treats the 4 bytes of a column as a degree-3 polynomial over $\text{GF}(2^8)$ and multiplies it by the fixed polynomial:

$$
c(x) = 03 \cdot x^3 + 01 \cdot x^2 + 01 \cdot x + 02 \pmod{x^4 + 1}
$$

Equivalently, each column is multiplied by the matrix:

$$
\begin{bmatrix} 2 & 3 & 1 & 1 \\ 1 & 2 & 3 & 1 \\ 1 & 1 & 2 & 3 \\ 3 & 1 & 1 & 2 \end{bmatrix}
\pmod{x^8 + x^4 + x^3 + x + 1}
$$

Each output byte depends on **all four** input bytes of the column, providing **full intra-column diffusion**. MixColumns is **omitted in the final round** by the AES design; decryption applies the corresponding inverse operations in reverse order.

```{figure} ../figures/ch08/aes_mixcolumns.png
:align: center
:width: 65%
:name: fig-aes-mixcolumns

MixColumns — each column is multiplied by a fixed matrix over GF(2⁸); every output byte depends on all four input bytes of the column.
```

---

#### 5.2.4 AddRoundKey — Key Injection

AddRoundKey **XORs** the entire 128-bit state with the 128-bit round subkey $K_i$ produced by the key schedule. This is the only step that introduces secret key material into the cipher.

$$
S'[r][c] = S[r][c] \oplus K_i[r][c]
$$

Because XOR is its own inverse ($a \oplus k \oplus k = a$), AddRoundKey is trivially invertible — the same operation undoes itself during decryption.

```{figure} ../figures/ch08/aes_addroundkey.png
:align: center
:width: 65%
:name: fig-aes-addroundkey

AddRoundKey — all 16 state bytes are XORed with the corresponding 16 bytes of the round subkey.
```

```{admonition} Full Diffusion After Two Rounds
:class: important
Combining ShiftRows (inter-column spread) with MixColumns (intra-column mix) gives the **wide-trail strategy**: after a small number of full rounds, a byte difference spreads across the full state. After 10 rounds this provides strong avalanche — a 1-bit plaintext change flips about half of the ciphertext bits on average.
```

````{prf:example} One Byte Through AES SubBytes and AddRoundKey
:label: ex-aes-byte-operation

A full AES encryption is too long to do by hand, but one byte operation is easy to trace.

Suppose a state byte before SubBytes is:

$$x = \mathtt{53}_{16}$$

The AES S-box maps this byte to:

$$S(\mathtt{53}) = \mathtt{ED}_{16}$$

If the matching round-key byte is:

$$k = \mathtt{2B}_{16}$$

then AddRoundKey XORs the substituted byte with the key byte:

$$\mathtt{ED} \oplus \mathtt{2B} = \mathtt{C6}$$

So for this byte position, the local transformation is:

$$\mathtt{53} \xrightarrow{\text{SubBytes}} \mathtt{ED} \xrightarrow{\text{AddRoundKey}} \mathtt{C6}$$

In real AES this happens to all 16 state bytes, with ShiftRows and MixColumns spreading each byte's influence across the state between key additions.
````

---

### 5.3 AES Key Schedule

The key schedule expands the original key into $N_r + 1$ round keys of 128 bits each. For AES-128 this produces **11 round keys** (44 words of 32 bits).

```{figure} ../figures/ch08/aes_design.png
:align: center
:width: 70%
:name: fig-aes-design

AES key schedule — the original key is expanded into per-round subkeys using RotWord, SubWord, and XOR with round constants (Rcon).
```

```{prf:algorithm} AES Key Expansion
:label: algo-aes-keyschedule

**Input:** Key $K$ of $N_k$ 32-bit words ($N_k$ = 4 for AES-128, 6 for AES-192, 8 for AES-256)

**Output:** $4(N_r+1)$ words — one 128-bit round key per round plus the initial key

**Steps for each new word $W[i]$:**
1. Set $\text{temp} = W[i-1]$
2. If $i \equiv 0 \pmod{N_k}$:
   - $\text{temp} \leftarrow \text{SubWord}(\text{RotWord}(\text{temp})) \oplus \text{Rcon}[i/N_k]$
   - (**RotWord** = circular-left-shift by 1 byte; **SubWord** = S-box each byte; **Rcon** = $[x^{i/N_k - 1}, 0, 0, 0]$ in GF(2⁸))
3. $W[i] \leftarrow W[i - N_k] \oplus \text{temp}$
```

| Variant | $N_k$ | $N_r$ | Words generated | Round keys |
|:---:|:---:|:---:|:---:|:---:|
| AES-128 | 4 | 10 | 44 | 11 |
| AES-192 | 6 | 12 | 52 | 13 |
| AES-256 | 8 | 14 | 60 | 15 |

---

### 5.4 AES Decryption

AES decryption reverses each round by applying the **inverse operations** in reverse order:

- **InvShiftRows** — right-shift rows by 0, 1, 2, 3 bytes.
- **InvSubBytes** — apply the inverse S-box.
- **AddRoundKey** — identical to encryption (XOR is self-inverse).
- **InvMixColumns** — multiply columns by the inverse matrix over GF(2⁸).

The round key schedule is used in **reverse**: the last generated round key is used first.

```{figure} ../figures/ch08/aes_decryption.png
:align: center
:width: 65%
:name: fig-aes-decryption

AES decryption — identical structure to encryption but with inverse operations applied in reverse order.
```

```{admonition} Equivalent Inverse Cipher
:class: note
NIST also defines an **Equivalent Inverse Cipher** that reshuffles the inverse operations so that decryption follows the same code structure as encryption (useful for hardware implementation). Both are specified in FIPS 197.
```

---

### 5.5 AES Key Variants: 128 vs 192 vs 256

| Feature | AES-128 | AES-192 | AES-256 |
|:---|:---:|:---:|:---:|
| Key length | 128 bits | 192 bits | 256 bits |
| Number of rounds | 10 | 12 | 14 |
| Classical security | 2¹²⁸ | 2¹⁹² | 2²⁵⁶ |
| Post-quantum (Grover) | ~2⁶⁴ | ~2⁹⁶ | ~2¹²⁸ ✓ |
| Performance | Fastest | Moderate | Slowest |
| NSA Suite B use | Sensitive data | — | Top Secret |
| Recommended for | General use | Transition | Long-term / PQC |

```{admonition} Choosing an AES Variant
:class: tip
- **AES-128** is computationally safe today and fastest for software (10 rounds). Use it where performance matters and long-term security is not a concern.
- **AES-256** is recommended when data must remain secure against future quantum computers — Grover's algorithm would only reduce effective key strength to ~128 bits, still considered secure.
- AES-192 offers little practical advantage and is rarely used outside specific government contexts.
```

---

### 5.6 AES vs DES

```{figure} ../figures/ch08/aes_vs_des.png
:align: center
:width: 75%
:name: fig-aes-vs-des

AES vs DES — key differences in design, key length, block size, structure, and security.
```

| Property | DES | AES |
|:---|:---:|:---:|
| Published | 1977 | 2001 |
| Structure | Feistel network | SPN (non-Feistel) |
| Block size | 64 bits | 128 bits |
| Key size | 56 bits | 128 / 192 / 256 bits |
| Number of rounds | 16 | 10 / 12 / 14 |
| Security | Broken (EFF, 1998) | No practical attack known |
| Speed (hardware) | Moderate | Faster (AES-NI) |
| Invertibility | Feistel auto-inverse | Explicit inverse ops required |
| Standard | Withdrawn | Current NIST FIPS 197 |

```{admonition} Why AES Replaced DES
:class: important
DES was broken not by cryptanalysis of the algorithm itself but by **exhaustive 56-bit key search** — a brute-force attack feasible with custom hardware since 1998. AES's 128-bit minimum key length makes brute force computationally infeasible for the foreseeable future, and its mathematical structure provides proven resistance to differential and linear cryptanalysis.
```

---

### 5.7 AES Security Analysis

```{admonition} AES Security Status (2026)
:class: tip

| Variant | Key bits | Classical security | Post-quantum security (Grover) |
|:---:|:---:|:---:|:---:|
| AES-128 | 128 | 128 bits | ~64 bits |
| AES-192 | 192 | 192 bits | ~96 bits |
| **AES-256** | **256** | **256 bits** | **~128 bits — quantum-safe** |

No attack significantly better than exhaustive key search is known against any AES variant.
```

**Known Attacks (none are practical):**

- **Known-key distinguishing attack (2009)** — breaks only 8 of 10 rounds of AES-128 and requires knowledge of the key; not a threat to real-world AES.
- **Side-channel attacks** — if AES is implemented carelessly (non-constant-time table lookups), electromagnetic or timing information can leak key bits. Mitigated by AES-NI hardware instructions.
- **Key-recovery biclique attack (2011)** — the best known theoretical break: reduces AES-128 search from $2^{128}$ to $2^{126.1}$ — faster by a factor of only ~4, and still completely infeasible.
- **Quantum (Grover) attack** — halves the effective key length. AES-256 maintains ~128-bit post-quantum security.

```{admonition} AES-NI
:class: note
Modern x86 CPUs (Intel/AMD since ~2010) and ARM CPUs include **AES-NI** — dedicated hardware instructions that execute one AES round per clock cycle in constant time, eliminating side-channel timing leaks and achieving multi-gigabyte-per-second throughput.
```

::::{question} AES Round Operations
:type: multiple-choice
:variant: single-select
:showanswer:

Which AES round operation is responsible for ensuring that a change in one byte of the state affects all four bytes in the **same column**?
---
[ ] SubBytes
> SubBytes operates on each byte independently using the S-box — it does not spread influence between bytes in the same column.
[ ] ShiftRows
> ShiftRows moves bytes between different columns but does not mix bytes within a column.
[x] MixColumns
> Correct! MixColumns multiplies each column by a 4×4 matrix over GF(2⁸), so each of the four output bytes depends on all four input bytes of that column — this is the primary intra-column diffusion step.
[ ] AddRoundKey
> AddRoundKey XORs the state with the round key. It injects key material but does not mix state bytes among each other.
---
::::

::::{question} AES Key Variants
:type: multiple-choice
:variant: single-select
:showanswer:

Which AES variant is recommended for data that must remain secure against future quantum computers?
---
[ ] AES-128
> AES-128 has ~64-bit post-quantum security after Grover's algorithm halves the effective key length — this is considered marginal for long-term secrets.
[ ] AES-192
> AES-192 gives ~96-bit post-quantum security, generally considered sufficient but AES-256 is the stronger recommendation.
[x] AES-256
> Correct! AES-256 provides ~128-bit post-quantum security (Grover halves 256 bits to ~128), which is the accepted threshold for long-term quantum-resistant symmetric encryption.
[ ] 3DES-168
> 3DES is deprecated and provides only ~112-bit classical security (meet-in-the-middle). It is not used for new applications.
---
::::

---

## 6. Modes of Operation

A block cipher encrypts exactly one block. Real messages are longer. **Modes of operation** define how to split, chain, and encrypt multi-block messages securely.

### 6.1 ECB — Electronic Codebook

```{prf:definition} ECB Mode
:label: def-ecb

**Encryption:** $C_i = E_K(P_i)$ for each block $i$ independently.

**Decryption:** $P_i = E_K^{-1}(C_i)$
```

```{admonition} Never Use ECB
:class: danger
ECB is **not semantically secure**. Identical plaintext blocks produce identical ciphertext blocks, leaking equality information. The "ECB penguin" is the canonical illustration: encrypting a bitmap with AES-ECB leaves the image outline clearly visible in the ciphertext. **ECB must never be used.**
```

### 6.2 CBC — Cipher Block Chaining

```{prf:definition} CBC Mode
:label: def-cbc

CBC uses the previous ciphertext block to randomise each encryption:

**Encryption** (requires random IV $C_0$):
$$C_i = E_K(P_i \oplus C_{i-1})$$

**Decryption:**
$$P_i = E_K^{-1}(C_i) \oplus C_{i-1}$$

The **Initialisation Vector** $C_0 = \text{IV}$ must be **uniformly random** and **never reused** with the same key.
```

```{admonition} CBC Vulnerabilities
:class: warning
- **Padding oracle attacks** (POODLE, BEAST) can decrypt CBC ciphertext by exploiting padding error messages — CBC is not IND-CCA secure on its own.
- **IV reuse** fully breaks confidentiality for the first block.
- Encryption is **sequential** (cannot be parallelised); decryption can be parallelised.
- Use CBC only with **HMAC** (CBC+HMAC = authenticated encryption) or prefer GCM.
```

### 6.3 CTR — Counter Mode

```{prf:definition} CTR Mode
:label: def-ctr

CTR turns a block cipher into a **stream cipher**:

**Keystream generation:**
$$Z_i = E_K(\text{nonce} \;\|\; i)$$

**Encryption/Decryption** (same operation):
$$C_i = P_i \oplus Z_i \qquad P_i = C_i \oplus Z_i$$

The nonce must be unique per encryption (never reused with the same key).
```

```{admonition} CTR Advantages
:class: tip
- **Parallelisable** — all $Z_i$ blocks can be computed simultaneously
- **Random access** — can decrypt block $i$ without processing blocks $1, \ldots, i-1$
- No padding needed (arbitrary message length)
- IND-CPA secure
- **Weakness:** no integrity — flipping a ciphertext bit deterministically flips the corresponding plaintext bit (malleable). Must add authentication (→ GCM).
```

### 6.4 GCM — Galois/Counter Mode

```{prf:definition} GCM Mode
:label: def-gcm

**GCM (Galois/Counter Mode)** is an **AEAD** mode combining CTR encryption with a **GHASH** authentication tag over $\text{GF}(2^{128})$:

**Encryption:**
$$C_i = P_i \oplus E_K(\text{nonce} \;\|\; i)$$

**Authentication tag:**
$$\tau = \text{GHASH}_{H}(A,\; C) \oplus E_K(\text{nonce} \;\|\; 0)$$

where $H = E_K(0^{128})$ is the hash key and $A$ is the **associated data** (authenticated but not encrypted, e.g. packet headers).

**Decryption:** Verify $\tau$ first; reject with $\bot$ if invalid; then decrypt.
```

```{admonition} GCM is the Modern Standard
:class: important
AES-256-GCM is the recommended mode for all new applications (TLS 1.3, SSH, IPsec, disk encryption). It provides:
- **Confidentiality** (IND-CPA from CTR)
- **Integrity + Authentication** (IND-CCA from GHASH tag)
- **Speed** — GCM is parallelisable and hardware-accelerated (AES-NI + PCLMULQDQ instructions on x86)

**Single nonce reuse breaks both confidentiality and authentication** — use a random 96-bit nonce or a counter that is never repeated.
```

### 6.5 Mode Comparison

| Mode | Auth? | Parallel Enc? | Parallel Dec? | IV/Nonce reuse | Use |
|:---:|:---:|:---:|:---:|:---:|:---:|
| ECB | ✗ | ✓ | ✓ | Fatal | **Never** |
| CBC | ✗ | ✗ | ✓ | Fatal | Legacy only + HMAC |
| CTR | ✗ | ✓ | ✓ | Fatal | With separate MAC |
| **GCM** | **✓** | **✓** | **✓** | **Fatal** | **Recommended** |

::::{question} Choosing a Mode
:type: multiple-choice
:variant: single-select
:showanswer:

A developer needs to encrypt individual 128-byte database records with AES. Records must be verifiably untampered with. Each record uses a fresh random nonce. Which mode should she use?
---
[ ] ECB
> ECB provides no authentication and identical records would produce identical ciphertexts, leaking equality.
[ ] CBC with a fixed IV
> A fixed IV means the first block of identical records always encrypts identically — leaking information. CBC also needs a separate MAC for integrity.
[ ] CTR
> CTR provides confidentiality but no built-in integrity. A separate authentication step would still be needed.
[x] GCM
> Correct! AES-GCM provides both confidentiality and integrity in one efficient pass. With a fresh random nonce per record, it is IND-CCA secure.
---
::::

---

## 7. Interactive Demo: ECB vs GCM

```{admonition} How to Make It Interactive
:class: note
Click the **Live Code** button at the top of the page to run the cell below. Modify `block_a`, `block_b`, and the key to see how repeated plaintext blocks behave in ECB and how GCM adds authentication.
```

```{code-cell} python
:tags: [thebe-init]

try:
    from Crypto.Cipher import AES
    import os

    key = os.urandom(16)
    block_a = b"PAYMENT:00010000"
    block_b = b"PAYMENT:00010000"
    plaintext = block_a + block_b

    cipher_ecb = AES.new(key, AES.MODE_ECB)
    ecb_ciphertext = cipher_ecb.encrypt(plaintext)
    ecb_block_1 = ecb_ciphertext[:16]
    ecb_block_2 = ecb_ciphertext[16:]

    cipher_gcm = AES.new(key, AES.MODE_GCM)
    ciphertext_gcm, tag = cipher_gcm.encrypt_and_digest(plaintext)

    print(f"Key (hex):            {key.hex()}")
    print(f"Plaintext block 1:    {block_a}")
    print(f"Plaintext block 2:    {block_b}")
    print(f"ECB block 1 (hex):    {ecb_block_1.hex()}")
    print(f"ECB block 2 (hex):    {ecb_block_2.hex()}")
    print(f"ECB blocks equal?     {ecb_block_1 == ecb_block_2}")
    print(f"GCM ciphertext (hex): {ciphertext_gcm.hex()}")
    print(f"GCM auth tag  (hex):  {tag.hex()}")
    print(f"GCM nonce     (hex):  {cipher_gcm.nonce.hex()}")

except ImportError:
    print("Install pycryptodome: pip install pycryptodome")
    print("  AES-128 key size:   16 bytes = 128 bits")
    print("  AES-256 key size:   32 bytes = 256 bits")
    print("  AES block size:     16 bytes = 128 bits (always)")
```

---

## 8. Advanced Attack Techniques

Modern block ciphers are designed to resist the following families of attacks. Understanding them explains why DES was retired and why AES's S-boxes and MixColumns were designed the way they were.

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

| Concept | Study meaning | Cryptographic role |
|:---|:---|:---|
| **Block cipher** | Keyed permutation on fixed-size $n$-bit blocks | Core symmetric primitive |
| **Block size** | Number of bits processed per primitive call | Controls birthday-bound limits and mode design |
| **Confusion** | Non-linear relation between key, plaintext, and ciphertext | Usually supplied by S-boxes |
| **Diffusion** | One input bit influences many output bits | Supplied by P-boxes, ShiftRows, MixColumns |
| **Avalanche effect** | One-bit change flips about half the output bits | Evidence of strong repeated confusion/diffusion |
| **Feistel network** | Split-half structure with XOR feedback | Makes the whole cipher invertible even if $F$ is not |
| **SPN** | Alternating substitution, permutation/mixing, key addition | AES design family; internal layers must be invertible |
| **DES** | 64-bit block, 56-bit key, 16-round Feistel cipher | Historically important, now broken by key search |
| **3DES** | EDE triple application of DES | Deprecated transition cipher |
| **AES** | 128-bit block SPN with 128/192/256-bit keys | Current standard block cipher |
| **ECB** | Independent block encryption | Insecure because patterns remain visible |
| **CBC** | Chains blocks using an IV | Legacy confidentiality mode; needs authentication |
| **CTR** | Uses encrypted counters as a keystream | Fast and parallel, but malleable without a MAC |
| **GCM** | CTR plus GHASH authentication | Recommended AEAD mode for new systems |

```{admonition} What to Remember
:class: tip
- A block cipher is only a one-block primitive; a mode of operation is required for real messages.
- DES is valuable to study because its Feistel design teaches the mechanics, but its 56-bit key is no longer secure.
- AES is the modern block cipher standard, but AES-ECB is still insecure because the mode leaks patterns.
- New applications should normally use authenticated encryption, such as AES-GCM, with a nonce that is never reused for the same key.
```

---

## Exercises

```{exercise} Feistel Decryption
:label: ch08-ex-feistel

Using the same parameters as {prf:ref}`ex-feistel-full` ($K_1=1010$, $K_2=0110$, $K_3=1100$, $F(R,K)=R \oplus K$), encrypt plaintext $P = 0110\;1001$ and then decrypt your ciphertext to verify the original plaintext is recovered.
```

```{solution} ch08-ex-feistel
:label: sol-ch08-ex-feistel
:class: dropdown

**Encryption** — $L_0=0110$, $R_0=1001$

Round 1 ($K_1=1010$): $L_1=1001$, $R_1=0110\oplus(1001\oplus1010)=0110\oplus0011=0101$

Round 2 ($K_2=0110$): $L_2=0101$, $R_2=1001\oplus(0101\oplus0110)=1001\oplus0011=1010$

Round 3 ($K_3=1100$): $L_3=1010$, $R_3=0101\oplus(1010\oplus1100)=0101\oplus0110=0011$

**Ciphertext:** $1010\;0011$

**Decryption** — starting from $L_3=1010$, $R_3=0011$, subkeys reversed $K_3,K_2,K_1$:

Dec-round 1 ($K_3=1100$): $R_2=1010$, $L_2=0011\oplus(1010\oplus1100)=0011\oplus0110=0101$

Dec-round 2 ($K_2=0110$): $R_1=0101$, $L_1=1010\oplus(0101\oplus0110)=1010\oplus0011=1001$

Dec-round 3 ($K_1=1010$): $R_0=1001$, $L_0=0101\oplus(1001\oplus1010)=0101\oplus0011=0110$

**Recovered plaintext:** $0110\;1001$ ✓
```

```{exercise} Mode of Operation Security
:label: ch08-ex-modes

A developer encrypts a large log file in CBC mode using AES-128, but accidentally uses a **fixed, hardcoded IV** (the same IV every time the program runs).

1. Describe the security consequence for the **first block** of the log.
2. Does the problem propagate to the second and later blocks? Explain.
3. What is the correct fix?
```

```{solution} ch08-ex-modes
:label: sol-ch08-ex-modes
:class: dropdown

**1. First-block consequence:**

CBC encrypts the first block as $C_1 = E_K(P_1 \oplus \text{IV})$. With a fixed IV, if the first block of the log is identical across runs (e.g. a fixed header like `[2026-04-12]`), then $C_1$ is always the same ciphertext. An attacker observing multiple run outputs can:
- Detect that all runs start with the same header
- Confirm equality of first blocks across messages without decrypting them

**2. Propagation:**

The effect is **limited to the first block**. For block $i > 1$: $C_i = E_K(P_i \oplus C_{i-1})$. Since $C_{i-1}$ depends on $P_{i-1}$, different message content in block 2 onwards produces different ciphertexts even with a fixed IV. However, if *both* block 1 and block 2 are identical across runs, block 2's ciphertext is also identical — the pattern replication grows with the length of the identical prefix.

**3. Fix:**

Generate a fresh **random 16-byte IV** using a cryptographically secure random number generator (`os.urandom(16)` in Python) for every encryption. Prepend the IV to the ciphertext (it is not secret). Better yet, switch to **AES-GCM** which provides both confidentiality and authentication.
```

```{exercise} S-box Lookup
:label: ch08-ex-sbox-lookup

Using the toy S-box from {prf:ref}`ex-sbox-lookup`, compute the output for input $x=\mathtt{1101}_2$.
```

```{solution} ch08-ex-sbox-lookup
:label: sol-ch08-ex-sbox-lookup
:class: dropdown

$\mathtt{1101}_2 = \mathtt{D}_{16}$. The toy S-box table gives $S(\mathtt{D})=\mathtt{9}$, so the output is:

$$\mathtt{9}_{16}=\mathtt{1001}_2$$
```

```{exercise} P-box Classification
:label: ch08-ex-pbox-classification

A permutation table maps 6 input bits to 4 output bits by selecting input positions $[2,6,1,5]$.

1. Is this a straight, expansion, or compression P-box?
2. Is it invertible?
3. Explain the reason in one sentence.
```

```{solution} ch08-ex-pbox-classification
:label: sol-ch08-ex-pbox-classification
:class: dropdown

It is a **compression P-box** because it has fewer outputs than inputs: $m=4<n=6$.

It is **not invertible**. Input bits 3 and 4 are dropped by the table, so their values cannot be recovered from the 4-bit output.
```

```{exercise} AES Round Operation Identification
:label: ch08-ex-aes-operation

For each AES operation, identify whether its main role is confusion, diffusion, or key injection:

1. SubBytes
2. ShiftRows
3. MixColumns
4. AddRoundKey
```

```{solution} ch08-ex-aes-operation
:label: sol-ch08-ex-aes-operation
:class: dropdown

1. **SubBytes:** confusion, because it applies the non-linear AES S-box to each byte.
2. **ShiftRows:** diffusion, because it moves bytes across columns.
3. **MixColumns:** diffusion, because each output byte depends on all four input bytes of a column.
4. **AddRoundKey:** key injection, because it XORs the current state with secret round-key material.
```

```{exercise} Nonce Reuse in CTR/GCM
:label: ch08-ex-nonce-reuse

Two different plaintexts $P_1$ and $P_2$ are encrypted with AES-CTR under the same key and the same nonce, producing ciphertexts $C_1$ and $C_2$.

1. Show what an attacker learns from $C_1 \oplus C_2$.
2. Why is the same mistake even worse in AES-GCM?
```

```{solution} ch08-ex-nonce-reuse
:label: sol-ch08-ex-nonce-reuse
:class: dropdown

CTR encryption has the form $C_i=P_i\oplus Z$, where $Z$ is the keystream generated from the key and nonce. If the same keystream is reused:

$$C_1\oplus C_2=(P_1\oplus Z)\oplus(P_2\oplus Z)=P_1\oplus P_2$$

The keystream cancels. The attacker learns the XOR of the two plaintexts, which is often enough to recover both messages when they contain predictable structure.

In GCM, nonce reuse also damages the GHASH authentication mechanism. This can allow tag forgery, so the attacker may gain both confidentiality and integrity attacks.
```

---

```{bibliography}
:filter: docname in docnames
```
