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

---

## 2. Feistel Networks

Most block ciphers built before 2000 (including DES) use the **Feistel structure**, which elegantly unifies encryption and decryption into the same circuit.

```{prf:definition} Feistel Network
:label: def-feistel

A **Feistel network** with $r$ rounds processes a $2n$-bit block as two $n$-bit halves $(L_0, R_0)$:

**Encryption round $i$ ($1 \leq i \leq r$):**

$$L_i = R_{i-1}$$
$$R_i = L_{i-1} \oplus F(R_{i-1},\; K_i)$$

where $F$ is the **round function** (need not be invertible) and $K_i$ is the $i$-th **subkey**.

**Ciphertext:** $(L_r,\; R_r)$

**Decryption:** Apply the same structure with subkeys in **reverse order**: $(K_r, K_{r-1}, \ldots, K_1)$.
```

```{admonition} Why Feistel Networks Are Elegant
:class: important
The round function $F$ does **not** need to be invertible. Inversion is achieved by the XOR structure of the network itself. This means the same hardware/software circuit encrypts and decrypts — only the key schedule is reversed. DES's entire 16-round structure is symmetric; the chip from 1977 decrypts by reversing the key order.
```

```{prf:example} Two-Round Feistel Trace
:label: ex-feistel-trace

**Input:** $L_0 = 1010$, $R_0 = 1100$; subkeys $K_1 = 0110$, $K_2 = 1001$; round function $F(R, K) = R \oplus K$.

**Round 1:**
$$L_1 = R_0 = 1100$$
$$R_1 = L_0 \oplus F(R_0, K_1) = 1010 \oplus (1100 \oplus 0110) = 1010 \oplus 1010 = 0000$$

**Round 2:**
$$L_2 = R_1 = 0000$$
$$R_2 = L_1 \oplus F(R_1, K_2) = 1100 \oplus (0000 \oplus 1001) = 1100 \oplus 1001 = 0101$$

**Ciphertext:** $(L_2, R_2) = (0000,\; 0101)$

**Decryption** reverses with $K_2$ first, $K_1$ second — recovers $(L_0, R_0) = (1010,\; 1100)$.
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

### 4.1 Triple DES (3DES)

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

## 5. Advanced Encryption Standard (AES)

AES was selected in 2001 after a five-year public competition run by NIST. The winner — the **Rijndael** cipher by Joan Daemen and Vincent Rijmen — remains the global symmetric encryption standard.

```{prf:definition} AES
:label: def-aes

**AES (Advanced Encryption Standard)** is an SPN block cipher:

| Parameter | Value |
|:---:|:---:|
| Block size | 128 bits (16 bytes) |
| Key sizes | 128, 192, or 256 bits |
| Rounds | 10 (AES-128), 12 (AES-192), 14 (AES-256) |
| State | 4×4 matrix of bytes |

AES operates on a **4×4 byte state matrix**. Each round (except the last) applies four operations in sequence.
```

### 5.1 The Four Round Operations

```{prf:algorithm} AES Round
:label: algo-aes-round

**Input:** 4×4 byte state matrix $S$, round key $K_i$

**Output:** Updated state

1. **SubBytes** — replace each byte $b$ with $S\text{-box}(b)$: a non-linear bijection over $\text{GF}(2^8)$ (provides confusion)

2. **ShiftRows** — cyclically left-shift each row $r$ by $r$ positions:
   - Row 0: no shift
   - Row 1: shift left by 1
   - Row 2: shift left by 2
   - Row 3: shift left by 3
   (spreads bytes across columns — diffusion)

3. **MixColumns** — multiply each column by a fixed $4 \times 4$ matrix over $\text{GF}(2^8)$: each output byte depends on all 4 input bytes of the column (diffusion)
   *(Omitted in the final round)*

4. **AddRoundKey** — XOR the state with the 128-bit round subkey $K_i$
```

```{admonition} Why This Matters in Cryptography
:class: important
The structure ensures that after just **2 rounds**, every output bit depends on every input bit and every key bit — the **full diffusion** guarantee. After **10 rounds** (AES-128), the cipher provides 128-bit security against all known attacks, including quantum Grover search which reduces security to 64 bits for AES-128 and 128 bits for AES-256.
```

### 5.2 AES Key Schedule

```{prf:algorithm} AES Key Expansion (overview)
:label: algo-aes-keyschedule

**Input:** Key $K$ of 128/192/256 bits

**Output:** $N_r + 1$ round keys of 128 bits each ($N_r$ = number of rounds)

The key schedule expands $K$ into $44$ (AES-128), $52$ (AES-192), or $60$ (AES-256) 32-bit words using:
- **RotWord** — circular left-shift of 4 bytes
- **SubWord** — apply AES S-box to each byte
- **Rcon** — XOR with round constant $x^{i-1}$ over $\text{GF}(2^8)$
```

### 5.3 AES Security

```{admonition} AES Security Status (2026)
:class: tip

| Variant | Key bits | Classical security | Post-quantum security |
|:---:|:---:|:---:|:---:|
| AES-128 | 128 | 128 bits | ~64 bits (Grover) |
| AES-192 | 192 | 192 bits | ~96 bits |
| **AES-256** | **256** | **256 bits** | **~128 bits** — quantum-safe |

No attack significantly better than brute force is known against any AES variant. **AES-256** is the recommended choice for long-term (post-quantum) security.
```

::::{question} AES Round Operations
:type: multiple-choice
:variant: single-select
:showanswer:

Which AES round operation is responsible for ensuring that a change in one byte of the state affects all four bytes in the same column?
---
[ ] SubBytes
> SubBytes operates on each byte independently using the S-box — it does not spread influence between bytes.
[ ] ShiftRows
> ShiftRows moves bytes between columns but does not mix bytes within a column.
[x] MixColumns
> Correct! MixColumns multiplies each column by a 4×4 matrix over GF(2⁸), so each output byte depends on all 4 input bytes of that column — this is the primary diffusion step within a column.
[ ] AddRoundKey
> AddRoundKey XORs the state with the round key — it introduces key material but does not mix bytes among each other.
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

Using the same parameters as {prf:ref}`ex-feistel-trace` ($K_1=0110$, $K_2=1001$, $F(R,K)=R \oplus K$), decrypt the ciphertext $(L_2, R_2) = (0000, 0101)$ and verify you recover $(L_0, R_0) = (1010, 1100)$.
```

```{solution} ch08-ex-feistel
:label: sol-ch08-ex-feistel
:class: dropdown

Decryption applies the rounds in reverse with reversed key order ($K_2$ first, then $K_1$):

**Decryption round 2** (undo encryption round 2, using $K_2 = 1001$):

$$R_1 = L_2 = 0000$$
$$L_1 = R_2 \oplus F(L_2, K_2) = 0101 \oplus (0000 \oplus 1001) = 0101 \oplus 1001 = 1100$$

**Decryption round 1** (undo encryption round 1, using $K_1 = 0110$):

$$R_0 = L_1 = 1100$$
$$L_0 = R_1 \oplus F(L_1, K_1) = 0000 \oplus (1100 \oplus 0110) = 0000 \oplus 1010 = 1010$$

**Recovered plaintext:** $(L_0, R_0) = (1010,\; 1100)$ ✓
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
