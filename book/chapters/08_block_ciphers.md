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

A block cipher is a **keyed permutation** on fixed-size data blocks. Applied with the right mode of operation, it becomes the most versatile building block in symmetric cryptography — used for file encryption, authenticated encryption, MAC construction, and even hash functions.

This chapter covers the two major structural designs (Feistel networks and Substitution-Permutation Networks), the most important historical and modern ciphers (DES, 3DES, AES), and the modes of operation that let them encrypt data of arbitrary length securely.

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
- Explain Shannon's confusion and diffusion principles
- Describe the Feistel network and prove that encryption and decryption share the same structure
- State the key parameters of DES and explain why it is insecure
- Describe the four AES round operations and their roles
- Distinguish the standard block cipher modes and know which mode is secure and authenticated
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

## 1. Design Principles: Confusion and Diffusion

Shannon's two principles from 1949 underpin every modern block cipher design.

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

### 1.1 P-boxes (Permutation Boxes)

A **P-box** (also called a *D-box* or *diffusion box*) is a hardware/software component that rearranges — **permutes** — the bit positions of its input block. P-boxes are the primary mechanism for achieving **diffusion** in block ciphers.

```{prf:definition} P-box
:label: def-pbox

A **P-box** takes an $n$-bit input and produces an $m$-bit output by rearranging (and optionally duplicating or dropping) bits according to a fixed table. The table entry at position $j$ specifies which input bit position maps to output position $j$.
```

**Example:** For input positions $(1, 2, 3, 4, 5)$, one possible P-box output ordering is $(3, 4, 2, 1, 5)$ — input bit 3 moves to output position 1, input bit 4 to position 2, and so on.

There are three types of P-boxes, classified by the relationship between input count $n$ and output count $m$:

```{figure} ../figures/ch08/pbox_types_overview.png
:name: fig-pbox-types
:width: 70%
:align: center

**Three types of P-boxes.** Straight (n = m), Compression (m < n), and Expansion (m > n).
```

---

#### 1.1.1 Straight P-box ($n = m$)

A **straight P-box** has the same number of inputs and outputs. Every input bit appears in the output exactly once, just at a different position.

```{figure} ../figures/ch08/pbox_straight.png
:name: fig-pbox-straight
:width: 65%
:align: center

**Straight P-box.** The number of inputs equals the number of outputs. Each bit is mapped to a new position — no bit is dropped or duplicated. This is the only type of P-box that is **invertible** (its inverse is simply the reverse permutation).
```

- **Invertible:** yes — the reverse permutation undoes it exactly.
- **Used in:** DES final P-box (after S-boxes in each round), AES ShiftRows.

---

#### 1.1.2 Expansion P-box ($m > n$)

An **expansion P-box** has more outputs than inputs. Some input bits are **duplicated** to fill the extra output positions.

```{figure} ../figures/ch08/pbox_expansion.png
:name: fig-pbox-expansion
:width: 65%
:align: center

**Expansion P-box.** More outputs than inputs — certain input bits appear at multiple output positions. One input can map to more than one output.
```

- **Invertible:** **no** — because one input maps to multiple outputs, the decryption algorithm cannot determine the unique original input from the output alone.
- **Used in:** DES E-box (expands the 32-bit right half to 48 bits before XOR with the subkey).

---

#### 1.1.3 Compression P-box ($m < n$)

A **compression P-box** has fewer outputs than inputs. Some input bits are **dropped** entirely.

```{figure} ../figures/ch08/pbox_compression.png
:name: fig-pbox-compression
:width: 65%
:align: center

**Compression P-box.** Fewer outputs than inputs — certain input bits are discarded. One output maps to exactly one input, but some inputs are not included.
```

- **Invertible:** **no** — dropped bits are lost; decryption cannot recover them.
- **Used in:** DES PC-1 (64-bit key → 56 bits by dropping 8 parity bits) and PC-2 (56 bits → 48-bit subkey).

---

#### 1.1.4 Invertibility Summary

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

### 1.2 S-boxes (Substitution Boxes)

An **S-box** (substitution box) is the primary tool for **confusion**. Unlike P-boxes, which rearrange bits, S-boxes **replace** a group of bits with a completely different group in a non-linear way.

```{prf:definition} S-box
:label: def-sbox

An **S-box** is a fixed lookup table that maps an $n$-bit input to an $m$-bit output non-linearly. The mapping is designed so that:
- A single input bit change causes multiple, unpredictable output bit changes (**non-linearity**)
- There is no simple algebraic relationship between input and output (resists linear cryptanalysis)

Most block ciphers use $6 \to 4$ bit S-boxes (DES) or $8 \to 8$ bit S-boxes (AES).
```

| | S-box | P-box |
|:---:|:---:|:---:|
| **Shannon property** | Confusion | Diffusion |
| **Operation** | Non-linear substitution | Bit rearrangement (linear) |
| **DES example** | S1–S8: $6 \to 4$ bits each | E-box (expansion), P-box (straight), PC-1/PC-2 (compression) |
| **AES example** | SubBytes: $8 \to 8$ bits | ShiftRows, MixColumns |

---

### 1.3 How Confusion and Diffusion Work Together

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

**Ciphertext:** $(C_L,\; C_R) = (L_r,\; R_r)$
```

```{figure} ../figures/ch08/feistel_encrypt.avif
:name: fig-feistel-encrypt
:width: 60%
:align: center

**Feistel Cipher — Encryption.** The plaintext block is split into left half $L_0$ and right half $R_0$. In each round, the right half passes through the round function $F$ together with a subkey $K_i$; the result is XORed into the left half, and the halves swap. After $r$ rounds the concatenation $(L_r, R_r)$ is the ciphertext.
```

### 2.3 Decryption Structure

```{prf:definition} Feistel Network — Decryption
:label: def-feistel-dec

**Decryption** uses the **identical circuit** but applies the subkeys in **reverse order** $(K_r, K_{r-1}, \ldots, K_1)$:

$$R_{i-1} = L_i$$
$$L_{i-1} = R_i \oplus F(L_i,\; K_i)$$

The round function $F$ is **never inverted** — the XOR structure of the network provides invertibility for free.
```

```{figure} ../figures/ch08/feistel_decrypt.avif
:name: fig-feistel-decrypt
:width: 60%
:align: center

**Feistel Cipher — Decryption.** The ciphertext block $(L_r, R_r)$ enters the same circuit with subkeys applied in reverse order. Each round undoes one encryption round exactly, recovering $(L_0, R_0)$ from the final output.
```

```{admonition} Why Feistel Networks Are Elegant
:class: important
The round function $F$ does **not** need to be invertible. Inversion is achieved by the XOR structure of the network itself. This means the same hardware/software circuit encrypts and decrypts — only the key schedule is reversed. DES's entire 16-round structure is symmetric; the chip from 1977 decrypts by reversing the key order.
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

---

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

**Ciphertext:** $C = L_3 \| R_3 = \mathbf{1111\;0000}$

---

**DECRYPTION** (same circuit, subkeys reversed: $K_3, K_2, K_1$)

Starting state: $L_3 = 1111$, $R_3 = 0000$

**Round 1 of decryption** (subkey $K_3 = 1100$):

$$R_2 = L_3 = 1111$$
$$L_2 = R_3 \oplus F(L_3, K_3) = 0000 \oplus (1111 \oplus 1100) = 0000 \oplus 0011 = 0011$$

**Round 2 of decryption** (subkey $K_2 = 0110$):

$$R_1 = L_2 = 0011$$
$$L_1 = R_2 \oplus F(L_2, K_2) = 1111 \oplus (0011 \oplus 0110) = 1111 \oplus 0101 = 1010$$

**Round 3 of decryption** (subkey $K_1 = 1010$):

$$R_0 = L_1 = 1010$$
$$L_0 = R_1 \oplus F(L_1, K_1) = 0011 \oplus (1010 \oplus 1010) = 0011 \oplus 0000 = 0011$$

**Recovered plaintext:** $P = L_0 \| R_0 = \mathbf{0011\;1010}$ ✓

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

DES was the US federal standard from 1977 to 2001. It was the first publicly specified cipher and drove an entire generation of cryptographic research.

```{prf:definition} DES
:label: def-des

**Data Encryption Standard (DES)** is a Feistel-network block cipher with:

| Parameter | Value |
|:---:|:---:|
| Block size | 64 bits |
| Key size | 56 bits (64 bits including 8 parity bits) |
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

DES processes a 64-bit plaintext block through four sequential phases. The **data path** and **key path** run in parallel:

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

### 4.2 Step 1 — Initial Permutation (IP)

The 64-bit plaintext block is reordered by the fixed **IP table** before the first Feistel round. Reading the table row by row, each entry specifies which input bit arrives at that output position:

$$\text{IP}:\quad[58,\;50,\;42,\;34,\;26,\;18,\;10,\;2,\;\;60,\;52,\;\ldots,\;\;63,\;55,\;47,\;39,\;31,\;23,\;15,\;7]$$

Output bit 1 comes from input bit 58; output bit 2 from input bit 50; …; output bit 64 from input bit 7.

```{figure} ../figures/ch08/des_initial_permutation.png
:name: fig-des-ip
:width: 75%
:align: center

**Initial Permutation in DES.** Bit positions highlighted in green are the parity bits that PC-1 will discard during key transformation. The IP table rearranges the 64 plaintext bits into a new order before the first Feistel round.
```

```{admonition} Cryptographic Role of IP
:class: note
IP provides **no cryptographic security** — it is a fixed, publicly known permutation applied identically for every key. It was included in the 1977 chip design for hardware bus-alignment reasons. All security in DES derives from the S-boxes and key mixing in the 16 Feistel rounds.
```

The permuted 64-bit block is split into:
- $L_0$ = bits 1–32 of the permuted block
- $R_0$ = bits 33–64 of the permuted block

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

1. **PC-1 (Permuted Choice 1):** Discard the 8 parity bits (bit positions 8, 16, 24, 32, 40, 48, 56, 64). Rearrange the remaining 56 bits. Split into:
   - $C_0$ = first 28 bits
   - $D_0$ = last 28 bits

2. **For each round $i = 1, \ldots, 16$:**
   - Apply a **circular left-shift** of $s_i$ bits to both $C_{i-1}$ and $D_{i-1}$:

     | Rounds | 1, 2, 9, 16 | all others (3–8, 10–15) |
     |:---:|:---:|:---:|
     | Shift $s_i$ | **1 bit** | **2 bits** |

   - **PC-2 (Permuted Choice 2):** Concatenate $C_i \| D_i$ (56 bits); select and permute 48 of them to produce $K_i$.

3. **Decryption:** apply subkeys in **reverse order** $K_{16}, K_{15}, \ldots, K_1$.
```

---

### 4.4 Step 3 — The Feistel Round Function (Mangler)

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

**All 16 Rounds — Mangler Function and Key Transformation Together.** The left column shows the parallel key schedule producing $K_1, \ldots, K_{16}$; the right column shows the Feistel data path. Each round consumes one subkey and swaps the left and right halves.
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

*Example using S1 and input* `101010`:

| Outer bits $b_1 b_6$ | Inner bits $b_2 b_3 b_4 b_5$ | Row | Col | S1 value | 4-bit output |
|:---:|:---:|:---:|:---:|:---:|:---:|
| $\mathtt{1},\,\mathtt{0}$ | $\mathtt{0101}$ | 2 | 5 | 6 | `0110` |
```

**④ P-box Permutation:** The concatenated 32-bit S-box output is rearranged by a fixed P-box table. This spreads each S-box's output bits across multiple S-box inputs in the **next** round, achieving **diffusion** across the block.

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

### 4.6 Solved Numerical Example — DES Round 1 Trace

```{prf:example} DES Round 1: Detailed Step-by-Step Walkthrough
:label: ex-des-round1

We trace DES encryption through Round 1 using the FIPS reference values from GeeksforGeeks (DES Set 1).

**Inputs (hex):**
- Plaintext: `123456ABCD132536`
- Key: `AABB09182736CCDD`

---

**Phase 1 — Initial Permutation**

Applying the IP table to rearrange all 64 plaintext bits:

$$\mathtt{123456ABCD132536} \xrightarrow{\;\text{IP}\;} \mathtt{14A7D67818CA18AD}$$

Split into two 32-bit halves:

$$L_0 = \mathtt{14A7D678}, \qquad R_0 = \mathtt{18CA18AD}$$

---

**Phase 2 — Key Schedule: Generating $K_1$**

Starting from key `AABB09182736CCDD`:
1. PC-1 drops the 8 parity bits → 56-bit key, split into $C_0$ (28 bits) and $D_0$ (28 bits).
2. Round 1 uses a 1-bit circular left-shift on both halves → $C_1, D_1$.
3. PC-2 selects and permutes 48 of the 56 bits:

$$K_1 = \mathtt{194CD072DE8C} \quad (48\text{-bit subkey in hex})$$

---

**Phase 3 — Round 1: Mangler Function $F(R_0, K_1)$**

**Step ①: Expansion of $R_0$ (32 → 48 bits)**

The E-box table expands $R_0 = \mathtt{18CA18AD}$ from 32 to 48 bits by duplicating 16 boundary bits. The expanded block is XORed with $K_1$.

**Step ②: XOR with $K_1$**

Writing the 48-bit result of $E(R_0) \oplus K_1$ as eight 6-bit chunks:

$$E(R_0) \oplus K_1 = \underbrace{\mathtt{101010}}_{c_1}\;\underbrace{\mathtt{010001}}_{c_2}\;\underbrace{\mathtt{011110}}_{c_3}\;\underbrace{\mathtt{111010}}_{c_4}\;\underbrace{\mathtt{100001}}_{c_5}\;\underbrace{\mathtt{100110}}_{c_6}\;\underbrace{\mathtt{010100}}_{c_7}\;\underbrace{\mathtt{100111}}_{c_8}$$

**Step ③: S-box Substitution — chunk $c_1$ in full detail**

For $c_1 = \mathtt{101010}$ entering **S1**:

| | Bits | Binary | Decimal |
|:---:|:---:|:---:|:---:|
| **Row** | outer bits $b_1 b_6 = \mathtt{1,\,0}$ | $\mathtt{10}$ | **2** |
| **Col** | inner bits $b_2 b_3 b_4 b_5 = \mathtt{0101}$ | $\mathtt{0101}$ | **5** |
| **S1[2][5]** | — | `0110` | **6** |

$$c_1 = \mathtt{101010} \;\xrightarrow{\text{S1}}\; \mathtt{0110}$$

Chunks $c_2$–$c_8$ are processed identically through S2–S8 respectively. Concatenating all eight 4-bit outputs produces the **32-bit S-box result**.

**Step ④: P-box Permutation**

The P-box rearranges the 32-bit S-box output according to its fixed table, spreading S-box outputs across S-box inputs in Round 2. Combined result:

$$F(R_0, K_1) = L_0 \oplus R_1 = \mathtt{14A7D678} \oplus \mathtt{5A78E394} = \mathtt{4EDF35EC}$$

---

**Phase 4 — Completing Round 1**

Applying the Feistel update rule:

$$L_1 = R_0 = \mathtt{18CA18AD}$$

$$R_1 = L_0 \oplus F(R_0, K_1) = \mathtt{14A7D678} \oplus \mathtt{4EDF35EC} = \mathtt{5A78E394}$$

**Round 1 output: $L_1 = \mathtt{18CA18AD}$, $R_1 = \mathtt{5A78E394}$** ✓

Rounds 2–16 repeat this process with subkeys $K_2, \ldots, K_{16}$, followed by the 32-bit swap and IP⁻¹ to produce the 64-bit ciphertext.
```

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

Each output byte depends on **all four** input bytes of the column, providing **full intra-column diffusion**. MixColumns is **omitted in the final round** to maintain the encrypt/decrypt symmetry.

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
Combining ShiftRows (inter-column spread) with MixColumns (intra-column mix) gives the **wide-trail strategy**: after just **2 full rounds**, every output bit depends on every input bit and every key bit. After 10 rounds this provides overwhelming avalanche — a 1-bit plaintext change flips ~50% of all ciphertext bits.
```

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

## 7. Interactive AES Demo

```{admonition} How to Make It Interactive
:class: note
Click the 🚀 **Live Code** button (top of page) to run the cell below. Modify `plaintext` and `key` to experiment.
```

```{code-cell} python
:tags: [thebe-init]

def xor_bytes(a, b):
    return bytes(x ^ y for x, y in zip(a, b))

# Minimal AES-128 ECB using Python's built-in library (no extra install needed)
try:
    from Crypto.Cipher import AES
    import os

    key = os.urandom(16)          # 128-bit random key
    plaintext = b"Hello, AES!!!"  # 13 bytes
    # Pad to 16 bytes (PKCS#7)
    pad_len = 16 - len(plaintext) % 16
    padded = plaintext + bytes([pad_len] * pad_len)

    cipher_ecb = AES.new(key, AES.MODE_ECB)
    ciphertext = cipher_ecb.encrypt(padded)

    cipher_gcm = AES.new(key, AES.MODE_GCM)
    ciphertext_gcm, tag = cipher_gcm.encrypt_and_digest(plaintext)

    print(f"Key (hex):            {key.hex()}")
    print(f"Plaintext:            {plaintext}")
    print(f"ECB ciphertext (hex): {ciphertext.hex()}")
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

## 8. Summary

| Concept | Definition | Cryptographic Role |
|:---|:---|:---|
| **Block cipher** | Keyed permutation on $n$-bit blocks | Core symmetric primitive |
| **Feistel network** | Split-half structure, invertible XOR | DES, Blowfish, CAST |
| **SPN** | Alternating Sub / Permute / Key-mix layers | AES, PRESENT |
| **Confusion** | S-box non-linearity | Resists known-plaintext attacks |
| **Diffusion** | ShiftRows + MixColumns spreading | Causes avalanche effect |
| **DES** | 56-bit key Feistel, 16 rounds | Broken — historical only |
| **3DES** | EDE triple application of DES | Deprecated |
| **AES** | 128-bit block SPN, 10/12/14 rounds | Current standard |
| **ECB** | Independent block encryption | Insecure — never use |
| **CBC** | Chained with IV | Legacy — needs separate MAC |
| **CTR** | Counter keystream, bit-flip malleable | IND-CPA — add MAC |
| **GCM** | CTR + GHASH authentication | IND-CCA — recommended |

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

---

```{bibliography}
:filter: docname in docnames
```
