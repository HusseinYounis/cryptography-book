# Chapter 1: Introduction to Cryptography

## What is Cryptography?

**Cryptography** is the science and art of securing communication and information through the use of codes and ciphers. The word comes from the Greek words *kryptos* (hidden) and *graphein* (writing).

```{admonition} Definition: Cryptography
:class: tip
Cryptography is the practice and study of techniques for secure communication in the presence of adversarial behavior.
```

## Historical Context

Cryptography has been used throughout history to protect sensitive information:

- **Ancient Rome**: Julius Caesar used a simple substitution cipher (Caesar cipher) to communicate with his generals
- **World War II**: The Enigma machine was used by Nazi Germany, and its breaking by Allied cryptanalysts significantly impacted the war
- **Modern Era**: With the advent of computers, cryptography has become essential for digital security

## Goals of Cryptography

Cryptography aims to achieve several security objectives:

### 1. Confidentiality
Ensuring that information is accessible only to those authorized to access it.

### 2. Integrity
Ensuring that information has not been altered or tampered with.

### 3. Authentication
Verifying the identity of users and the origin of messages.

### 4. Non-repudiation
Ensuring that a party cannot deny the authenticity of their signature or the sending of a message.

## Basic Terminology

```{glossary}
Plaintext
  The original, readable message or data before encryption.

Ciphertext
  The encrypted, unreadable form of the plaintext.

Encryption
  The process of converting plaintext into ciphertext.

Decryption
  The process of converting ciphertext back into plaintext.

Key
  A piece of information used in conjunction with an algorithm to perform encryption or decryption.

Algorithm
  A mathematical procedure or set of rules used for encryption and decryption.
```

## The Cryptographic Process

The basic cryptographic process can be visualized as follows:

$$
\text{Plaintext} \xrightarrow{\text{Encryption with Key}} \text{Ciphertext} \xrightarrow{\text{Decryption with Key}} \text{Plaintext}
$$

More formally:
- Encryption: $C = E_K(P)$
- Decryption: $P = D_K(C)$

Where:
- $P$ = Plaintext
- $C$ = Ciphertext
- $K$ = Key
- $E_K$ = Encryption function with key $K$
- $D_K$ = Decryption function with key $K$

## Types of Cryptography

### Symmetric Cryptography
Uses the same key for both encryption and decryption.

**Advantages:**
- Fast and efficient
- Suitable for encrypting large amounts of data

**Disadvantages:**
- Key distribution problem
- Requires secure channel for key exchange

### Asymmetric Cryptography
Uses a pair of keys: a public key for encryption and a private key for decryption.

**Advantages:**
- Solves key distribution problem
- Enables digital signatures

**Disadvantages:**
- Slower than symmetric encryption
- More computationally intensive

## Kerckhoffs's Principle

```{important}
**Kerckhoffs's Principle** (1883): A cryptographic system should be secure even if everything about the system, except the key, is public knowledge.

In other words: *The security of a cryptosystem should depend only on the secrecy of the key, not the secrecy of the algorithm.*
```

This principle is fundamental to modern cryptography and emphasizes that:
- Algorithms should be publicly known and scrutinized
- Security through obscurity is not reliable
- Only the key needs to be kept secret

## Security Levels

Cryptographic systems can provide different levels of security:

1. **Computational Security**: Cannot be broken with available computational resources in a reasonable time
2. **Provable Security**: Security can be proven under certain mathematical assumptions
3. **Unconditional Security**: Secure even against adversaries with unlimited computational power (e.g., One-Time Pad)

## Threat Models

Understanding potential attackers is crucial:

### Ciphertext-Only Attack
Adversary has access only to ciphertext.

### Known-Plaintext Attack
Adversary has access to some plaintext-ciphertext pairs.

### Chosen-Plaintext Attack
Adversary can choose plaintexts and obtain corresponding ciphertexts.

### Chosen-Ciphertext Attack
Adversary can choose ciphertexts and obtain corresponding plaintexts.

## Example: Caesar Cipher

Let's look at a simple example to illustrate basic concepts:

The **Caesar cipher** shifts each letter in the plaintext by a fixed number of positions in the alphabet.

```{admonition} Example
:class: note
With a shift of 3:
- Plaintext: HELLO
- Ciphertext: KHOOR

Encryption rule: $C = (P + 3) \mod 26$
Decryption rule: $P = (C - 3) \mod 26$
```

**Security Analysis:**
- Very weak by modern standards
- Only 26 possible keys (easy to brute force)
- Vulnerable to frequency analysis
- Good for learning basic concepts!

## Modern Applications

Cryptography is everywhere in modern digital life:

- 🔒 **HTTPS**: Securing web communications
- 💳 **Online Banking**: Protecting financial transactions
- 📱 **Messaging Apps**: End-to-end encryption (WhatsApp, Signal)
- 🔐 **Password Storage**: Hashing and salting
- 💰 **Cryptocurrencies**: Bitcoin, Ethereum
- 🆔 **Digital Signatures**: Authentication and non-repudiation

## Summary

In this chapter, we introduced:
- The definition and goals of cryptography
- Basic terminology and concepts
- Types of cryptographic systems
- Kerckhoffs's principle
- Threat models
- A simple example (Caesar cipher)

```{admonition} Next Steps
:class: tip
In the next chapter, we'll explore the mathematical foundations necessary for understanding modern cryptography, including modular arithmetic, number theory, and group theory.
```

## Exercises

```{exercise}
:label: caesar-exercise
Decrypt the following message that was encrypted using a Caesar cipher with shift 5:
MJQQT BTWQI
```

```{exercise}
:label: kerckhoffs-exercise
Explain why Kerckhoffs's principle is important for modern cryptographic systems. Give an example of a situation where violating this principle could be problematic.
```

```{exercise}
:label: symmetric-vs-asymmetric
Compare symmetric and asymmetric cryptography. In what scenarios would you use each type?
```

## Further Reading

- {cite}`stinson2018cryptography` - Comprehensive textbook on cryptography
- {cite}`katz2020introduction` - Modern approach with formal definitions
- {cite}`schneier2015applied` - Practical cryptographic implementations
