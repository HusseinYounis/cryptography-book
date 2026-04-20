# Chapter 2.2: Computer Fundamentals for Cryptography

```{figure} ../figures/ch02_2/computer_banner.jpg
:align: center
:width: 60%
```

---

::::{grid} 2

:::{grid-item-card} Binary & Number Systems
Working with binary, decimal, and hexadecimal representations that underlie all cryptographic data.
:::

:::{grid-item-card} Logic Gates
Boolean logic operations (AND, OR, XOR, NOT) as the hardware building blocks of cryptographic circuits.
:::

:::{grid-item-card} Bitwise Operations
Applying logic gates at the bit level for efficient cryptographic mixing, masking, and permuting.
:::

:::{grid-item-card} Character Encoding
ASCII and Unicode mappings from human-readable text to the byte sequences processed by ciphers.
:::

::::

```{admonition} Learning Objectives
:class: important
By the end of this chapter, you will be able to:
- Convert numbers between binary, decimal, and hexadecimal representations
- Describe the function of each basic logic gate (AND, OR, XOR, NOT, NAND, NOR)
- Perform bitwise AND, OR, XOR, and shift operations on binary values
- Explain why XOR is self-inverse and describe its role in stream ciphers
- Encode a string using ASCII and convert characters to their binary representation
```

---

## Warm-Up: Everything Is a Number

What does the computer actually store when you type the letter **"A"**?

```{admonition} Solution
:class: dropdown
The computer stores the number **65** in binary: **01000001**.

Every character, image, and cryptographic key is ultimately a sequence of 0s and 1s. Understanding this binary world is the foundation for implementing and attacking cryptographic algorithms.
```

---

## 1. Introduction

Before diving deeper into cryptographic algorithms, it is essential to understand how computers represent and manipulate data. At the most fundamental level, computers operate using only two states: **0** and **1**.

```{admonition} Why This Matters
:class: important
Modern cryptography is implemented in software and hardware that operates **exclusively with binary data**. Understanding number systems, encoding schemes, and bitwise operations is crucial for implementing and analyzing cryptographic algorithms efficiently and securely.
```

---

## 2. The Binary Foundation

### Digital Logic: The Language of Computers

Computers use electronic circuits that can be in one of **two states**:

```{figure} ../figures/ch02_2/binary_on_off.png
:align: center
:width: 40%

Binary states: 0 = Off (low voltage), 1 = On (high voltage)
```

| State | Voltage | Meaning |
|:---:|:---:|:---:|
| **0** | Low | False / Off |
| **1** | High | True / On |

This binary system forms the basis of all digital computation. Every piece of data — text, numbers, images, encryption keys — is ultimately represented as a **sequence of 0s and 1s**.

---

## 3. Binary Numbers

All digital content including text messages, emails, images, sounds and videos are converted into binary so that computers can process them. A **binary digit** (bit) has one of two possibilities: 0 or 1.

| Decimal | Binary |
|:---:|:---:|
| 0 | 0 |
| 1 | 1 |
| 2 | 10 |
| 3 | 11 |
| 4 | 100 |
| 5 | 101 |
| 6 | 110 |
| 7 | 111 |
| 8 | 1000 |
| 9 | 1001 |
| 10 | 1010 |

---

## 4. Binary Units

| Unit | Size | Description |
|:---|:---:|:---|
| **Bit** | 1 binary digit | Smallest unit of data (0 or 1) |
| **Nibble** | 4 bits | Half a byte; one hexadecimal digit |
| **Byte** | 8 bits | Standard unit for character representation |
| **Word** | 16, 32, or 64 bits | Processor-dependent data unit |
| **Kilobyte (KB)** | 1,024 bytes | $2^{10}$ bytes |
| **Megabyte (MB)** | 1,024 KB | $2^{20}$ bytes |
| **Gigabyte (GB)** | 1,024 MB | $2^{30}$ bytes |

```{note}
In computing, we use powers of 2 (1024) rather than powers of 10 (1000), because computer architecture is based on binary.
```

---

## 5. Number Systems

### 5.1 Overview

| System | Base | Digits Used | Example (Value = 26) |
|:---|:---:|:---|:---:|
| **Binary** | 2 | 0, 1 | `11010` |
| **Decimal** | 10 | 0–9 | `26` |
| **Hexadecimal** | 16 | 0–9, A–F | `1A` |

### 5.2 Binary (Base-2)

Uses only digits 0 and 1 — the native language of computers.

$$N_2 = b_n \times 2^n + b_{n-1} \times 2^{n-1} + \cdots + b_1 \times 2^1 + b_0 \times 2^0$$

**Example:**

$$1011_2 = 1 \times 2^3 + 0 \times 2^2 + 1 \times 2^1 + 1 \times 2^0 = 8 + 0 + 2 + 1 = 11_{10}$$

### 5.3 Decimal (Base-10)

The number system we use daily, with digits 0–9.

$$N_{10} = d_n \times 10^n + d_{n-1} \times 10^{n-1} + \cdots + d_1 \times 10^1 + d_0 \times 10^0$$

**Example:**

$$1234_{10} = 1 \times 10^3 + 2 \times 10^2 + 3 \times 10^1 + 4 \times 10^0 = 1000 + 200 + 30 + 4$$

### 5.4 Hexadecimal (Base-16)

Uses digits 0–9 and letters A–F (where A=10, B=11, ..., F=15).

```{admonition} Why Hexadecimal in Cryptography?
:class: important
- One hex digit represents exactly **4 bits** (1 nibble)
- Two hex digits represent exactly **1 byte**
- Much more compact and readable than binary
- Easy conversion to/from binary
- **Example:** An AES-256 key = 64 hex characters = 256 bits
```

```{figure} ../figures/ch02_2/hex_decimal_binary_table.png
:align: center
:width: 30%

Hexadecimal to Decimal to Binary reference table
```

---

## 6. Logic Gates

Logic gates are the **building blocks** of digital circuits and cryptographic hardware. Each gate performs a basic Boolean operation on one or two binary inputs and produces one output.

```{figure} ../figures/ch02_2/logic_gates.png
:align: center
:width: 90%

Logic gates: BUFFER, NOT, AND, OR, XOR, NAND, NOR, XNOR — with truth tables
```

| Gate | Symbol | Description | Key Property |
|:---:|:---:|:---|:---|
| **BUFFER** | → | Output equals input | Signal amplification |
| **NOT** | ¬ | Inverts the input | $0 \to 1$, $1 \to 0$ |
| **AND** | ∧ | Output is 1 only when both inputs are 1 | "This **and** that" |
| **OR** | ∨ | Output is 1 when at least one input is 1 | "This **or** that" |
| **XOR** | ⊕ | Output is 1 when inputs **differ** | "One or the other, not both" |
| **NAND** | ¬∧ | NOT-AND; opposite of AND | Universal gate |
| **NOR** | ¬∨ | NOT-OR; opposite of OR | Universal gate |
| **XNOR** | ≡ | Inverted XOR; 1 when inputs are equal | Equality test |

```{admonition} XOR in Cryptography
:class: important
The **XOR gate** is the most important logic operation in cryptography:
- It is the foundation of stream ciphers and one-time pads: $C = P \oplus K$
- Self-inverse: $(P \oplus K) \oplus K = P$ — XOR-ing twice restores the original
- Equal probability output: does not leak statistical information about the input
```

---

## 7. Bitwise Operations

Bitwise operations apply logic gates **bit by bit** across binary numbers. They are used extensively in cryptographic algorithms for mixing, masking, and permuting data.

```{figure} ../figures/ch02_2/bitwise_operations.png
:align: center
:width: 80%

Bitwise AND, OR, XOR, and Shift operations with worked examples
```

### Operation Summary

| Operation | Symbol | Purpose | Example |
|:---:|:---:|:---|:---|
| **AND** | `&` | Extract / mask specific bits | `60 & 6 = 4` |
| **OR** | `\|` | Set specific bits | `60 \| 6 = 62` |
| **XOR** | `^` | Flip / toggle specific bits | `60 ^ 6 = 58` |
| **Left Shift** | `<<` | Multiply by $2^k$ | `60 << 1 = 120` |
| **Right Shift** | `>>` | Divide by $2^k$ | `60 >> 2 = 15` |

---

## 8. Character Encoding

### 8.1 Key Idea

At the hardware level, computers only understand **bytes** — sequences of 8 bits representing values from 0 to 255. Character encoding provides the **mapping rules** between byte values and human-readable characters.

This standardization is crucial for:
- **Data exchange** — different systems interpret text consistently
- **Cryptography** — converting plaintext to processable binary data
- **Storage** — efficiently representing text in computer memory
- **Communication** — transmitting text across networks reliably

### 8.2 ASCII

**ASCII** (American Standard Code for Information Interchange) is a 7-bit encoding (128 characters) for English text. It associates each letter and punctuation mark with a unique numeric representation, and is the **foundation of text encoding** in cryptography and computing.

```{figure} ../figures/ch02_2/ascii_table.png
:align: center
:width: 100%

Full ASCII table (values 0–127)
```

**Key values to know:**

| Character | Decimal | Hex | Binary |
|:---:|:---:|:---:|:---:|
| `'A'` | 65 | `0x41` | `01000001` |
| `'a'` | 97 | `0x61` | `01100001` |
| `'0'` | 48 | `0x30` | `00110000` |
| Space | 32 | `0x20` | `00100000` |

### 8.3 Getting ASCII Values in C++

In C++, characters (`char`) are stored as integers using their ASCII values. Simply **cast the char to an integer type** to read the value.

```cpp
#include <iostream>
using namespace std;

int main() {
    char letter = 'A';
    int ascii = (int)letter;
    cout << "ASCII of '" << letter << "' is " << ascii << endl;
    return 0;
}
```

**Output:** `ASCII of 'A' is 65`

### 8.4 Unicode and `char32_t` in C++

Standard `char` in C++ is 1 byte (values 0–255). Emojis and characters from non-Latin scripts require **Unicode** code points that do not fit in a single byte.

**Solution:** Use `char32_t` — a 4-byte type that holds full Unicode code points.

```cpp
#include <iostream>
int main() {
    char32_t emoji = U'😀';    // char32_t literal
    std::cout << "Code point: " << (unsigned int)emoji << std::endl;
    return 0;
}
```

### 8.5 Python ASCII Functions

Python provides built-in functions for ASCII conversion:

| Function | Description |
|:---|:---|
| `ord(char)` | Returns the ASCII code of a character |
| `chr(code)` | Returns the character for an ASCII code |
| `format(num, '08b')` | Converts number to 8-bit binary string |
| `format(num, '02X')` | Converts number to 2-digit hexadecimal string |

```{figure} ../figures/ch02_2/python_ascii_code.png
:align: center
:width: 80%

Python code: converting a character to ASCII, binary, and hexadecimal
```

**Code:**

```python
char = 'A'

ascii_code = ord(char)
print(f"Character: {char} → ASCII code: {ascii_code}")

restored_char = chr(ascii_code)
print(f"ASCII code: {ascii_code} → Character: {restored_char}")

binary = format(ascii_code, '08b')
print(f"ASCII code: {ascii_code} → Binary (8-bit): {binary}")

hexadecimal = format(ascii_code, '02X')
print(f"ASCII code: {ascii_code} → Hexadecimal (2-digit): {hexadecimal}")
```

**Output:**
```
Character: A → ASCII code: 65
ASCII code: 65 → Character: A
ASCII code: 65 → Binary (8-bit): 01000001
ASCII code: 65 → Hexadecimal (2-digit): 41
```

---

## Summary

| Concept | Key Facts |
|:---|:---|
| **Binary** | Base-2; only 0 and 1; language of all digital hardware |
| **Binary Units** | Bit → Nibble (4) → Byte (8) → Word → KB/MB/GB |
| **Number Systems** | Binary (2), Decimal (10), Hexadecimal (16) |
| **Hex** | 1 hex digit = 4 bits; 2 hex digits = 1 byte; compact key representation |
| **Logic Gates** | AND, OR, XOR, NOT, NAND, NOR, XNOR — building blocks of circuits |
| **XOR** | Self-inverse bitwise operation; core of stream ciphers and OTP |
| **Bitwise Ops** | AND (mask), OR (set), XOR (flip), Shift (scale) |
| **ASCII** | 7-bit encoding; 128 characters; maps letters to numbers |
| **Unicode** | Universal encoding for all world scripts; `char32_t` for 4-byte code points |

---

## Exercises

```{exercise} Number System Conversions
:label: ch02-2-ex-convert

Convert the following:
- (a) $1101_2$ to decimal
- (b) $47_{10}$ to binary
- \(c) $3F_{16}$ to binary
- (d) $10110110_2$ to hexadecimal
```

```{solution} ch02-2-ex-convert
:label: sol-ch02-2-ex-convert
:class: dropdown

(a) $1101_2 = 8+4+1 = 13_{10}$

(b) $47 \div 2$: remainders bottom-to-top → $101111_2$

\(c) $3 = 0011$, $F = 1111$ → $00111111_2$

(d) Group: $1011\ 0110$ → $B6_{16}$
```

```{exercise} Bitwise Operations
:label: ch02-2-ex-bitwise

Compute the following bitwise operations on $a = 0b10110100$ (= 180) and $b = 0b00111001$ (= 57):
- (a) $a$ AND $b$
- (b) $a$ OR $b$
- \(c) $a$ XOR $b$
- (d) $a$ right-shifted by 2
```

```{solution} ch02-2-ex-bitwise
:label: sol-ch02-2-ex-bitwise
:class: dropdown

~~~
  a: 10110100
  b: 00111001

(a) AND:  00110000 = 48
(b) OR:   10111101 = 189
\(c) XOR:  10001101 = 141
(d) >>2:  00101101 = 45
~~~
```

```{exercise} XOR Truth Table and Self-Inverse
:label: ch02-2-ex-xor

Fill in the truth table for XOR:

| A | B | A XOR B |
|:---:|:---:|:---:|
| 0 | 0 | ? |
| 0 | 1 | ? |
| 1 | 0 | ? |
| 1 | 1 | ? |

Then explain why XOR is self-inverse: $(P \oplus K) \oplus K = P$.
```

```{solution} ch02-2-ex-xor
:label: sol-ch02-2-ex-xor
:class: dropdown

| A | B | A XOR B |
|:---:|:---:|:---:|
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

For self-inverse: $P \oplus K$ flips the bits of $P$ wherever $K=1$. Then XOR-ing again with the same $K$ flips those same bits back, restoring $P$ exactly. Formally, $x \oplus x = 0$ for any $x$, so $(P \oplus K) \oplus K = P \oplus (K \oplus K) = P \oplus 0 = P$.
```

```{exercise} ASCII String Encoding
:label: ch02-2-ex-ascii

Write the string `"HI"` as:
- (a) ASCII decimal values
- (b) 8-bit binary
- \(c) Hexadecimal
```

```{solution} ch02-2-ex-ascii
:label: sol-ch02-2-ex-ascii
:class: dropdown

(a) H=72, I=73

(b) H: 01001000, I: 01001001

\(c) H: 48, I: 49 (hex)
```

```{exercise} XOR Encryption and Decryption
:label: ch02-2-ex-encryption

Encrypt the byte $P = 0b10110011$ (= 179) with the key $K = 0b11001010$ (= 202) using XOR. Then decrypt by XOR-ing the ciphertext with the same key. Verify you recover $P$.
```

```{solution} ch02-2-ex-encryption
:label: sol-ch02-2-ex-encryption
:class: dropdown

~~~
  P: 10110011
  K: 11001010
  C = P⊕K: 01111001 = 121

  C: 01111001
  K: 11001010
  P' = C⊕K: 10110011 = 179 ✓
~~~

$P' = P$, confirming XOR decryption works.
```
