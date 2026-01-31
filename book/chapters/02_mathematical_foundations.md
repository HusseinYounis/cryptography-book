# Chapter 2: Mathematical Foundations

## Introduction

Modern cryptography relies heavily on mathematical concepts. This chapter covers the essential mathematical tools you'll need to understand cryptographic algorithms.

```{admonition} Prerequisites
:class: note
This chapter assumes familiarity with basic algebra. We'll build up from there to more advanced concepts.
```

## Modular Arithmetic

Modular arithmetic is fundamental to cryptography. It's sometimes called "clock arithmetic."

### Definition

```{admonition} Definition: Modulus Operation
:class: tip
For integers $a$, $b$, and $n$ (where $n > 0$), we say:

$$a \equiv b \pmod{n}$$

if $n$ divides $(a - b)$. We read this as "$a$ is congruent to $b$ modulo $n$."
```

### Properties of Modular Arithmetic

For any integers $a$, $b$, $c$, and modulus $n$:

1. **Addition**: $(a + b) \mod n = ((a \mod n) + (b \mod n)) \mod n$
2. **Subtraction**: $(a - b) \mod n = ((a \mod n) - (b \mod n)) \mod n$
3. **Multiplication**: $(a \times b) \mod n = ((a \mod n) \times (b \mod n)) \mod n$

```{warning}
Division in modular arithmetic is more complex and requires the concept of **modular multiplicative inverse**, which we'll cover later.
```

### Example: Modular Arithmetic

Let's compute some values:

- $17 \mod 5 = 2$ (since $17 = 3 \times 5 + 2$)
- $(23 + 15) \mod 7 = 38 \mod 7 = 3$
- $(4 \times 9) \mod 11 = 36 \mod 11 = 3$

## Greatest Common Divisor (GCD)

The greatest common divisor of two integers is the largest positive integer that divides both numbers.

```{admonition} Definition: GCD
:class: tip
$\gcd(a, b)$ is the largest integer $d$ such that $d|a$ and $d|b$.
```

### Euclidean Algorithm

The Euclidean algorithm efficiently computes the GCD:

```{prf:algorithm} Euclidean Algorithm
:label: euclidean-algorithm

**Input:** Two positive integers $a$ and $b$ with $a \geq b$

**Output:** $\gcd(a, b)$

1. If $b = 0$, return $a$
2. Otherwise, return $\gcd(b, a \mod b)$
```

**Example:** Find $\gcd(48, 18)$

$$
\begin{align}
\gcd(48, 18) &= \gcd(18, 48 \mod 18) = \gcd(18, 12)\\
&= \gcd(12, 18 \mod 12) = \gcd(12, 6)\\
&= \gcd(6, 12 \mod 6) = \gcd(6, 0)\\
&= 6
\end{align}
$$

## Extended Euclidean Algorithm

The extended Euclidean algorithm finds integers $x$ and $y$ such that:

$$ax + by = \gcd(a, b)$$

This is crucial for finding **modular multiplicative inverses**.

```{admonition} Bézout's Identity
:class: note
For any integers $a$ and $b$, there exist integers $x$ and $y$ such that:
$$ax + by = \gcd(a, b)$$
```

## Modular Multiplicative Inverse

The modular multiplicative inverse is essential for decryption in many cryptographic systems.

```{admonition} Definition: Modular Inverse
:class: tip
The modular multiplicative inverse of $a$ modulo $n$ is an integer $x$ such that:

$$ax \equiv 1 \pmod{n}$$

We denote this as $a^{-1} \mod n$ or $x = a^{-1}$.
```

**Existence:** The inverse $a^{-1} \mod n$ exists if and only if $\gcd(a, n) = 1$ (i.e., $a$ and $n$ are **coprime** or **relatively prime**).

### Example: Finding Modular Inverse

Find $7^{-1} \mod 26$:

We need to find $x$ such that $7x \equiv 1 \pmod{26}$.

Using the extended Euclidean algorithm:
- $\gcd(7, 26) = 1$
- $7 \times 15 - 26 \times 4 = 105 - 104 = 1$
- Therefore: $7 \times 15 \equiv 1 \pmod{26}$
- So $7^{-1} \equiv 15 \pmod{26}$

## Prime Numbers

Prime numbers are the building blocks of number theory and cryptography.

```{admonition} Definition: Prime Number
:class: tip
A prime number is a natural number greater than 1 that has no positive divisors other than 1 and itself.
```

**Examples:** 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, ...

### Fundamental Theorem of Arithmetic

```{prf:theorem} Fundamental Theorem of Arithmetic
:label: fundamental-theorem

Every integer greater than 1 can be uniquely represented as a product of prime numbers (up to the order of factors).

$$n = p_1^{e_1} \times p_2^{e_2} \times \cdots \times p_k^{e_k}$$

where $p_1, p_2, \ldots, p_k$ are distinct primes and $e_1, e_2, \ldots, e_k$ are positive integers.
```

**Example:** $360 = 2^3 \times 3^2 \times 5^1$

## Euler's Totient Function

Euler's totient function is crucial for RSA cryptography.

```{admonition} Definition: Euler's Totient Function
:class: tip
$\phi(n)$ is the number of positive integers less than or equal to $n$ that are relatively prime to $n$.
```

### Properties

1. If $p$ is prime: $\phi(p) = p - 1$
2. If $n = p \times q$ where $p$ and $q$ are distinct primes: $\phi(n) = (p-1)(q-1)$
3. For $n = p^k$: $\phi(p^k) = p^k - p^{k-1} = p^{k-1}(p-1)$

**Examples:**
- $\phi(7) = 6$ (since 7 is prime)
- $\phi(15) = \phi(3 \times 5) = (3-1)(5-1) = 2 \times 4 = 8$

## Fermat's Little Theorem

```{prf:theorem} Fermat's Little Theorem
:label: fermats-little-theorem

If $p$ is prime and $a$ is not divisible by $p$, then:

$$a^{p-1} \equiv 1 \pmod{p}$$

Equivalently: $a^p \equiv a \pmod{p}$ for all integers $a$.
```

This theorem is the basis for many cryptographic algorithms and primality tests.

**Example:** Let $a = 2$, $p = 7$:
$$2^{7-1} = 2^6 = 64 = 9 \times 7 + 1 \equiv 1 \pmod{7}$$

## Euler's Theorem

Euler's theorem generalizes Fermat's Little Theorem:

```{prf:theorem} Euler's Theorem
:label: eulers-theorem

If $\gcd(a, n) = 1$, then:

$$a^{\phi(n)} \equiv 1 \pmod{n}$$
```

This theorem is fundamental to RSA encryption.

## Modular Exponentiation

Computing $a^b \mod n$ efficiently is crucial for cryptographic operations.

### Square-and-Multiply Algorithm

For large exponents, we use the **square-and-multiply algorithm** (also called binary exponentiation):

```{prf:algorithm} Square-and-Multiply
:label: square-multiply

**Input:** Base $a$, exponent $b$, modulus $n$

**Output:** $a^b \mod n$

1. Convert $b$ to binary: $b = (b_k b_{k-1} \cdots b_1 b_0)_2$
2. Set result $r = 1$
3. For $i$ from $k$ down to $0$:
   - $r = r^2 \mod n$
   - If $b_i = 1$: $r = r \times a \mod n$
4. Return $r$
```

**Example:** Compute $5^{13} \mod 7$

- $13 = (1101)_2$
- Following the algorithm: $5^{13} \equiv 6 \pmod{7}$

## Chinese Remainder Theorem

The Chinese Remainder Theorem (CRT) is used to speed up modular operations.

```{prf:theorem} Chinese Remainder Theorem
:label: crt

Let $n_1, n_2, \ldots, n_k$ be pairwise coprime positive integers. Then for any integers $a_1, a_2, \ldots, a_k$, the system of congruences:

$$
\begin{align}
x &\equiv a_1 \pmod{n_1}\\
x &\equiv a_2 \pmod{n_2}\\
&\vdots\\
x &\equiv a_k \pmod{n_k}
\end{align}
$$

has a unique solution modulo $N = n_1 \times n_2 \times \cdots \times n_k$.
```

## Computational Complexity

Understanding algorithm efficiency is important for cryptography:

- **Polynomial Time**: $O(n^k)$ - Considered efficient
- **Exponential Time**: $O(2^n)$ - Generally infeasible for large $n$

**Important Facts:**
- GCD computation: $O(\log n)$
- Modular exponentiation: $O(\log n)$ multiplications
- Primality testing: Polynomial time (AKS algorithm)
- Integer factorization: No known polynomial-time algorithm (basis for RSA security)

## Summary

In this chapter, we covered:

- ✅ Modular arithmetic and its properties
- ✅ GCD and Extended Euclidean Algorithm
- ✅ Modular multiplicative inverse
- ✅ Prime numbers and the Fundamental Theorem of Arithmetic
- ✅ Euler's totient function
- ✅ Fermat's Little Theorem and Euler's Theorem
- ✅ Efficient modular exponentiation
- ✅ Chinese Remainder Theorem
- ✅ Computational complexity basics

```{admonition} Next Steps
:class: tip
Now that we have the mathematical foundation, we'll explore classical ciphers in the next chapter.
```

## Exercises

```{exercise}
:label: modular-arithmetic-ex
Compute the following:
1. $47 \mod 12$
2. $(123 + 456) \mod 100$
3. $(7 \times 13) \mod 15$
```

```{exercise}
:label: gcd-ex
Use the Euclidean algorithm to find $\gcd(252, 105)$.
```

```{exercise}
:label: modular-inverse-ex
Find the modular multiplicative inverse of $17 \mod 26$, if it exists.
```

```{exercise}
:label: totient-ex
Calculate $\phi(100)$ and $\phi(91)$.
```

```{exercise}
:label: fermats-ex
Verify Fermat's Little Theorem for $a = 3$ and $p = 11$.
```

## Further Reading

- {cite}`katz2020introduction` - Chapter on mathematical background
- {cite}`stinson2018cryptography` - Number theory for cryptography
