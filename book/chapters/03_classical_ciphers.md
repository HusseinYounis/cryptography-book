# Chapter 3: Classical Ciphers

## Introduction

Classical ciphers are historical encryption methods that predate modern computers. While not secure by today's standards, they illustrate fundamental cryptographic concepts and provide insight into cryptanalysis techniques.

## Substitution Ciphers

Substitution ciphers replace each character in the plaintext with another character according to a fixed system.

### Caesar Cipher

The **Caesar cipher** is one of the oldest known ciphers, named after Julius Caesar who used it in his private correspondence.

```{admonition} Caesar Cipher Definition
:class: tip
Shifts each letter in the plaintext by a fixed number of positions in the alphabet.

**Encryption:** $C = (P + k) \mod 26$

**Decryption:** $P = (C - k) \mod 26$

where $k$ is the key (shift value).
```

**Example with $k = 3$:**
```
Plaintext:  ATTACK AT DAWN
Ciphertext: DWWDFN DW GDZQ
```

**Security Analysis:**
- **Key space:** Only 26 possible keys
- **Vulnerability:** Trivial to break by brute force
- **Attack method:** Try all 26 possible shifts

### Affine Cipher

The affine cipher extends the Caesar cipher using two keys.

```{admonition} Affine Cipher Definition
:class: tip
**Encryption:** $C = (aP + b) \mod 26$

**Decryption:** $P = a^{-1}(C - b) \mod 26$

where:
- $a$ and $b$ are keys
- $\gcd(a, 26) = 1$ (so that $a^{-1}$ exists)
```

**Example:** With $a = 5$, $b = 8$:
```
P = 7 (letter H)
C = (5 × 7 + 8) mod 26 = 43 mod 26 = 17 (letter R)
```

**Key Space:** $\phi(26) \times 26 = 12 \times 26 = 312$ possible keys

### Substitution Cipher (General)

A general substitution cipher uses an arbitrary permutation of the alphabet.

**Example:**
```
Plaintext alphabet:  ABCDEFGHIJKLMNOPQRSTUVWXYZ
Ciphertext alphabet: QWERTYUIOPASDFGHJKLZXCVBNM
```

**Security Analysis:**
- **Key space:** $26! \approx 4 \times 10^{26}$ possible keys
- **Vulnerability:** Frequency analysis
- **Attack method:** Statistical analysis of letter frequencies

## Frequency Analysis

Frequency analysis exploits the fact that in any language, certain letters and combinations occur more frequently than others.

### English Letter Frequencies

Most common letters in English (approximate):
1. E (12.7%)
2. T (9.1%)
3. A (8.2%)
4. O (7.5%)
5. I (7.0%)

```{tip}
Common words like "THE", "AND", "OF" can help identify patterns in ciphertext.
```

**Attack Strategy:**
1. Count frequency of each letter in ciphertext
2. Compare with known language statistics
3. Make educated guesses for high-frequency letters
4. Look for common patterns (double letters, common words)
5. Iteratively refine the mapping

## Polyalphabetic Ciphers

Polyalphabetic ciphers use multiple substitution alphabets to resist frequency analysis.

### Vigenère Cipher

The Vigenère cipher was considered unbreakable for centuries.

```{admonition} Vigenère Cipher Definition
:class: tip
Uses a keyword to determine the shift for each letter.

**Encryption:** $C_i = (P_i + K_{i \mod m}) \mod 26$

**Decryption:** $P_i = (C_i - K_{i \mod m}) \mod 26$

where:
- $K$ is the keyword
- $m$ is the length of the keyword
- The keyword repeats as needed
```

**Example:** With keyword "KEY":
```
Plaintext:  ATTACKATDAWN
Keyword:    KEYKEYKEYKEY
Ciphertext: KXVGOKXDOKFX
```

**Encryption Process:**
- A + K = K
- T + E = X
- T + Y = V
- And so on...

**Security Analysis:**
- **Strength:** Resists simple frequency analysis
- **Weakness:** Kasiski examination and index of coincidence
- **Key length:** Security increases with key length

### Breaking Vigenère: Kasiski Examination

```{prf:algorithm} Kasiski Examination
:label: kasiski-method

1. Find repeated sequences in ciphertext
2. Measure distances between repetitions
3. Find GCD of these distances
4. This likely gives key length
5. Perform frequency analysis on each position
```

**Example:** If "XYZ" appears at positions 10, 35, 60:
- Distances: 25, 25
- GCD(25, 25) = 25
- Likely key length: 5, 25, or a divisor

### Index of Coincidence

The **index of coincidence** (IC) measures how likely two randomly selected letters from a text are identical.

$$IC = \sum_{i=A}^{Z} p_i^2$$

where $p_i$ is the frequency of letter $i$.

**Values:**
- English text: IC ≈ 0.065
- Random text: IC ≈ 0.038
- Can be used to determine key length

## Transposition Ciphers

Transposition ciphers rearrange the positions of characters rather than substituting them.

### Rail Fence Cipher

Characters are written in a zigzag pattern and read row by row.

**Example with 3 rails:**
```
Plaintext: WEAREDISCOVEREDFLEEATONCE

W . . . E . . . C . . . R . . . L . . . T . . . E
. E . R . D . S . O . E . E . F . E . A . O . C .
. . A . . . I . . . V . . . D . . . E . . . N . .

Ciphertext: WECRLTEERDSOEEFEAOCAIVDEN
```

### Columnar Transposition

Text is written in rows and read column by column according to a key.

**Example with key "3142":**
```
Key:        3 1 4 2
Plaintext:  A T T A
            C K A T
            D A W N

Ciphertext: TKADT AAWN TATN C
           (column 1, 2, 3, 4 order)
```

## Product Ciphers

**Product ciphers** combine substitution and transposition to create stronger ciphers.

```{admonition} Design Principle
:class: note
Modern block ciphers (like AES) use multiple rounds of substitution and permutation—this is a form of product cipher.
```

## One-Time Pad

The One-Time Pad (OTP) is theoretically unbreakable.

```{admonition} One-Time Pad Definition
:class: tip
**Encryption:** $C_i = (P_i + K_i) \mod 26$

**Decryption:** $P_i = (C_i - K_i) \mod 26$

where:
- $K$ is a random key
- $|K| = |P|$ (key length equals message length)
- Each key is used only once
```

### Perfect Secrecy

```{prf:theorem} Shannon's Perfect Secrecy
:label: perfect-secrecy

The One-Time Pad provides **perfect secrecy** if:
1. The key is truly random
2. The key is at least as long as the message
3. The key is never reused
4. The key is kept completely secret
```

**Why It's Impractical:**
- Key distribution problem
- Key must be as long as message
- Key cannot be reused
- Difficult to generate truly random keys

## Breaking Classical Ciphers: Summary

| Cipher Type | Primary Weakness | Attack Method |
|-------------|------------------|---------------|
| Caesar | Small key space | Brute force |
| Affine | Small key space | Brute force or frequency analysis |
| Substitution | Letter frequencies | Frequency analysis |
| Vigenère | Repeating key | Kasiski, IC, frequency analysis |
| Transposition | Pattern preservation | Anagramming, pattern recognition |
| One-Time Pad | None (if used correctly) | Only vulnerable if rules violated |

## Historical Cryptanalysis

### The Enigma Machine

The German Enigma machine was considered unbreakable but was eventually cracked by Allied cryptanalysts, including Alan Turing.

**Why it was broken:**
- Operators made mistakes
- Repeated message formats
- Known plaintext attacks
- Cribs (guessed plaintext sections)

## Lessons for Modern Cryptography

Classical ciphers teach us:

1. **Security through obscurity fails** - Algorithm secrecy doesn't ensure security
2. **Key space matters** - But isn't everything
3. **Statistical properties persist** - Even with substitution
4. **Randomness is crucial** - Patterns can be exploited
5. **Perfect security requires perfect conditions** - OTP shows theoretical limits

## Summary

Classical ciphers introduced:
- ✅ Substitution ciphers (Caesar, Affine, General)
- ✅ Frequency analysis techniques
- ✅ Polyalphabetic ciphers (Vigenère)
- ✅ Transposition ciphers
- ✅ One-Time Pad and perfect secrecy
- ✅ Cryptanalysis methods

```{admonition} Next Steps
:class: tip
In the next chapter, we'll dive deeper into cryptanalysis and learn systematic approaches to breaking ciphers.
```

## Exercises

```{exercise}
:label: caesar-decrypt
Decrypt the following Caesar cipher (unknown shift):
WKLV LV D VHFUHW PHVVDJH
```

```{exercise}
:label: affine-encrypt
Encrypt "HELLO" using an affine cipher with $a = 7$ and $b = 3$.
```

```{exercise}
:label: vigenere-ex
Encrypt "CRYPTOGRAPHY" using the Vigenère cipher with keyword "MATH".
```

```{exercise}
:label: frequency-analysis
Given a ciphertext, describe the step-by-step process you would use to perform frequency analysis.
```

```{exercise}
:label: otp-ex
Explain why reusing a One-Time Pad key breaks perfect secrecy.
```

## Further Reading

- {cite}`stinson2018cryptography` - Chapter on classical cryptography
- {cite}`schneier2015applied` - Historical ciphers and their weaknesses
