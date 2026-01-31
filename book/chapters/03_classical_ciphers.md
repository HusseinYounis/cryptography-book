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

### Interactive Caesar Cipher Demo

Try the Caesar cipher yourself! Modify the plaintext and key below, then click "Run" to see the encryption and decryption in action.

```{code-cell} python
:tags: [thebe-init]

def caesar_encrypt(plaintext, key):
    """Encrypt plaintext using Caesar cipher with given key."""
    result = []
    for char in plaintext.upper():
        if char.isalpha():
            # Shift character by key positions
            shifted = chr((ord(char) - ord('A') + key) % 26 + ord('A'))
            result.append(shifted)
        else:
            # Keep non-alphabetic characters unchanged
            result.append(char)
    return ''.join(result)

def caesar_decrypt(ciphertext, key):
    """Decrypt ciphertext using Caesar cipher with given key."""
    # Decryption is encryption with negative key
    return caesar_encrypt(ciphertext, -key)

def display_caesar_demo(plaintext, key):
    """Display Caesar cipher encryption/decryption demo."""
    print("="*60)
    print("         CAESAR CIPHER DEMONSTRATION")
    print("="*60)
    print(f"\n📝 Original Plaintext:  {plaintext}")
    print(f"🔑 Shift Key:           {key}")
    print("-"*60)
    
    # Encrypt
    ciphertext = caesar_encrypt(plaintext, key)
    print(f"🔒 Encrypted:           {ciphertext}")
    
    # Decrypt
    decrypted = caesar_decrypt(ciphertext, key)
    print(f"🔓 Decrypted:           {decrypted}")
    print("="*60)
    
    # Show the shift mapping for first few letters
    print("\n📊 Shift Mapping (first 10 letters):")
    print("   Plaintext:  A B C D E F G H I J")
    print("   Ciphertext: ", end="")
    for char in "ABCDEFGHIJ":
        encrypted = caesar_encrypt(char, key)
        print(f"{encrypted} ", end="")
    print("\n" + "="*60)
    
    # Verify
    if plaintext.upper().replace(" ", "") == decrypted.replace(" ", ""):
        print("✅ Decryption successful! Original message recovered.")
    else:
        print("❌ Decryption failed!")
    print("="*60)

# Example usage - modify these values!
plaintext = "ATTACK AT DAWN"
key = 3

display_caesar_demo(plaintext, key)
```

```{admonition} Try It Yourself!
:class: tip
**Experiment with different values:**
- Change the `plaintext` to any message you want
- Try different `key` values (0-25)
- What happens with `key = 0`?
- What happens with `key = 26`?
- Try encrypting the ciphertext again with the same key!
```

### Brute Force Attack Demo

Since there are only 26 possible keys, we can try them all!

```{code-cell} python
:tags: [thebe-init]

def caesar_brute_force(ciphertext):
    """Try all possible Caesar cipher keys."""
    print("="*70)
    print("           CAESAR CIPHER BRUTE FORCE ATTACK")
    print("="*70)
    print(f"\n🎯 Ciphertext: {ciphertext}")
    print("-"*70)
    print("\nTrying all possible keys:\n")
    
    for key in range(26):
        decrypted = caesar_decrypt(ciphertext, key)
        # Highlight likely correct decryption (contains common words)
        common_words = ['THE', 'AND', 'ATTACK', 'MESSAGE', 'HELLO', 'DAWN']
        is_likely = any(word in decrypted for word in common_words)
        marker = "⭐" if is_likely else "  "
        
        print(f"{marker} Key {key:2d}: {decrypted}")
    
    print("="*70)
    print("⭐ = Likely correct decryption (contains common English words)")
    print("="*70)

# Try to crack this message!
ciphertext = "DWWDFN DW GDZQ"
caesar_brute_force(ciphertext)
```

```{admonition} Security Lesson
:class: warning
The Caesar cipher has only 26 possible keys, making it vulnerable to **brute force attack**. 
An attacker can simply try all possibilities in seconds!

**Key takeaway:** A cipher needs a sufficiently large key space to be secure.
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
