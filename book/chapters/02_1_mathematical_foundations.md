# Chapter 2.1: Mathematical Foundations

```{figure} ../figures/ch02_1/math_banner.jpg
:align: center
:width: 60%
```

---

## Warm-Up: The Clock Puzzle

It is currently **11 o'clock**. What time will it be **15 hours** from now?

```{admonition} Solution
:class: dropdown
$11 + 15 = 26$.  But clocks only go to 12, so we compute $26 \mod 12 = 2$.

The answer is **2 o'clock**.

This is modular arithmetic — the arithmetic used in almost every cryptographic algorithm!
```

---

## 1. Modular Arithmetic

Modular arithmetic is fundamental to cryptography. It is sometimes called **"clock arithmetic."**

```{prf:definition} Modulus Operation
:label: def-modulus

For integers $a$, $b$, and $n$ (where $n > 0$), we say:

$$a \equiv b \pmod{n} \iff n \mid (a - b)$$

If $n$ divides $(a - b)$, we read this as **"$a$ is congruent to $b$ modulo $n$."**
```

### 1.1 How to Compute $a \bmod n$

Find the **smallest non-negative** integer $m$ such that $(a - m)$ is a multiple of $n$.

```{prf:example} Compute $14 \bmod 3$
:label: ex-mod14

- We need the smallest $m \geq 0$ such that $14 - m$ is divisible by 3.
- Try $m = 2$: $14 - 2 = 12 = 4 \times 3$ ✓
- Therefore $14 \bmod 3 = \mathbf{2}$
```

### 1.2 Important Cases

| Expression | Result | Note |
|:---:|:---:|:---:|
| $23 \bmod 6$ | **5** | $a > b$ |
| $2 \bmod 2$ | **0** | $a = b$ |
| $4 \bmod 5$ | **4** | $a < b$ |
| $0 \bmod 2$ | **0** | zero dividend |
| $1 \bmod 0$ | **Math error** | $b = 0$ is undefined |
| $12 \bmod 6$ | **0** | exact divisibility |

### 1.3 Cyclic Pattern

Computing $\text{num} \bmod 5$ for every integer from 0 to 9 reveals the cyclic nature of modular arithmetic:

| $n$ | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| $n \bmod 5$ | 0 | 1 | 2 | 3 | 4 | **0** | **1** | **2** | **3** | **4** |

The output **cycles back** to 0 at every multiple of 5. This cycling property is exploited in cryptographic key generation and stream ciphers.

### 1.4 Properties

| Operation | Rule |
|:---|:---|
| **Addition** | $(a + b) \bmod n = \bigl[(a \bmod n) + (b \bmod n)\bigr] \bmod n$ |
| **Subtraction** | $(a - b) \bmod n = \bigl[(a \bmod n) - (b \bmod n)\bigr] \bmod n$ |
| **Multiplication** | $(a \times b) \bmod n = \bigl[(a \bmod n) \times (b \bmod n)\bigr] \bmod n$ |

```{note}
Division in modular arithmetic requires the concept of the **modular multiplicative inverse** and is more complex than the operations above.
```

::::{question} Check Your Understanding: Modular Arithmetic
:type: multiple-choice
:variant: single-select
:showanswer:

What is $17 \bmod 5$?
---
[ ] 1
> $17 = 3 \times 5 + 2$, so the remainder is 2, not 1.
[x] 2
> Correct! $17 = 3 \times 5 + 2$, so $17 \bmod 5 = 2$.
[ ] 3
> $17 = 3 \times 5 + 2$, so the remainder is 2, not 3.
[ ] 4
> $17 = 3 \times 5 + 2$, so the remainder is 2, not 4.
---
::::

---

## 2. Greatest Common Divisor (GCD)

```{prf:definition} Greatest Common Divisor (GCD)
:label: def-gcd

The **greatest common divisor** of two integers is the largest positive integer that divides both numbers.

$\gcd(a, b)$ is the largest integer $d$ such that $d \mid a$ **and** $d \mid b$.
```

### 2.1 Step-by-Step Method

1. List all divisors of $a$.
2. List all divisors of $b$.
3. Identify the **common** divisors.
4. Select the **largest** common divisor.

```{prf:example} Find $\gcd(13, 48)$
:label: ex-gcd1348

| Number | Divisors |
|:---:|:---|
| 13 | 1, 13 |
| 48 | 1, 2, 3, 4, 6, 8, 12, 16, 24, 48 |

Common divisors: **{1}**. Therefore, $\gcd(13, 48) = \mathbf{1}$.
```

```{prf:example} Find $\gcd(12, 33)$
:label: ex-gcd1233

| | 12 | 33 |
|:---:|:---|:---|
| Divisors | 1, 2, 3, 4, 6, 12 | 1, 3, 11, 33 |
| Common | \{1, 3\} | |
| **GCD** | **3** | |
```

### 2.2 Prime Factorization Method

```{prf:definition} Prime Factorization Method for GCD
:label: def-prime-factor-gcd

Break each number into its prime factors. The GCD equals the product of the **lowest powers** of all **common** prime factors.
```

```{note}
This method works only for positive natural numbers.
```

:::::{prf:example} Compute $\gcd(36, 60)$ using Prime Factorization
:label: ex-gcd3660

::::{grid} 1 2 2 2
:gutter: 3

:::{grid-item}
```{figure} ../figures/ch02_1/prime_tree_36.png
:align: center
:width: 70%

Prime factorization tree of 36
```
:::

:::{grid-item}
```{figure} ../figures/ch02_1/prime_tree_60.png
:align: center
:width: 70%

Prime factorization tree of 60
```
:::
::::

**Solution:**

- $36 = 2 \times 2 \times 3 \times 3$
- $60 = 2 \times 2 \times 3 \times 5$
- Common prime factors: **2, 2, 3**
- Therefore: $\gcd(36, 60) = 2 \times 2 \times 3 = \mathbf{12}$
:::::

### 2.3 Euclidean Algorithm

The Euclidean algorithm computes the GCD **efficiently** without listing all divisors.

```{prf:algorithm} Euclidean GCD
:label: algo-euclidean

**Input:** Two positive integers $a$ and $b$ with $a \geq b$.

**Output:** $\gcd(a, b)$

1. If $b = 0$, return $a$.
2. Otherwise, return $\gcd(b,\ a \bmod b)$.
```

```{prf:example} Find $\gcd(50, 12)$ using the Euclidean Algorithm
:label: ex-gcd5012

$$\gcd(50, 12) = \gcd(12, 50 \bmod 12) = \gcd(12, 2)$$
$$\gcd(12, 2) = \gcd(2, 12 \bmod 2) = \gcd(2, 0) = \mathbf{2}$$
```

::::{question} Check Your Understanding: Euclidean Algorithm
:type: multiple-choice
:variant: single-select
:showanswer:

Using the Euclidean Algorithm, what is $\gcd(30, 18)$?
---
[ ] 3
> $\gcd(30,18)=\gcd(18,12)=\gcd(12,6)=\gcd(6,0)=6$, not 3.
[ ] 9
> $\gcd(30,18)=\gcd(18,12)=\gcd(12,6)=\gcd(6,0)=6$, not 9.
[x] 6
> Correct! $\gcd(30,18)=\gcd(18,12)=\gcd(12,6)=\gcd(6,0)=6$.
[ ] 18
> 18 would only be the GCD if 18 divides 30, which it does not.
---
::::

---

## 3. Relatively Prime (Co-Prime) Numbers

```{prf:definition} Relatively Prime (Co-Prime)
:label: def-coprime

Two numbers are **relatively prime** (or **co-prime**) if their only common factor is 1, i.e., $\gcd(a, b) = 1$.
```

```{prf:example} Are 4 and 13 relatively prime?
:label: ex-coprime413

| | 4 | 13 |
|:---:|:---|:---|
| Divisors | 1, 2, 4 | 1, 13 |
| Common | \{1\} | |
| GCD | 1 | |

**Yes** — since $\gcd(4, 13) = 1$, they are relatively prime.
```

```{admonition} Why This Matters in Cryptography
:class: important
Co-primality is a fundamental requirement in many cryptographic constructions. In RSA, the public exponent $e$ must be co-prime to $\phi(n)$. In modular inverses, $a^{-1} \bmod n$ exists **only when** $\gcd(a, n) = 1$.
```

---

## 4. Euler's Totient Function $\phi(n)$

```{prf:definition} Euler's Totient Function
:label: def-totient

$\phi(n)$ (read "phi of $n$") is the **count of positive integers less than $n$ that are relatively prime to $n$**.
```

```{prf:example} Compute $\phi(5)$
:label: ex-phi5

Integers less than 5: 1, 2, 3, 4.

| Pair | $\gcd$ | Relatively prime? |
|:---:|:---:|:---:|
| $\gcd(1, 5)$ | 1 | ✓ Yes |
| $\gcd(2, 5)$ | 1 | ✓ Yes |
| $\gcd(3, 5)$ | 1 | ✓ Yes |
| $\gcd(4, 5)$ | 1 | ✓ Yes |

$$\therefore \phi(5) = \mathbf{4}$$
```

```{note}
For any **prime** number $p$: $\phi(p) = p - 1$, because every integer from 1 to $p-1$ is co-prime with a prime.
```

::::{question} Quick Check: Euler's Totient
:type: short-answer
:variant: blocks
:showanswer:

Compute $\phi(7)$ (enter a whole number):
---
M[6] $\phi(7) =$
= Correct! Since 7 is prime, $\phi(7) = 7 - 1 = 6$.
> Incorrect. Since 7 is prime, every integer from 1 to 6 is co-prime to 7. So $\phi(7) = 6$.
---
::::

---

## 5. Euler's Theorem

```{prf:theorem} Euler's Theorem
:label: thm-euler

For every pair of **relatively prime** positive integers $a$ and $n$ (i.e., $\gcd(a,n)=1$):

$$a^{\phi(n)} \equiv 1 \pmod{n}$$
```

```{prf:example} Verify Euler's Theorem for $a = 3$, $n = 10$
:label: ex-euler310

1. Check co-primality: $\gcd(3, 10) = 1$ ✓
2. Compute $\phi(10) = 4$
3. Verify:

$$3^{\phi(10)} = 3^4 = 81 \equiv 1 \pmod{10}$$

$$81 = 8 \times 10 + 1 \implies 81 \bmod 10 = 1 \checkmark$$

Euler's Theorem holds for $a = 3$, $n = 10$.
```

```{admonition} Why This Matters in Cryptography
:class: important
Euler's Theorem is the mathematical foundation of **RSA encryption**. The decryption step works because applying the exponent $\phi(n)$ cycles back to the original plaintext modulo $n$.
```

---

## Summary

| Concept | Definition | Cryptographic Use |
|:---|:---|:---|
| **Modular Arithmetic** | $a \bmod n$ gives the remainder | Core of all symmetric & asymmetric algorithms |
| **GCD** | Largest common divisor of two integers | Key generation; co-primality checks |
| **Euclidean Algorithm** | Efficient GCD computation | Computing modular inverses |
| **Relatively Prime** | $\gcd(a, b) = 1$ | Required for modular inverse and RSA |
| **$\phi(n)$** | Count of co-primes less than $n$ | RSA key generation: $\phi(n) = (p-1)(q-1)$ |
| **Euler's Theorem** | $a^{\phi(n)} \equiv 1 \pmod{n}$ | Basis of RSA decryption correctness |

---

## Exercises

```{exercise} Modular Arithmetic Computations
:label: ch02-ex-mod

Compute the following:
- $17 \bmod 5$
- $100 \bmod 7$
- $(23 + 15) \bmod 9$
- $(14 \times 3) \bmod 11$
```

```{solution} ch02-ex-mod
:label: sol-ch02-ex-mod
:class: dropdown

- $17 \bmod 5 = 2$ (since $17 = 3 \times 5 + 2$)
- $100 \bmod 7 = 2$ (since $100 = 14 \times 7 + 2$)
- $(23 + 15) \bmod 9 = 38 \bmod 9 = 2$ (since $38 = 4 \times 9 + 2$)
- $(14 \times 3) \bmod 11 = 42 \bmod 11 = 9$ (since $42 = 3 \times 11 + 9$)
```

```{exercise} Computing GCD — Three Methods
:label: ch02-ex-gcd

Find $\gcd(48, 36)$ using:
- (a) The listing method
- (b) Prime factorization
- (c) The Euclidean algorithm
```

```{solution} ch02-ex-gcd
:label: sol-ch02-ex-gcd
:class: dropdown

**(a)** Divisors of 48: 1,2,3,4,6,8,12,16,24,48. Divisors of 36: 1,2,3,4,6,9,12,18,36. Largest common: **12**.

**(b)** $48 = 2^4 \times 3$. $36 = 2^2 \times 3^2$. Common: $2^2 \times 3 = \mathbf{12}$.

**(c)** $\gcd(48,36) = \gcd(36,12) = \gcd(12,0) = \mathbf{12}$.
```

```{exercise} Identifying Co-Prime Pairs
:label: ch02-ex-coprime

Are the following pairs relatively prime? Justify your answer.
- (a) $\gcd(7, 15)$
- (b) $\gcd(6, 14)$
- (c) $\gcd(17, 300)$
```

```{solution} ch02-ex-coprime
:label: sol-ch02-ex-coprime
:class: dropdown

**(a)** $\gcd(7, 15) = 1$ → **relatively prime** (7 is prime; $7 \nmid 15$).

**(b)** $\gcd(6, 14) = 2$ → **not** relatively prime (both even).

**(c)** $\gcd(17, 300) = 1$ → **relatively prime** (17 is prime; $17 \nmid 300$).
```

```{exercise} Computing Euler's Totient Function
:label: ch02-ex-totient

Compute $\phi(n)$ for:
- (a) $n = 7$
- (b) $n = 12$
- (c) $n = 15$
```

```{solution} ch02-ex-totient
:label: sol-ch02-ex-totient
:class: dropdown

**(a)** 7 is prime $\Rightarrow \phi(7) = 6$.

**(b)** Integers $< 12$ co-prime to 12: 1, 5, 7, 11 $\Rightarrow \phi(12) = 4$.

**(c)** $15 = 3 \times 5 \Rightarrow \phi(15) = (3-1)(5-1) = 2 \times 4 = 8$.
```

```{exercise} Verifying Euler's Theorem
:label: ch02-ex-euler

Verify Euler's Theorem for $a = 2$, $n = 9$.
- (a) Confirm $\gcd(2, 9) = 1$.
- (b) Compute $\phi(9)$.
- (c) Verify $2^{\phi(9)} \equiv 1 \pmod{9}$.
```

```{solution} ch02-ex-euler
:label: sol-ch02-ex-euler
:class: dropdown

**(a)** $\gcd(2, 9) = 1$ ✓

**(b)** $9 = 3^2 \Rightarrow \phi(9) = 9 - 3 = 6$.

**(c)** $2^6 = 64 = 7 \times 9 + 1 \Rightarrow 64 \bmod 9 = 1$ ✓
```
