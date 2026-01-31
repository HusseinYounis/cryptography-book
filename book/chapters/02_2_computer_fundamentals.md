# Chapter 2.2: Computer Fundamentals for Cryptography

## Introduction

Before diving deeper into cryptographic algorithms, it's essential to understand how computers represent and manipulate data. At the most fundamental level, computers operate using only two states: 0 and 1. This chapter explores the binary world of computing and the operations that form the foundation of modern cryptographic implementations.

```{admonition} Why This Matters
:class: tip
Modern cryptography is implemented in software and hardware that operates exclusively with binary data. Understanding number systems, encoding schemes, and bitwise operations is crucial for implementing and analyzing cryptographic algorithms efficiently and securely.
```

## The Binary Foundation

### Digital Logic: The Language of Computers

Computers use electronic circuits that can be in one of two states:
- **0 (Low voltage)**: Typically represents "false" or "off"
- **1 (High voltage)**: Typically represents "true" or "on"

This binary system forms the basis of all digital computation. Every piece of data—text, numbers, images, encryption keys—is ultimately represented as a sequence of 0s and 1s.

### Binary Units

```{list-table} Fundamental Binary Units
:header-rows: 1
:name: binary-units

* - Unit
  - Size
  - Description
* - **Bit**
  - 1 binary digit
  - Smallest unit of data (0 or 1)
* - **Nibble**
  - 4 bits
  - Half a byte, one hexadecimal digit
* - **Byte**
  - 8 bits
  - Standard unit for character representation
* - **Word**
  - 16, 32, or 64 bits
  - Processor-dependent data unit
* - **Kilobyte (KB)**
  - 1,024 bytes
  - $2^{10}$ bytes
* - **Megabyte (MB)**
  - 1,024 KB
  - $2^{20}$ bytes
* - **Gigabyte (GB)**
  - 1,024 MB
  - $2^{30}$ bytes
```

```{note}
In computing, we use powers of 2 (1024) rather than powers of 10 (1000) because computer architecture is based on binary.
```

## Number Systems

### Decimal (Base-10)

The number system we use daily, with digits 0-9.

$$N_{10} = d_n \times 10^n + d_{n-1} \times 10^{n-1} + \ldots + d_1 \times 10^1 + d_0 \times 10^0$$

**Example:** $1234_{10} = 1 \times 10^3 + 2 \times 10^2 + 3 \times 10^1 + 4 \times 10^0$

### Binary (Base-2)

Uses only digits 0 and 1, the native language of computers.

$$N_2 = b_n \times 2^n + b_{n-1} \times 2^{n-1} + \ldots + b_1 \times 2^1 + b_0 \times 2^0$$

**Example:** $1011_2 = 1 \times 2^3 + 0 \times 2^2 + 1 \times 2^1 + 1 \times 2^0 = 11_{10}$

### Hexadecimal (Base-16)

Uses digits 0-9 and letters A-F (where A=10, B=11, ..., F=15).

```{list-table} Hexadecimal to Decimal Conversion
:header-rows: 1
:name: hex-decimal

* - Hex
  - Decimal
  - Binary
* - 0
  - 0
  - 0000
* - 1
  - 1
  - 0001
* - ...
  - ...
  - ...
* - 9
  - 9
  - 1001
* - A
  - 10
  - 1010
* - B
  - 11
  - 1011
* - C
  - 12
  - 1100
* - D
  - 13
  - 1101
* - E
  - 14
  - 1110
* - F
  - 15
  - 1111
```

**Example:** $2A3_{16} = 2 \times 16^2 + 10 \times 16^1 + 3 \times 16^0 = 675_{10}$

```{admonition} Why Hexadecimal in Cryptography?
:class: important
Hexadecimal is extensively used in cryptography because:
- One hex digit represents exactly 4 bits (1 nibble)
- Two hex digits represent exactly 1 byte
- Much more compact and readable than binary
- Easy conversion to/from binary
- Example: AES-256 key = 64 hex characters = 256 bits
```

### Octal (Base-8)

Uses digits 0-7. Less common in modern cryptography but occasionally seen in Unix permissions and legacy systems.

**Example:** $157_8 = 1 \times 8^2 + 5 \times 8^1 + 7 \times 8^0 = 111_{10}$

## Number System Conversions

### Decimal to Binary

**Division Method:**
1. Divide the decimal number by 2
2. Record the remainder
3. Continue dividing the quotient by 2
4. Read remainders from bottom to top

**Example: Convert** $45_{10}$ **to binary**

```
45 ÷ 2 = 22 remainder 1  ←─┐
22 ÷ 2 = 11 remainder 0    │
11 ÷ 2 = 5  remainder 1    │ Read upward
5  ÷ 2 = 2  remainder 1    │
2  ÷ 2 = 1  remainder 0    │
1  ÷ 2 = 0  remainder 1  ←─┘

Result: 101101₂
```

### Binary to Decimal

Sum the powers of 2 for each bit position with value 1.

**Example:** $101101_2 = 1×2^5 + 0×2^4 + 1×2^3 + 1×2^2 + 0×2^1 + 1×2^0 = 32 + 8 + 4 + 1 = 45_{10}$

### Binary to Hexadecimal

Group binary digits in sets of 4 (from right to left) and convert each group to hex.

**Example:** $11010111_2$

```
1101  0111
 ↓     ↓
 D     7

Result: D7₁₆
```

### Hexadecimal to Binary

Convert each hex digit to 4 binary digits.

**Example:** $3AF_{16}$

```
3     A     F
↓     ↓     ↓
0011  1010  1111

Result: 001110101111₂
```

## Character Encoding

### ASCII (American Standard Code for Information Interchange)

7-bit encoding (128 characters) for English text.

```{list-table} Common ASCII Values
:header-rows: 1
:name: ascii-table

* - Character
  - Decimal
  - Hex
  - Binary
* - 'A'
  - 65
  - 0x41
  - 01000001
* - 'Z'
  - 90
  - 0x5A
  - 01011010
* - 'a'
  - 97
  - 0x61
  - 01100001
* - 'z'
  - 122
  - 0x7A
  - 01111010
* - '0'
  - 48
  - 0x30
  - 00110000
* - '9'
  - 57
  - 0x39
  - 00111001
* - Space
  - 32
  - 0x20
  - 00100000
```

**Example:** "CAT" in ASCII
```
C: 67  = 0x43 = 01000011
A: 65  = 0x41 = 01000001
T: 84  = 0x54 = 01010100
```

### Extended ASCII

8-bit encoding (256 characters) including additional symbols and international characters.

### Unicode (UTF-8, UTF-16, UTF-32)

Universal character encoding supporting all world languages and symbols.

**UTF-8:**
- Variable-length encoding (1-4 bytes)
- Backward compatible with ASCII
- Most common on the web

### Base64 Encoding

Encodes binary data using 64 printable ASCII characters: A-Z, a-z, 0-9, +, /

**Character Set:**
```
ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/
```

**Algorithm:**
1. Take 3 bytes (24 bits) of input
2. Split into 4 groups of 6 bits
3. Convert each 6-bit group to Base64 character
4. Add '=' padding if needed

**Example:** Encode "Hi!"

```
Input:     H        i        !
Binary:    01001000 01101001 00100001
Grouped:   010010   000110   100100   100001
           ↓        ↓        ↓        ↓
Base64:    S        G        k        h

Result: "SGkh"
```

```{admonition} Base64 in Cryptography
:class: tip
Base64 is commonly used to:
- Encode binary encryption keys for text transmission
- Represent digital certificates (PEM format)
- Embed encrypted data in JSON/XML
- Email attachments (MIME)
```

### Hexadecimal Encoding

Each byte represented as two hex digits (00-FF).

**Example:** "Hello"
```
H: 0x48
e: 0x65
l: 0x6C
l: 0x6C
o: 0x6F

Hex: 48656C6C6F
```

## Bitwise Operations

### Basic Logic Gates

Fundamental operations used in cryptographic algorithms.

#### AND Operation (∧)

Returns 1 only if both bits are 1.

```{list-table} AND Truth Table
:header-rows: 1
:name: and-gate

* - A
  - B
  - A ∧ B
* - 0
  - 0
  - 0
* - 0
  - 1
  - 0
* - 1
  - 0
  - 0
* - 1
  - 1
  - 1
```

**Example:**
```
  10110011
∧ 11110000
-----------
  10110000
```

**Uses:** Masking, extracting specific bits, bit clearing.

#### OR Operation (∨)

Returns 1 if at least one bit is 1.

```{list-table} OR Truth Table
:header-rows: 1
:name: or-gate

* - A
  - B
  - A ∨ B
* - 0
  - 0
  - 0
* - 0
  - 1
  - 1
* - 1
  - 0
  - 1
* - 1
  - 1
  - 1
```

**Example:**
```
  10110011
∨ 11110000
-----------
  11110011
```

**Uses:** Setting specific bits, combining flags.

#### XOR Operation (⊕)

Returns 1 if bits are different, 0 if same.

```{list-table} XOR Truth Table
:header-rows: 1
:name: xor-gate

* - A
  - B
  - A ⊕ B
* - 0
  - 0
  - 0
* - 0
  - 1
  - 1
* - 1
  - 0
  - 1
* - 1
  - 1
  - 0
```

**Example:**
```
  10110011
⊕ 11110000
-----------
  01000011
```

```{admonition} XOR: The Heart of Cryptography
:class: important
XOR is fundamental to cryptography because:
- **Reversible:** $A ⊕ B ⊕ B = A$
- **Self-inverse:** $A ⊕ A = 0$
- **Used in:** Stream ciphers, one-time pad, block cipher modes
- **Example:** If plaintext ⊕ key = ciphertext, then ciphertext ⊕ key = plaintext
```

#### NOT Operation (¬)

Inverts all bits (1→0, 0→1).

```{list-table} NOT Truth Table
:header-rows: 1
:name: not-gate

* - A
  - ¬A
* - 0
  - 1
* - 1
  - 0
```

**Example:**
```
  10110011
¬ 
-----------
  01001100
```

**Uses:** Bit inversion, complementing data.

#### NAND, NOR, XNOR

**NAND:** NOT AND → $\overline{A \land B}$  
**NOR:** NOT OR → $\overline{A \lor B}$  
**XNOR:** NOT XOR → $\overline{A \oplus B}$ (equality check)

### Bit Shifting Operations

#### Left Shift (<<)

Shifts bits to the left, fills with 0s on the right.

**Example:** `10110011 << 2 = 11001100`

**Effect:** Multiplies by $2^n$ where n is shift amount  
`10110011 << 2` = multiply by 4

**Uses:** Fast multiplication, bit manipulation, alignment.

#### Right Shift (>>)

**Logical Right Shift:** Fills with 0s on the left.

**Example:** `10110011 >> 2 = 00101100`

**Effect:** Divides by $2^n$ (integer division)

**Arithmetic Right Shift:** Preserves sign bit (for signed integers).

**Example (signed):** `10110011 >> 2 = 11101100` (sign extended)

**Uses:** Fast division, extracting high-order bits.

### Rotation Operations

#### Circular Left Rotate (ROL)

Bits that fall off the left end reappear on the right.

**Example:** `ROL(10110011, 2) = 11001110`

```
10110011  →  11001110
↑↑                 ↑↑
└─────────────────┘
```

#### Circular Right Rotate (ROR)

Bits that fall off the right end reappear on the left.

**Example:** `ROR(10110011, 2) = 11101100`

```
10110011  →  11101100
  ↓↓       ↓↓
  └────────┘
```

```{admonition} Rotations in Cryptography
:class: tip
Rotation operations are used extensively in:
- **SHA hash functions:** Message schedule generation
- **DES cipher:** Key schedule and permutations
- **ChaCha20 stream cipher:** Quarter-round function
- **RC5/RC6 ciphers:** Data-dependent rotations
```

### Bit Masking

Using bitwise operations to isolate or modify specific bits.

#### Setting a Bit

```
Original:  10110011
Mask:      00001000  (bit 3)
Operation: OR
Result:    10111011
```

#### Clearing a Bit
```
Original:  10110011
Mask:      11110111  (NOT of bit 3)
Operation: AND
Result:    10110011
```

#### Toggling a Bit
```
Original:  10110011
Mask:      00001000  (bit 3)
Operation: XOR
Result:    10111011
```

#### Extracting Bits
```
Original:  10110011
Mask:      00111100  (extract bits 2-5)
Operation: AND
Result:    00110000
Shift:     >> 2
Final:     00001100  (value = 12)
```

## Practical Applications in Cryptography

### XOR Cipher (Stream Cipher Example)

```
Plaintext:  01001000 01100101 01101100 01101100 01101111  ("Hello")
Key:        10101010 10101010 10101010 10101010 10101010
           ⊕⊕⊕⊕⊕⊕⊕⊕ ⊕⊕⊕⊕⊕⊕⊕⊕ ⊕⊕⊕⊕⊕⊕⊕⊕ ⊕⊕⊕⊕⊕⊕⊕⊕ ⊕⊕⊕⊕⊕⊕⊕⊕
Ciphertext: 11100010 11001111 11000110 11000110 11000101
```

**Decryption (same operation):**
```
Ciphertext: 11100010 11001111 11000110 11000110 11000101
Key:        10101010 10101010 10101010 10101010 10101010
           ⊕⊕⊕⊕⊕⊕⊕⊕ ⊕⊕⊕⊕⊕⊕⊕⊕ ⊕⊕⊕⊕⊕⊕⊕⊕ ⊕⊕⊕⊕⊕⊕⊕⊕ ⊕⊕⊕⊕⊕⊕⊕⊕
Plaintext:  01001000 01100101 01101100 01101100 01101111  ("Hello")
```

### S-Box (Substitution Box)

Uses bit patterns as lookup indices:

```
Input:  1011 (11 in decimal)
S-Box:  [5, 2, 14, 11, ..., 9, 3, 7, 15]
Output: S[11] = 3 = 0011
```

### Permutation (P-Box)

Rearranges bit positions:

```
Input:     10110011
P-Box:     [3,7,2,6,1,5,0,4]  (new positions)
Output:    11001011
```

### Feistel Function

Combines XOR with function output:

```
Left:   10110011
Right:  11001100
F(R,K): 01010101
       ⊕
New R:  11100110
```

## Performance Considerations

### Why Bitwise Operations Matter

```{list-table} Operation Performance
:header-rows: 1
:name: perf-comparison

* - Operation Type
  - CPU Cycles (approx)
  - Speed
* - Bitwise (AND, OR, XOR)
  - 1
  - Fastest
* - Shift/Rotate
  - 1-2
  - Very Fast
* - Integer Addition
  - 1-3
  - Fast
* - Integer Multiplication
  - 3-5
  - Moderate
* - Division/Modulo
  - 20-40
  - Slow
```

### Optimization Examples

**Instead of:** `x * 8` (multiplication)  
**Use:** `x << 3` (left shift by 3)

**Instead of:** `x / 16` (division)  
**Use:** `x >> 4` (right shift by 4)

**Instead of:** `x % 256` (modulo)  
**Use:** `x & 0xFF` (AND mask)

## Summary

Understanding computer fundamentals is essential for cryptography because:

1. **Data Representation:** All cryptographic data is ultimately binary
2. **Efficiency:** Bitwise operations are the fastest operations available
3. **Algorithm Design:** Many ciphers rely heavily on bit manipulation
4. **Implementation:** Writing efficient cryptographic code requires low-level understanding
5. **Analysis:** Understanding bit patterns helps in cryptanalysis

```{admonition} Key Takeaways
:class: note
- Computers operate in binary (base-2)
- Hexadecimal provides compact representation of binary data
- XOR is fundamental to cryptographic operations
- Bitwise operations are extremely fast
- Shifts and rotations are used throughout cryptography
- Proper encoding/decoding is critical for data integrity
```

## Exercises

```{exercise}
:label: hex-conversion

Convert the following hexadecimal key to binary:
```
Key: 0xA5F3
```

What is the decimal value?
```

```{exercise}
:label: xor-cipher

Encrypt the message "CRYPTO" using the repeating key "KEY" with XOR.
Show your work in binary.
```

```{exercise}
:label: bit-masking-exercise

Given the byte `11010110`:
1. Set bit 3 to 1
2. Clear bit 6 to 0
3. Toggle bit 4
Show the mask and result for each operation.
```

```{exercise}
:label: rotation

Perform a left rotation by 3 positions on `10011101`.
Then perform a right rotation by 2 positions on the result.
What is the final value?
```

## Further Reading

- **"Hacker's Delight"** by Henry S. Warren Jr. - Advanced bit manipulation techniques
- **"Computer Systems: A Programmer's Perspective"** by Bryant & O'Hallaron - Low-level programming
- **"The Art of Computer Programming"** by Donald Knuth - Volume 2: Seminumerical Algorithms
