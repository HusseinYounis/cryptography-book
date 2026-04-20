# Chapter 1: Introduction to Cryptography

```{figure} ../figures/ch01/intro_banner.jpg
:align: center
:width: 60%
```

---

::::{grid} 1 2 2 3
:gutter: 3

:::{grid-item-card} 🔒 What Is Cryptography?
Definitions, goals, and the five primary functions of cryptographic systems.
:::

:::{grid-item-card} 🛡️ CIA Triad
The three pillars of information security and how cryptography addresses each one.
:::

:::{grid-item-card} 🔑 Types of Cryptography
Symmetric, asymmetric, and hybrid encryption — when and why each is used.
:::

:::{grid-item-card} 📐 Kerckhoffs's Principle
Why security must depend only on the key, never on algorithm secrecy.
:::

::::

```{admonition} Learning Objectives
:class: tip
By the end of this chapter you will be able to:
- Define cryptography and distinguish it from cryptanalysis and cryptology
- List the five primary functions of cryptography (Confidentiality, Authentication, Integrity, Non-repudiation, Key Exchange)
- Explain the CIA Triad and map cryptographic tools to each pillar
- Describe the three types of cryptography (symmetric, asymmetric, hybrid) and when to use each
- State Kerckhoffs's Principle and explain why it is the foundation of modern cipher design
- Understand the basic cryptographic process: $C = E_K(P)$ and $P = D_K(C)$
```

---

## Warm-Up: The Hidden Message

A friend wrote down:

$$8 - 5 - 12 - 12 - 15$$

Each number corresponds to its position in the English alphabet ($A=1, B=2, \ldots, Z=26$). What does it say?

```{admonition} Solution
:class: dropdown
$8=H,\ 5=E,\ 12=L,\ 12=L,\ 15=O$ → **HELLO**

This is the simplest possible cipher — a positional substitution table. We will study far more sophisticated systems throughout this course.
```

---

## 1. What Is This Course About?

This course covers **Applied Cryptography** from fundamentals to modern practice:

- **Classical Cryptography** — historical ciphers and their cryptanalysis
- **Mathematical Foundations** — number theory, modular arithmetic, and algebraic structures
- **Modern Symmetric Cryptography** — block ciphers, stream ciphers, and modes of operation
- **Public Key Cryptography** — RSA, Diffie-Hellman, and elliptic curve cryptography
- **Cryptographic Applications** — hash functions, digital signatures, and key exchange
- **Practical Implementation** — hands-on interactive code demonstrations

---

## 2. What Is Cryptography?

Cryptography is the **science and art of securing communication and information** through the use of codes and ciphers. The word comes from the Greek words *kryptos* (hidden) and *graphein* (writing).

```{prf:definition} Cryptography
:label: def-cryptography

Cryptography is the practice and study of techniques for **secure communication in the presence of adversarial behavior**, encompassing the design and analysis of protocols that prevent third parties from reading private messages.
```

---

## 3. Primary Functions of Cryptography

There are **five primary functions** of cryptography:

| # | Function | Description |
|---|----------|-------------|
| 1 | **Confidentiality** | No one can read the message except the intended receiver |
| 2 | **Authentication** | Proving one's identity |
| 3 | **Integrity** | The received message has not been altered from the original |
| 4 | **Non-repudiation** | Proof that the sender really sent this message |
| 5 | **Key Exchange** | The method by which crypto keys are shared |

---

## 4. Related Terms

```{prf:definition} Cryptanalysis
:label: def-cryptanalysis

The study of analyzing and breaking cryptographic systems. It involves finding weaknesses in algorithms and protocols to recover plaintext from ciphertext without the key.
```

```{prf:definition} Cryptology
:label: def-cryptology

The comprehensive scientific discipline encompassing both cryptography (creating secure systems) and cryptanalysis (breaking them).
```

```{prf:definition} Cipher
:label: def-cipher

An algorithm or mathematical function used for encryption and decryption. Works at the character or bit level.
```

```{prf:definition} Code
:label: def-code

A method of transforming information by replacing words or phrases with predetermined equivalents. Works at the semantic level.
```

$$\text{Cryptology} = \text{Cryptography} + \text{Cryptanalysis}$$

**Cipher vs Code:**
- *Cipher*: each letter shifted by 3 positions (Caesar cipher)
- *Code*: "ATTACK AT DAWN" → "ALPHA BRAVO CHARLIE"

---

## 5. The CIA Triad: Foundation of Information Security

```{figure} ../figures/ch01/cia_triad_triangle.jpg
:align: center
:width: 65%
:alt: CIA Triad — Confidentiality, Integrity, Availability
```

*The CIA Triad: Three Pillars of Information Security*

Information Security programs are built around three objectives — **CIA**:

- **C — Confidentiality**: Protecting information from unauthorized access
- **I — Integrity**: Ensuring information accuracy and preventing unauthorized modification
- **A — Availability**: Ensuring authorized users have reliable access to information when needed

```{figure} ../figures/ch01/cia_triad_tree.png
:align: center
:width: 80%
:alt: CIA Triad tree showing cryptographic tools for each pillar
```

*Cryptographic tools map to each CIA pillar*

### Pillar 1 — Confidentiality

Ensures data is not disclosed to unauthorized individuals, entities, or processes.

**Analogy:** A sealed envelope delivered to your mailbox — only you should open it.

**Real-World Examples:**
- Your medical records are only accessible to you and your doctor
- Your bank balance is not visible to other customers
- Classified documents are only accessible to personnel with the correct clearance

### Pillar 2 — Integrity

Maintains consistency, accuracy, and trustworthiness of data over its entire lifecycle.

**Analogy:** A signed check — the amount cannot be changed without the signature becoming invalid.

**Real-World Examples:**
- Ensuring a bank transfer amount hasn't been altered in transit
- A Wikipedia edit log allows you to see the original unaltered version
- Sensor readings in a nuclear plant must be accurate; a false reading could be catastrophic

### Pillar 3 — Availability

Ensures information and systems are accessible and usable upon demand by authorized entities.

**Analogy:** A 24/7 ATM machine that always has cash and power.

**Real-World Examples:**
- Being able to log into your email account whenever you want
- An e-commerce website staying online during a massive sale
- Emergency services (911) must be operational 100% of the time

---

## 6. How Cryptography Serves the CIA Triad

| CIA Pillar | Cryptographic Tool | How It Helps |
|------------|-------------------|--------------|
| **Confidentiality** | Encryption | Transforms plaintext → ciphertext; attacker sees only scrambled data |
| **Integrity** | Hashing, Digital Signatures | Any change to data is detected via its fingerprint |
| **Availability** | Authentication protocols | Ensures only authorized users access systems |

```{warning}
**The Ransomware Paradox:** Attackers exploit encryption *against* availability — they encrypt your data and hold it hostage. This is why key management and backups are critical.
```

**Balancing the Triad:**
- High Confidentiality may reduce Availability (more restrictions = harder access)
- Strong Integrity checks may impact performance
- Maximum Availability might compromise Confidentiality (more access points = more vulnerabilities)

---

## 7. Basic Concepts of Cryptography

### The Cryptographic Process

```{figure} ../figures/ch01/crypto_process_simple.png
:align: center
:width: 75%
:alt: Encryption and Decryption process diagram
```

```{figure} ../figures/ch01/crypto_process_diagram.png
:align: center
:width: 90%
:alt: Detailed cryptographic process with Key
```

*The Cryptographic Process: Plaintext + Key → Ciphertext → Plaintext*

More formally:

$$\text{Encryption: } C = E_K(P)$$

$$\text{Decryption: } P = D_K(C)$$

Where:
- $P$ = Plaintext
- $C$ = Ciphertext
- $K$ = Key
- $E_K$ = Encryption function with key $K$
- $D_K$ = Decryption function with key $K$

---

## 8. Types of Cryptography

### 1. Symmetric Cryptography

Uses the **same key** for both encryption and decryption.

```{figure} ../figures/ch01/symmetric_encryption.png
:align: center
:width: 55%
:alt: Symmetric encryption — Alice and Bob share secret key K
```

*Symmetric Encryption: Shared Secret Key*

Symmetric ciphers are **fast and efficient**, making them ideal for encrypting large amounts of data. The main challenge is the **key distribution problem**: both parties must share the same secret key before they can communicate securely.

**Examples:** AES, DES, ChaCha20

### 2. Asymmetric Cryptography

Uses a **key pair**: a public key for encryption and a private key for decryption.

```{figure} ../figures/ch01/asymmetric_encryption.png
:align: center
:width: 55%
:alt: Asymmetric encryption — Alice encrypts with Bob's public key, Bob decrypts with his private key
```

*Asymmetric Encryption: Public/Private Key Pair*

Asymmetric ciphers use a **key pair** (public key for encryption, private key for decryption), solving the key distribution problem. They are significantly slower than symmetric ciphers and are primarily used for key exchange and digital signatures.

**Examples:** RSA, Diffie-Hellman, Elliptic Curve Cryptography

### 3. Hybrid Cryptography

Combines **both** symmetric and asymmetric to get the best of both worlds.

```{prf:algorithm} Hybrid Cryptography Protocol
:label: algo-hybrid

1. Generate a random symmetric key (session key)
2. Encrypt data with fast symmetric encryption
3. Encrypt the session key with asymmetric encryption
4. Send both the encrypted data and the encrypted session key
```

**Used in:** HTTPS, TLS/SSL, PGP, S/MIME — this is how your browser securely communicates with websites.

---

## 9. Kerckhoffs's Principle

```{prf:criterion} Kerckhoffs's Principle (1883)
:label: crit-kerckhoffs

*"The system must not require secrecy, and must be able to fall into the enemy's hands without inconvenience."*

A cryptographic system should be secure even if **everything about the system, except the key, is public knowledge**.
```

**Core Idea:** Security must depend **only on the key**, not on the secrecy of the algorithm.

| Benefit | Why It Matters |
|---------|---------------|
| Security through transparency | Public algorithms are scrutinized by experts → stronger designs |
| Independence from obscurity | Security relies on keys, not algorithm secrecy |
| Interoperability | Open algorithms enable secure communication between different systems |
| Algorithm Agility | Easy to replace a compromised algorithm |

**Kerckhoffs's Insight — Assume the Enemy Knows Everything:**
- The attacker knows the encryption algorithm
- The attacker has access to the source code
- The attacker may have sample plaintext-ciphertext pairs

Security must depend **ONLY** on the key. This was revolutionary in 1883 and remains the foundation of modern cryptography.

---

## 10. Why Modern Cryptography Works

$$\text{Open Algorithms} + \text{Secret Keys} + \text{Hard Math} + \text{True Randomness} = \text{Trust}$$

| Pillar | Description |
|--------|-------------|
| **Open Algorithms** | Publicly scrutinized and tested |
| **Secret Keys** | The only thing that must remain private |
| **Hard Math** | Based on computationally infeasible problems |
| **True Randomness** | Unpredictable key generation |

### Classical vs Modern Encryption

| Classical Encryption | Modern Encryption |
|---------------------|------------------|
| No provable security | Security formally proven |
| Used because people believed they worked | Based on well-defined computational assumptions |
| Broken through clever analysis | Mathematical hardness (factoring, discrete log) |
| *"Unbreakable" ciphers eventually broken (Enigma, Vigenère)* | *"Breaking this requires $2^{128}$ operations"* |

---

## 11. Threat Models

Understanding potential attackers is crucial for evaluating any cryptosystem. Attackers are classified by what they can observe or control — ranging from a **ciphertext-only** eavesdropper (sees only the encrypted message) to a **chosen-ciphertext** adversary (can submit ciphertexts for decryption).

The four standard attack models — **COA**, **KPA**, **CPA**, and **CCA** — form a strict hierarchy of adversarial power. They are formally defined with examples and interactive exercises in **Chapter 4**.

---

## 12. Perfect Secrecy — A Preview

In 1949, Claude Shannon proved that a cipher can achieve **perfect secrecy** — meaning that observing the ciphertext provides an attacker with *zero* additional information about the plaintext, regardless of computational power. This theoretical ideal requires the key to be at least as long as the message and used only once (the One-Time Pad). The formal definition, proof, and practical implications are fully covered in **Chapter 4**.

---

## Summary

```{admonition} Key Takeaways
:class: tip
- **Cryptography** = science of secure communication using codes and ciphers
- **Five functions**: Confidentiality, Authentication, Integrity, Non-repudiation, Key Exchange
- **CIA Triad**: the three pillars of information security; cryptography is the primary tool to achieve all three
- **Cryptographic process**: $C = E_K(P)$ and $P = D_K(C)$
- **Three types**: Symmetric (fast, shared key), Asymmetric (key pair, solves distribution), Hybrid (both combined)
- **Kerckhoffs's Principle**: security depends only on the key, never on the algorithm
- **Threat Models**: four attack scenarios (COA, KPA, CPA, CCA) — formally defined in Chapter 4
- **Perfect Secrecy**: Shannon's ideal cipher leaking zero information — fully treated in Chapter 4
```

---

## Exercises

::::{question} CIA Triad Quick Check
:type: multiple-choice
:variant: multiple-select
:showanswer:

Which of the following are the three pillars of the CIA Triad? (Select all that apply)
---
[x] Confidentiality
> Correct! Confidentiality protects data from unauthorized access.
[ ] Authentication
> Authentication is one of the five cryptographic functions, but not a CIA pillar.
[x] Integrity
> Correct! Integrity ensures data is not tampered with.
[x] Availability
> Correct! Availability ensures authorized users can access resources.
[ ] Non-repudiation
> Non-repudiation is one of the five cryptographic functions, but not a CIA pillar.
---
::::

::::{question} Kerckhoffs's Principle
:type: multiple-choice
:variant: single-select
:showanswer:

According to Kerckhoffs's Principle, the security of a cryptosystem should depend on:
---
[ ] The secrecy of the algorithm
> A system relying on algorithm secrecy is called "security through obscurity" and violates Kerckhoffs's Principle.
[ ] Both the key and the algorithm being secret
> Kerckhoffs's Principle requires that only the key need be secret, not the algorithm.
[x] Only the key, not the algorithm
> Correct! Kerckhoffs's Principle states the algorithm can be public; only the key must remain secret.
[ ] The complexity of the ciphertext
> Ciphertext complexity alone does not constitute security.
---
::::

```{exercise} Decode a Hidden Message
:label: ch01-hidden-message

Decode the following messages where each number equals its position in the alphabet:

1. $3 - 18 - 25 - 16 - 20 - 15$
2. $19 - 5 - 3 - 18 - 5 - 20$
```

```{solution} ch01-hidden-message
:label: sol-ch01-hidden-message
:class: dropdown

1. $3=C,\ 18=R,\ 25=Y,\ 16=P,\ 20=T,\ 15=O$ → **CRYPTO**
2. $19=S,\ 5=E,\ 3=C,\ 18=R,\ 5=E,\ 20=T$ → **SECRET**
```

```{exercise} CIA Triad Violations
:label: ch01-cia-triad

For each scenario below, identify which CIA pillar(s) are violated and explain why:

1. A hospital database is offline for 3 hours due to a DDoS attack.
2. An attacker intercepts and reads your private emails without modifying them.
3. An attacker modifies a bank transfer amount from \$100 to \$10,000 during transmission.
```

```{solution} ch01-cia-triad
:label: sol-ch01-cia-triad
:class: dropdown

1. **Availability** is violated — authorized users (medical staff) cannot access critical data during the outage.
2. **Confidentiality** is violated — the attacker reads private data, even though it remains unmodified.
3. **Integrity** is violated — the data was altered in transit without detection.
```

```{exercise} Kerckhoffs's Principle in Practice
:label: ch01-kerckhoffs

A company uses a proprietary (secret) encryption algorithm and argues "our algorithm is so secret, no attacker can know it." Explain why this violates Kerckhoffs's Principle and why it is dangerous in practice.
```

```{solution} ch01-kerckhoffs
:label: sol-ch01-kerckhoffs
:class: dropdown

This violates Kerckhoffs's Principle because security relies on the algorithm remaining secret rather than only on the key. This is dangerous for several reasons:

- **No public scrutiny**: Proprietary algorithms have not been vetted by the cryptographic community, meaning they may contain hidden flaws.
- **Eventual exposure**: Algorithms can be reverse-engineered. Once discovered, if all security depends on algorithm secrecy, the entire system is broken.
- **No key rotation benefit**: Even if keys are changed, the underlying broken algorithm remains broken.
- **Historical precedent**: Many "secret" algorithms (e.g., RC4 internal state, Skipjack) were eventually revealed and found to be weak.

Kerckhoffs's Principle demands that security depend *only* on the key.
```

```{exercise} HTTPS Hybrid Cryptography
:label: ch01-hybrid

HTTPS uses hybrid cryptography. Describe step-by-step how a browser and a web server establish a secure connection, identifying where symmetric and asymmetric cryptography are each used.
```

```{solution} ch01-hybrid
:label: sol-ch01-hybrid
:class: dropdown

1. **TLS Handshake — Asymmetric phase:**
   - Browser requests the server's certificate (which contains the server's **public key**).
   - Browser verifies the certificate against a trusted Certificate Authority (CA).
   - Browser generates a random **pre-master secret** and encrypts it with the server's **public key** (asymmetric encryption).
   - Server decrypts it with its **private key**.

2. **Session Key Derivation:**
   - Both sides derive the same **symmetric session key** from the pre-master secret.

3. **Data Transfer — Symmetric phase:**
   - All subsequent HTTP data is encrypted and decrypted with the **symmetric session key** (e.g., AES-256).

Asymmetric cryptography solves the key distribution problem; symmetric cryptography provides the speed needed for bulk data transfer.
```
