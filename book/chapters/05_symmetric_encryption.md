# Chapter 5: Symmetric Encryption

## Introduction

Symmetric encryption, also called **secret-key cryptography**, uses the same key for both encryption and decryption. It's the foundation of modern cryptographic systems.

```{admonition} Symmetric Encryption
:class: tip
- Uses a single shared key
- Fast and efficient
- Suitable for bulk data encryption
- Main challenge: secure key distribution
```

## Stream Ciphers vs Block Ciphers

Symmetric ciphers are categorized into two types:

### Stream Ciphers
- Encrypt data **one bit or byte at a time**
- Use a keystream generator
- Examples: RC4, ChaCha20, Salsa20

### Block Ciphers
- Encrypt data in **fixed-size blocks**
- Typical block sizes: 64 bits, 128 bits
- Examples: DES, 3DES, AES

## Stream Ciphers

Stream ciphers generate a pseudorandom keystream that is XORed with the plaintext.

```{admonition} Stream Cipher Operation
:class: note
**Encryption:** $C_i = P_i \oplus K_i$

**Decryption:** $P_i = C_i \oplus K_i$

where $K_i$ is the keystream bit and $\oplus$ represents XOR operation.
```

### Linear Feedback Shift Registers (LFSR)

LFSRs are used to generate pseudorandom sequences in stream ciphers.

```{prf:algorithm} LFSR
:label: lfsr-algorithm

A sequence of bits $s_0, s_1, s_2, \ldots$ where each bit is determined by:

$$s_n = c_1s_{n-1} + c_2s_{n-2} + \cdots + c_Ls_{n-L} \pmod 2$$

where $c_1, \ldots, c_L \in \{0, 1\}$ are the feedback coefficients.
```

**Example:** 4-bit LFSR with feedback polynomial $x^4 + x + 1$:
- Initial state: 1000
- Next states: 0100 → 0010 → 0001 → 1000 (repeats)

### RC4 Stream Cipher

RC4 was widely used (WEP, WPA, SSL/TLS) but now considered insecure.

**Properties:**
- Variable key size (40-2048 bits)
- Simple algorithm
- Fast in software
- **Vulnerabilities:** Biases in keystream, weak keys

### Modern Stream Ciphers

**ChaCha20:**
- Designed by Daniel J. Bernstein
- Used in TLS, Google Chrome, Android
- Very fast and secure
- 256-bit key, 64-bit nonce

## Block Cipher Fundamentals

Block ciphers encrypt fixed-size blocks of data.

### Feistel Network

Many block ciphers use a Feistel network structure.

```{prf:algorithm} Feistel Network
:label: feistel-network

**Structure:** Data block split into left (L) and right (R) halves

**Round function:**
$$L_{i+1} = R_i$$
$$R_{i+1} = L_i \oplus F(R_i, K_i)$$

where $F$ is the round function and $K_i$ is the round key.

**Advantage:** Encryption and decryption use the same structure (just reverse key order).
```

### Substitution-Permutation Network (SPN)

Alternative to Feistel networks, used by AES.

**Components:**
1. **Substitution (S-box):** Provides confusion
2. **Permutation (P-box):** Provides diffusion
3. **Key mixing:** XOR with round key

### Confusion and Diffusion

Shannon's principles for cipher design:

```{admonition} Shannon's Principles
:class: tip
**Confusion:** Relationship between ciphertext and key should be complex
- Achieved through substitution

**Diffusion:** Each plaintext bit should influence many ciphertext bits
- Achieved through permutation
```

## Data Encryption Standard (DES)

DES was the federal standard from 1977-2001.

**Specifications:**
- Block size: 64 bits
- Key size: 56 bits (plus 8 parity bits)
- 16 rounds
- Feistel network structure

```{warning}
DES is no longer secure due to small key size. It can be broken by brute force in hours.
```

### Triple DES (3DES)

To extend DES's life, Triple DES was developed.

**Operation:**
$$C = E_{K_3}(D_{K_2}(E_{K_1}(P)))$$

**Properties:**
- Effective key length: 168 bits (3 × 56)
- Secure but slow
- Being phased out in favor of AES

## Advanced Encryption Standard (AES)

AES replaced DES in 2001 after a public competition.

```{admonition} AES Specifications
:class: tip
- **Block size:** 128 bits
- **Key sizes:** 128, 192, or 256 bits
- **Rounds:** 10, 12, or 14 (depends on key size)
- **Structure:** Substitution-Permutation Network
```

### AES Operations

Each round consists of four operations:

1. **SubBytes:** Byte substitution using S-box
2. **ShiftRows:** Cyclical shift of rows
3. **MixColumns:** Mix columns for diffusion (not in last round)
4. **AddRoundKey:** XOR with round key

```{admonition} AES Security
:class: note
AES-128 is considered secure against all known attacks. Even with quantum computers, AES-256 provides adequate security.
```

### AES S-Box

The S-box provides non-linearity:
- Maps each byte to another byte
- Designed to resist known attacks
- Based on multiplicative inverse in GF(2^8)

## Block Cipher Modes of Operation

Block ciphers need modes of operation to encrypt messages longer than one block.

### Electronic Codebook (ECB) Mode

**Operation:**
$$C_i = E_K(P_i)$$

```{danger}
**Never use ECB mode!**
- Identical plaintext blocks produce identical ciphertext blocks
- Patterns in plaintext are visible in ciphertext
- Not semantically secure
```

### Cipher Block Chaining (CBC) Mode

**Encryption:**
$$C_i = E_K(P_i \oplus C_{i-1})$$
$$C_0 = IV$$ (Initialization Vector)

**Decryption:**
$$P_i = D_K(C_i) \oplus C_{i-1}$$

**Properties:**
- Requires IV
- Sequential (not parallelizable for encryption)
- Errors propagate to next block only

### Counter (CTR) Mode

**Encryption/Decryption:**
$$C_i = P_i \oplus E_K(\text{nonce} || \text{counter}_i)$$

**Properties:**
- Turns block cipher into stream cipher
- Parallelizable
- Random access
- Requires unique nonce for each message

### Galois/Counter Mode (GCM)

GCM combines CTR mode with authentication.

**Features:**
- Provides both encryption and authentication
- Very fast and parallelizable
- Widely used (TLS, IPsec, SSH)

```{admonition} Authenticated Encryption
:class: tip
GCM provides:
- **Confidentiality** (encryption)
- **Authenticity** (message authentication)
- **Integrity** (detects tampering)
```

## Padding

When plaintext length isn't a multiple of block size, padding is needed.

### PKCS#7 Padding

Most common padding scheme:
- Add $n$ bytes, each with value $n$
- Where $n$ is the number of padding bytes needed

**Example:** If 3 bytes needed:
```
Original: [XX XX XX XX XX]
Padded:   [XX XX XX XX XX 03 03 03]
```

### Padding Oracle Attack

```{warning}
Improper padding validation can lead to **padding oracle attacks**, allowing attackers to decrypt ciphertext without the key.
```

## Key Derivation

Deriving encryption keys from passwords or other secrets.

### PBKDF2

Password-Based Key Derivation Function 2:

$$\text{DK} = \text{PBKDF2}(\text{PRF}, \text{Password}, \text{Salt}, c, \text{dkLen})$$

where:
- PRF: Pseudorandom function (e.g., HMAC-SHA256)
- $c$: Iteration count
- dkLen: Desired key length

**Purpose:**
- Slow down brute-force attacks
- Derive cryptographic keys from passwords

## Performance Considerations

Typical speeds on modern hardware (approximate):

| Algorithm | Speed (GB/s) | Notes |
|-----------|--------------|-------|
| AES-128-GCM (hardware) | 10-50 | With AES-NI instructions |
| AES-128-CBC (hardware) | 5-20 | With AES-NI instructions |
| ChaCha20 (software) | 1-3 | Very fast without hardware support |
| 3DES | 0.1-0.5 | Much slower than AES |

## Best Practices

```{admonition} Recommendations
:class: tip
✅ **Use:** AES-GCM with 128-bit or 256-bit keys

✅ **Key Management:** Use proper key derivation (PBKDF2, Argon2)

✅ **IVs/Nonces:** Always use random and unique

❌ **Avoid:** ECB mode, DES, RC4

❌ **Don't:** Implement your own crypto, reuse IVs
```

## Summary

Key concepts covered:
- ✅ Stream vs block ciphers
- ✅ Feistel networks and SPNs
- ✅ DES, 3DES, and AES
- ✅ Modes of operation (ECB, CBC, CTR, GCM)
- ✅ Padding schemes
- ✅ Key derivation

```{admonition} Next Steps
:class: tip
The next chapter explores block ciphers in greater depth, including design principles and security analysis.
```

## Exercises

```{exercise}
:label: stream-vs-block
Compare stream ciphers and block ciphers. In what scenarios would you prefer one over the other?
```

```{exercise}
:label: cbc-iv
Explain why the IV must be unpredictable in CBC mode.
```

```{exercise}
:label: ecb-weakness
Describe a practical attack scenario where ECB mode's weakness could be exploited.
```

```{exercise}
:label: gcm-benefits
What are the advantages of using AES-GCM over AES-CBC?
```

## Further Reading

- {cite}`katz2020introduction` - Modern symmetric encryption
- {cite}`schneier2015applied` - Block cipher design and analysis
