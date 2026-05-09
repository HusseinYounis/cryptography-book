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

# Chapter 3: Classical Ciphers

## Introduction

Classical ciphers are historical encryption methods that predate modern computers. While not secure by today's standards, they illustrate fundamental cryptographic concepts and provide insight into cryptanalysis techniques that remain relevant in modern cryptography.

::::{grid} 1 2 2 3
:gutter: 3

:::{grid-item-card} 🔤 Substitution
Learn Caesar, Affine, and General substitution ciphers — the building blocks of classical encryption.
:::

:::{grid-item-card} 📊 Frequency Analysis
Understand how statistical patterns in language break substitution ciphers.
:::

:::{grid-item-card} 🔑 Polyalphabetic
Master the Vigenère cipher and the Tabula Recta — thought unbreakable for centuries.
:::

:::{grid-item-card} 🔀 Transposition
See how rearranging characters, not replacing them, can also hide a message.
:::

:::{grid-item-card} ⚔️ Cryptanalysis
Learn systematic methods for breaking classical ciphers.
:::

::::

```{admonition} Why Study Old Ciphers?
:class: tip
Historical ciphers teach fundamental lessons:
- Security principles still relevant today
- Attack methodologies used in modern cryptography
- Mistakes to avoid in cipher design
- Foundation concepts for modern algorithms
```

```{admonition} Learning Objectives
:class: important
By the end of this chapter, you will be able to:
- Encrypt and decrypt messages using the Caesar and Affine ciphers
- Apply frequency analysis to break monoalphabetic substitution ciphers
- Describe the Vigenère cipher and its Tabula Recta construction
- Use the Kasiski test and Index of Coincidence to find a Vigenère key length
- Distinguish substitution from transposition ciphers and explain each cipher's weaknesses
```

---

## Warm-Up: Can You Break This?

A spy intercepted the following message:

$$\text{KHOOR ZRUOG}$$

Every letter has been shifted by the same fixed number of positions in the alphabet. What is the original message?

```{admonition} Solution
:class: dropdown
Shift each letter **back by 3** positions: K→H, H→E, O→L, O→L, R→O, Z→W, R→O, U→R, O→L, G→D.

The answer is **HELLO WORLD** — encrypted with the Caesar cipher, key $k = 3$.

This is the world's most famous cipher, and by the end of this chapter you will know exactly how to break it systematically.
```

---

## 1. Substitution Ciphers

Substitution ciphers replace each character in the plaintext with another character according to a fixed system. Despite their simplicity, they introduce fundamental concepts used in all modern encryption.

**Examples of substitution ciphers:**
- **Caesar Cipher**: Shift each letter by a fixed amount
- **Affine Cipher**: Uses modular arithmetic with two keys
- **General Substitution**: Any letter → any other letter

---

### 1.1 Caesar Cipher

```{admonition} Historical Background
:class: note
The Caesar cipher is one of the oldest known ciphers and holds a significant place in cryptographic history. It was used by **Julius Caesar** in the ancient Roman Republic more than **2,000 years ago** to encrypt military information passed around in the army, allowing secure communication of strategic orders and intelligence.

The Caesar cipher is a specific instance of substitution ciphers. Because of the cipher's historical origin, we assume the message consists of letters, although it can be extended to a larger message space.
```

```{prf:definition} Caesar Cipher
:label: def-caesar

Shifts each letter in the plaintext by a fixed number of positions in the alphabet.

**Encryption:** $C = (P + k) \bmod 26$

**Decryption:** $P = (C - k) \bmod 26$

where $k$ is the key (shift value) and the key space is $\{0, 1, 2, \ldots, 25\}$.
```

**Key examples:**

| Key | Effect |
|-----|--------|
| $k = 0$ | No shift — plaintext = ciphertext |
| $k = 1$ | Each letter shifts by 1 (A→B, B→C, …) |
| $k = 20$ | Each letter shifts by 20 positions |
| $k = 25$ | Each letter shifts by 25 (A→Z, B→A, …) |
| $k = 26$ | Same as $k = 0$ (wraps around) |

**Example with $k = 3$:**
~~~
Plaintext:  ATTACK AT DAWN
Ciphertext: DWWDFN DW GDZQ
~~~

#### Interactive Caesar Wheel

Use the slider or ◀ ▶ buttons to rotate the inner ring — the outer ring (blue) shows plaintext letters and the inner ring (red) shows what each letter encrypts to. Works without running any kernel.

```{raw} html
<div id="cw-widget" style="text-align:center;font-family:monospace;margin:1.5em 0;padding:1.2em;border:2px solid #c8d8e8;border-radius:10px;background:#f5f9ff;">
  <p style="margin:0 0 8px;font-weight:bold;font-size:1em;color:#2c3e50;">Interactive Caesar Cipher Wheel</p>
  <div style="margin-bottom:10px;">
    <button id="cw-dec" style="font-size:1.1em;padding:2px 10px;cursor:pointer;border-radius:4px;">&#9664;</button>
    &nbsp;
    <strong style="font-size:1em;">Shift key = <span id="cw-val" style="color:#1a7abf;font-size:1.3em;">3</span></strong>
    &nbsp;
    <button id="cw-inc" style="font-size:1.1em;padding:2px 10px;cursor:pointer;border-radius:4px;">&#9654;</button>
    <br>
    <input type="range" id="cw-range" min="0" max="25" value="3"
           style="width:280px;margin-top:8px;accent-color:#1a7abf;">
  </div>
  <svg id="cw-svg" width="340" height="340" viewBox="-170 -170 340 340"
       style="display:inline-block;max-width:100%;overflow:visible;"></svg>
  <div id="cw-tbl" style="margin-top:10px;overflow-x:auto;"></div>
  <div id="cw-eg" style="margin-top:8px;font-size:0.9em;padding:4px;"></div>
</div>
<script>
(function () {
  'use strict';
  var A = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', N = 26;
  var R1 = 130, R2 = 88, SAMPLE = 'ATTACK AT DAWN';
  var shift = 3;

  function ang(i) { return 2 * Math.PI * i / N - Math.PI / 2; }
  function px(r, i) { return r * Math.cos(ang(i)); }
  function py(r, i) { return r * Math.sin(ang(i)); }

  function mkSvg(tag, attr, txt) {
    var e = document.createElementNS('http://www.w3.org/2000/svg', tag);
    for (var k in attr) { e.setAttribute(k, attr[k]); }
    if (txt !== undefined) { e.textContent = txt; }
    return e;
  }

  function redrawSvg(k) {
    var svg = document.getElementById('cw-svg');
    while (svg.firstChild) { svg.removeChild(svg.firstChild); }

    var defs = mkSvg('defs', {});
    var mkr  = mkSvg('marker', { id: 'cwArr', markerWidth: 8, markerHeight: 6, refX: 8, refY: 3, orient: 'auto' });
    mkr.appendChild(mkSvg('polygon', { points: '0 0, 8 3, 0 6', fill: '#27ae60' }));
    defs.appendChild(mkr);
    svg.appendChild(defs);

    svg.appendChild(mkSvg('circle', { cx: 0, cy: 0, r: R1 + 18, fill: '#eaf2fb', stroke: '#4a90d9', 'stroke-width': 2 }));
    svg.appendChild(mkSvg('circle', { cx: 0, cy: 0, r: R2 + 18, fill: '#fef9f0', stroke: '#e07b39', 'stroke-width': 2 }));
    svg.appendChild(mkSvg('circle', { cx: 0, cy: 0, r: 26, fill: '#fff', stroke: '#bbb', 'stroke-width': 1 }));
    svg.appendChild(mkSvg('text', { x: 0, y: -8,  'text-anchor': 'middle', 'font-size': 8, fill: '#4a90d9' }, 'OUTER'));
    svg.appendChild(mkSvg('text', { x: 0, y:  2,  'text-anchor': 'middle', 'font-size': 7, fill: '#888' },   'plain'));
    svg.appendChild(mkSvg('text', { x: 0, y: 12,  'text-anchor': 'middle', 'font-size': 8, fill: '#c0392b' }, 'INNER'));
    svg.appendChild(mkSvg('text', { x: 0, y: 22,  'text-anchor': 'middle', 'font-size': 7, fill: '#888' },   'cipher'));

    svg.appendChild(mkSvg('line', {
      x1: px(R1 - 8, 0).toFixed(1), y1: py(R1 - 8, 0).toFixed(1),
      x2: px(R2 + 8, 0).toFixed(1), y2: py(R2 + 8, 0).toFixed(1),
      stroke: '#27ae60', 'stroke-width': 1.8, 'stroke-dasharray': '5,3',
      'marker-end': 'url(#cwArr)'
    }));

    for (var i = 0; i < N; i++) {
      var isA = (i === 0);
      svg.appendChild(mkSvg('text', {
        x: px(R1, i).toFixed(2), y: py(R1, i).toFixed(2),
        'text-anchor': 'middle', 'dominant-baseline': 'central',
        'font-size': isA ? 15 : 12, 'font-weight': 'bold',
        fill: isA ? '#0a4c8c' : '#1a7abf', 'font-family': 'monospace'
      }, A[i]));
      svg.appendChild(mkSvg('text', {
        x: px(R2, i).toFixed(2), y: py(R2, i).toFixed(2),
        'text-anchor': 'middle', 'dominant-baseline': 'central',
        'font-size': isA ? 15 : 12, 'font-weight': 'bold',
        fill: isA ? '#7b0d0d' : '#c0392b', 'font-family': 'monospace'
      }, A[(i + k) % N]));
    }
  }

  function redrawTable(k) {
    var h = '<table style="margin:auto;border-collapse:collapse;font-size:0.73em;">'
      + '<tr><td style="padding:2px 5px;font-weight:bold;color:#1a7abf;text-align:right">Plain</td>'
      + A.split('').map(function (c) {
          return '<td style="padding:1px 3px;font-weight:bold;color:#1a7abf;border:1px solid #cde">' + c + '</td>';
        }).join('')
      + '</tr><tr><td style="padding:2px 5px;font-weight:bold;color:#c0392b;text-align:right">Cipher</td>'
      + A.split('').map(function (_, i) {
          return '<td style="padding:1px 3px;font-weight:bold;color:#c0392b;border:1px solid #cde">' + A[(i + k) % N] + '</td>';
        }).join('')
      + '</tr></table>';
    document.getElementById('cw-tbl').innerHTML = h;
  }

  function redrawExample(k) {
    var enc = SAMPLE.split('').map(function (c) {
      var idx = A.indexOf(c);
      return idx >= 0 ? A[(idx + k) % N] : c;
    }).join('');
    document.getElementById('cw-eg').innerHTML =
      '<strong>Example:</strong> <span style="color:#1a7abf">' + SAMPLE + '</span>'
      + ' &rarr; <span style="color:#c0392b">' + enc + '</span>';
  }

  function update(k) {
    shift = ((k % N) + N) % N;
    document.getElementById('cw-val').textContent = shift;
    document.getElementById('cw-range').value = shift;
    redrawSvg(shift);
    redrawTable(shift);
    redrawExample(shift);
  }

  document.getElementById('cw-range').addEventListener('input', function () { update(+this.value); });
  document.getElementById('cw-dec').addEventListener('click', function () { update(shift - 1); });
  document.getElementById('cw-inc').addEventListener('click', function () { update(shift + 1); });
  update(3);
}());
</script>
```

#### Worked Examples

```{prf:example} Caesar Encryption (Arab American University)
:label: ex-caesar-aau

**For key $k = 2$ and plaintext $P =$ "Arab American University":**

$$\text{Enc}(2,\ \text{"Arab American University"}) = \text{"CTCD COGTKECPU WPKXGTUKVA"}$$

$$\text{Dec}(2,\ \text{"CTCD COGTKECPU WPKXGTUKVA"}) = \text{"Arab American University"}$$

---

**For key $k = 19$ and plaintext $P =$ "Arab American University":**

$$\text{Enc}(19,\ \text{"Arab American University"}) = \text{"ZYHI HTLYPJHU BUPCLYZPAF"}$$

$$\text{Dec}(19,\ \text{"ZYHI HTLYPJHU BUPCLYZPAF"}) = \text{"Arab American University"}$$
```

#### Caesar Cipher Key Space

```{admonition} Key Space Analysis
:class: warning
**Key Space Size:** $|\kappa| = 26$

- Only **26 possible shift values** (0 through 25)
- Key = 0: No shift (plaintext = ciphertext)
- Keys 1 through 25: Actual encryption
- Key = 26: Same as key = 0 (wraps around)

**Security Implication:**

$$\text{Extremely Small Key Space} \Rightarrow \text{Vulnerable to Exhaustive Search}$$

An attacker can simply try all 26 possibilities in seconds — or even manually in minutes.
```

#### Brute Force Attack on Caesar Cipher

The table below shows decryption attempts for ciphertext **"ZYHI HTLYPJHU BUPCLYZPAF"**. An attacker tries every key from 0 to 25:

| Shift | Decrypted Text | Makes Sense? |
|-------|----------------|:---:|
| 0 | ZYHI HTLYPJHU BUPCLYZPAF | ✗ |
| 1 | YXGH GSKXOIGT ATOBKXYOZE | ✗ |
| 2 | XWFG FRJWNHFS ZSNAJWXNYD | ✗ |
| 3 | WVEF EQIVMGER YRMZIVWMXC | ✗ |
| … | … | ✗ |
| **19** | **ARAB AMERICAN UNIVERSITY** | **✓** |

```{admonition} Time to Break by Brute Force
:class: note
**Simple Time Calculation Formula:**

$$\text{Time to break} = (\text{Number of keys}) \times (\text{Time per decryption})$$

| Step | Time Required |
|------|--------------|
| Try 1 key (decrypt a short message) | ~1 microsecond on a modern computer |
| Try all 26 keys | $26 \times 1\ \mu\text{s} = 26\ \mu\text{s}$ |
| Even by hand (writing each row out) | ~1–2 minutes |
```

::::{question} Check Your Understanding: Caesar Cipher
:type: multiple-choice
:variant: single-select
:showanswer:

How many keys does the Caesar cipher have, and what is the best attack strategy?
---
[ ] 26 keys; frequency analysis
> Frequency analysis works but is overkill — with only 26 keys you can simply try every one.
[x] 26 keys; exhaustive brute-force (try all shifts)
> Correct! With only 26 possible shift values, an attacker tries all of them in seconds.
[ ] 312 keys; exhaustive brute-force
> 312 is the Affine cipher's key space. Caesar has only 26 keys.
[ ] $26!$ keys; frequency analysis
> $26!$ is the General Substitution key space. Caesar has only 26 keys.
---
::::

### Interactive Caesar Cipher Demo

Try the Caesar cipher yourself!

```{admonition} How to Make It Interactive
:class: note
To run this code interactively:
1. Click the 🚀 rocket icon at the top of the page
2. Select "Live Code" to activate the interactive mode
3. Wait for the kernel to start (may take a few seconds)
4. Modify the `plaintext` and `key` values in the code below
5. Click the "run" button that appears above the code cell

Alternatively, you can copy this code and run it in your own Python environment.
```

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
        print("❌ Error: Decryption failed!")
    print("="*60)

# Change these values to experiment!
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
- **Key space:** Only $|\kappa| = 26$ possible keys
- **Vulnerability:** Trivial to break by brute force exhaustive search
- **Attack method:** Try all 26 possible shifts and apply human judgment

---

### 1.2 Affine Cipher

```{admonition} Historical Background
:class: note
The affine cipher is a **generalization of the Caesar cipher** using modular arithmetic. It introduces a multiplicative component, making key recovery harder than Caesar's additive-only shift.
```

```{prf:definition} Affine Cipher
:label: def-affine

**Encryption:** $C = (aP + k) \bmod 26$

**Decryption:** $P = a^{-1}(C - k) \bmod 26$

where:
- $a$ and $k$ are the two keys
- $\gcd(a, 26) = 1$ (so that $a^{-1}$ exists modulo 26)
- Valid values for $a$: $\{1, 3, 5, 7, 9, 11, 15, 17, 19, 21, 23, 25\}$
- $a^{-1}$ is the **modular multiplicative inverse** of $a$ modulo 26
```

#### Worked Example: Encryption

```{prf:example} Affine Encryption ($a=7$, $k=18$, plaintext = "hussein")
:label: ex-affine-enc

| # | Letter | Index $P$ | Calculation $(7P+18)\bmod 26$ | Cipher Index | Cipher |
|---|--------|-----------|-------------------------------|:---:|:---:|
| 1 | h | 7  | $(7\times7+18)\bmod26=67\bmod26=15$ | 15 | p |
| 2 | u | 20 | $(7\times20+18)\bmod26=158\bmod26=2$ | 2 | c |
| 3 | s | 18 | $(7\times18+18)\bmod26=144\bmod26=14$ | 14 | o |
| 4 | s | 18 | $(7\times18+18)\bmod26=144\bmod26=14$ | 14 | o |
| 5 | e | 4  | $(7\times4+18)\bmod26=46\bmod26=20$ | 20 | u |
| 6 | i | 8  | $(7\times8+18)\bmod26=74\bmod26=22$ | 22 | w |
| 7 | n | 13 | $(7\times13+18)\bmod26=109\bmod26=5$ | 5 | f |

**Result:** "hussein" → **"pcoouwf"**
```

#### Finding the Modular Inverse

To decrypt, we first need $a^{-1}$ — the modular multiplicative inverse of $a$ modulo 26.

**Method 1: Brute-Force Search** (simple for small moduli)

We need to find $x$ such that $7x \bmod 26 = 1$. Try $x = 1, 2, 3, \ldots$ until we find it:

$$7\times1=7,\quad 7\times2=14,\quad 7\times3=21,\quad 7\times4=28\equiv2,\quad \ldots,\quad 7\times15=105\equiv1\ \pmod{26}$$

So $a^{-1} = 15$. ✓

**Method 2: Extended Euclidean Algorithm** (efficient for large numbers)

Solve $7x \equiv 1 \pmod{26}$. Start with $A=26,\ B=7,\ T_1=0,\ T_2=1$, then repeatedly compute $Q=\lfloor A/B \rfloor$, $R = A - Q\cdot B$, and $T = T_1 - Q\cdot T_2$:

| Step | Q | A  | B | R | $T_1$ | $T_2$ | $T = T_1 - Q\cdot T_2$ |
|------|---|----|---|---|-------|-------|--------------------------|
| 1 | 3 | 26 | 7 | 5 | 0  | 1  | $0-1\cdot3 = -3$ |
| 2 | 1 | 7  | 5 | 2 | 1  | -3 | $1-(-3)\cdot1 = 4$ |
| 3 | 2 | 5  | 2 | 1 | -3 | 4  | $-3-4\cdot2 = -11$ |
| 4 | 2 | 2  | 1 | 0 | 4  | -11 | $4-(-11)\cdot2 = 26$ |

Computation stops when $B=1$ (GCD found). The last $T_2$ value is $-11$.

Since we need a positive residue: $-11 \bmod 26 = 26 - 11 = \mathbf{15}$ ✓

#### Modulus of Negative Numbers

When decrypting the affine cipher, we encounter negative numbers modulo 26.

```{admonition} Rule: Modulus of Negative Numbers
:class: tip
For $-n \bmod m$:
1. Ignore the sign and compute the remainder: $n \div m$ gives remainder $r$
2. If $r \neq 0$, the result is $m - r$
3. If $r = 0$, the result is $0$

**Example:** $-6 \bmod 5 = ?$

$6 = 5\times 1 + 1$, so remainder $r = 1$. Since original is negative: $5 - 1 = \mathbf{4}$

**Verification:** $-6 = 5\times(-2) + 4$ ✓
```

#### Worked Example: Decryption

```{prf:example} Affine Decryption ($a=7$, $k=18$, ciphertext = "pcoouwf")
:label: ex-affine-dec

Using $P = a^{-1}(C-k)\bmod26 = 15(C-18)\bmod26$:

| # | Cipher | Index $C$ | Calculation $15(C-18)\bmod 26$ | Plaintext |
|---|--------|-----------|--------------------------------|-----------|
| 1 | p | 15 | $15\times(15-18)\bmod26=15\times(-3)\bmod26=-45\bmod26=7$ | h |
| 2 | c | 2  | $15\times(2-18)\bmod26=15\times(-16)\bmod26=-240\bmod26=20$ | u |
| 3 | o | 14 | $15\times(14-18)\bmod26=15\times(-4)\bmod26=-60\bmod26=18$ | s |
| 4 | o | 14 | $15\times(14-18)\bmod26=18$ | s |
| 5 | u | 20 | $15\times(20-18)\bmod26=30\bmod26=4$ | e |
| 6 | w | 22 | $15\times(22-18)\bmod26=60\bmod26=8$ | i |
| 7 | f | 5  | $15\times(5-18)\bmod26=15\times(-13)\bmod26=-195\bmod26=13$ | n |

**Note for row 1:** $-45 \bmod 26$ → $45=26\times1+19$, so $26-19=\mathbf{7}$ → h ✓

**Result:** "pcoouwf" → **"hussein"** ✓
```

#### Affine Cipher Key Space

```{admonition} Key Space Analysis
:class: note
**Valid values for $a$** (must be coprime with 26): $\phi(26) = 12$ values

$\{1, 3, 5, 7, 9, 11, 15, 17, 19, 21, 23, 25\}$

**Valid values for $k$**: Any integer from 0 to 25 → 26 possibilities

$$|\kappa| = 12 \times 26 = \mathbf{312}$$

Much larger than Caesar's 26, but still small by modern standards.
```

::::{question} Check Your Understanding: Affine Cipher
:type: multiple-choice
:variant: single-select
:showanswer:

Why must $\gcd(a, 26) = 1$ for the affine cipher key $a$?
---
[ ] To make the ciphertext look more random
> Randomness of output is unrelated to the coprimality requirement.
[ ] To ensure $a$ is a prime number
> $a$ need not be prime — for example, $a=9$ is valid ($\gcd(9,26)=1$) and is not prime.
[x] So that the modular inverse $a^{-1} \bmod 26$ exists, enabling decryption
> Correct! $a^{-1} \bmod 26$ exists if and only if $\gcd(a, 26) = 1$. Without it, decryption is impossible.
[ ] To prevent frequency analysis
> Coprimality does not affect resistance to frequency analysis.
---
::::

**Example:** With $a = 5$, $k = 8$:
~~~
P = 7 (letter H)
C = (5 × 7 + 8) mod 26 = 43 mod 26 = 17 (letter R)
~~~

---

### 1.3 Substitution Cipher (General)

A general substitution cipher uses an **arbitrary permutation** of the alphabet.

**Example:**
~~~
Plaintext alphabet:  ABCDEFGHIJKLMNOPQRSTUVWXYZ
Ciphertext alphabet: QWERTYUIOPASDFGHJKLZXCVBNM
~~~

**Security Analysis:**
- **Key space:** $26! \approx 4 \times 10^{26}$ possible keys
- **Vulnerability:** Frequency analysis
- **Attack method:** Statistical analysis of letter frequencies

```{admonition} Frequency Analysis
:class: note
Frequency analysis exploits the fact that in any language, certain letters appear more often than others (e.g., E ≈ 12.7%, T ≈ 9.1% in English). An attacker counts letter frequencies in the ciphertext and matches them to known language statistics to recover the substitution mapping. A full treatment is in **Chapter 4**.
```

## 3. Polyalphabetic Ciphers

Polyalphabetic ciphers use multiple substitution alphabets to resist frequency analysis.

### 3.1 Vigenère Cipher

The Vigenère cipher was named after French cryptographer **Blaise de Vigenère** and was considered **unbreakable for centuries** (known as "le chiffre indéchiffrable").

```{admonition} Key Idea
:class: tip
Instead of using a single shift key (like Caesar), the Vigenère cipher uses a **keyword** — a sequence of shifts that repeats throughout the message. This distributes the statistical patterns, defeating simple frequency analysis.

- Built from a collection of Caesar ciphers in series
- Uses a **Tabula Recta** (a 26×26 alphabet grid)
- The key is a repeated keyword
```

```{prf:definition} Vigenère Cipher
:label: def-vigenere

Uses a keyword to determine the shift for each letter.

**Encryption:** $c_i = (m_i + k_i) \bmod 26$

**Decryption:** $m_i = (c_i - k_i) \bmod 26$

where:
- $m$ is the plaintext message, $c$ is the ciphertext
- $k$ is the keyword (repeated to match message length)
- $m_i$ and $k_i$ are the numeric indices of the $i$-th message and key letters
```

#### Formal Algorithm

```{prf:algorithm} Vigenère Cipher (Gen / Enc / Dec)
:label: algo-vigenere

**Input:** Keyword $s$ of length $\kappa$, message $m$.

**Key Generation:** $s \leftarrow \text{Gen}(\kappa)$ — outputs a uniformly random string $s$ of length $\kappa$.

**Encryption:** $c \leftarrow \text{Enc}(s, m)$ — repeat $s$ to match length of $m$, then:
$$c_i = (m_i + k_i) \bmod 26$$

**Decryption:** $m \leftarrow \text{Dec}(s, c)$ — repeat $s$ to match length of $c$, then:
$$m_i = (c_i - k_i) \bmod 26$$

where $k_i$ is the numeric position of the $i$-th key letter.
```

#### Tabula Recta

The Tabula Recta is a 26×26 grid used for Vigenère lookups. Row $i$ is the alphabet shifted by $i$ positions (row A = standard alphabet, row B shifted by 1, etc.).

**How to encrypt using the Tabula Recta:**
1. Find the **row** for the key letter
2. Find the **column** for the plaintext letter
3. The **cell at that intersection** is the ciphertext letter

**How to decrypt:**
1. Find the **key letter's row**
2. In that row, **locate the ciphertext letter**
3. The **column header** is the plaintext letter

*Example:* plaintext **H**, key **C** → row C, column H → value **J** (shifted by 2)

#### Worked Example: Encryption

```{prf:example} Vigenère Encryption (Key = "COVER", Plaintext = "HUSSEIN YOUNIS")
:label: ex-vigenere-enc

**Standard Alphabet:** A=0, B=1, C=2, D=3, E=4, R=17, V=21, O=14, …

| Pos | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 |
|-----|---|---|---|---|---|---|---|---|---|----|----|----|----|
| Plaintext ($m$) | H | U | S | S | E | I | N | Y | O | U  | N  | I  | S  |
| $m_i$ index     | 7 | 20| 18| 18| 4 | 8 | 13| 24| 14| 20 | 13 | 8  | 18 |
| Key ($k$, repeated) | C | O | V | E | R | C | O | V | E | R  | C  | O  | V  |
| $k_i$ index     | 2 | 14| 21| 4 | 17| 2 | 14| 21| 4 | 17 | 2  | 14 | 21 |
| $c_i = (m_i+k_i)\bmod26$ | 9 | 8 | 13| 22| 21| 10| 1 | 19| 18| 11 | 15 | 22 | 13 |
| Ciphertext ($c$) | J | I | N | W | V | K | B | T | S | L  | P  | W  | N  |

**Result:** "HUSSEIN YOUNIS" → **"JINWVKBTSLPWN"**
```

```{prf:example} Vigenère Decryption (Key = "COVER", Ciphertext = "JINWVKBTSLPWN")
:label: ex-vigenere-dec

Using $m_i = (c_i - k_i) \bmod 26$:

| Ciphertext ($c_i$) | 9 | 8 | 13 | 22 | 21 | 10 | 1 | 19 | 18 | 11 | 15 | 22 | 13 |
|--------------------|---|---|----|----|----|----|---|----|----|----|----|----|----|
| Key index ($k_i$)  | 2 | 14| 21 | 4  | 17 | 2  | 14| 21 | 4  | 17 | 2  | 14 | 21 |
| $m_i$ index        | 7 | 20| 18 | 18 | 4  | 8  | 13| 24 | 14 | 20 | 13 | 8  | 18 |
| Plaintext          | H | U | S  | S  | E  | I  | N | Y  | O  | U  | N  | I  | S  |

**Result:** "JINWVKBTSLPWN" → **"HUSSEIN YOUNIS"** ✓
```

#### Vigenère Key Space

```{admonition} Key Space Analysis
:class: note
For a keyword of length $L$, with 26 possible letters at each position:

$$|\kappa| = 26^L$$

| Keyword Length $L$ | Key Space $26^L$ | Notes |
|-------------------|------------------|-------|
| 1 | $26$ | Same as Caesar — trivial |
| 2 | $676$ | Very easy |
| 3 | $17{,}576$ | Trivial for any computer |
| 4 | $456{,}976$ | Easily searched |
| 5 | $\approx 11.9 \times 10^6$ | ~12 million; broken quickly |
| 6 | $\approx 3.1 \times 10^8$ | 300 million |
| 7 | $\approx 8.0 \times 10^9$ | 8 billion |
| 8 | $\approx 2.1 \times 10^{11}$ | 208 billion |
| 9 | $\approx 5.4 \times 10^{12}$ | 5 trillion |
| 10 | $\approx 1.4 \times 10^{14}$ | 141 trillion |

Key length $L = 10$ provides $\approx 10^{14}$ keys — brute-force practically impossible, yet the cipher is still broken by Kasiski + frequency analysis!
```

::::{question} Check Your Understanding: Vigenère Cipher
:type: multiple-choice
:variant: single-select
:showanswer:

The Vigenère cipher with a very long keyword is hard to brute-force. Why can it still be broken?
---
[ ] Because 26 letter frequencies are always the same
> Simple frequency analysis alone fails against Vigenère due to polyalphabetic substitution.
[x] The Kasiski examination finds the key length, then frequency analysis breaks each Caesar sub-cipher
> Correct! Kasiski exploits repeated patterns to determine the key length, after which each position becomes a simple Caesar cipher breakable by frequency analysis.
[ ] Because the Tabula Recta is publicly known
> The Tabula Recta being public does not break the cipher — Kerckhoffs’s Principle says algorithms can be public.
[ ] Because it has the same key space as the Caesar cipher
> The Vigenère key space ($26^L$) is vastly larger than Caesar’s 26 keys.
---
::::

**Example:** With keyword "KEY":
~~~
Plaintext:  ATTACKATDAWN
Keyword:    KEYKEYKEYKEY
Ciphertext: KXVGOKXDOKFX
~~~

**Encryption Process:**
- A + K = K
- T + E = X
- T + Y = V
- And so on…

**Security Analysis:**
- **Strength:** Resists simple frequency analysis
- **Weakness:** Kasiski examination and index of coincidence
- **Key length:** Security increases with key length, but not immune to statistical attack

### 3.2 Breaking Vigenère: Kasiski Examination

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

## 4. Transposition Ciphers

Transposition ciphers rearrange the positions of characters rather than substituting them.

```{prf:definition} Transposition Cipher
:label: def-transposition

Unlike substitution ciphers that **replace** characters, transposition ciphers **rearrange** the positions of characters. The plaintext characters remain the same but appear in a different order.

- **Substitution:** A → D (identity of character changes)
- **Transposition:** "HELLO" → "LLOHE" (same characters, different order)
```

### 4.1 Rail Fence Cipher

Characters are written in a zigzag pattern and read row by row.

**Example with 3 rails:**
~~~
Plaintext: WEAREDISCOVEREDFLEEATONCE

W . . . E . . . C . . . R . . . L . . . T . . . E
. E . R . D . S . O . E . E . F . E . A . O . C .
. . A . . . I . . . V . . . D . . . E . . . N . .

Rail 1: WECRLTE
Rail 2: ERDSOEEFEAOC
Rail 3: AIVDEN

Ciphertext: WECRLTEERDSOEEFEAOCAIVDEN
~~~

### 4.2 Columnar Transposition

Text is written in rows and read column by column according to a numerical key.

**Example with key "3142":**
~~~
Key:        3 1 4 2
Plaintext:  A T T A
            C K A T
            D A W N

Read columns in sorted key order (1,2,3,4):
Column 1: T, K, A  →  TKA
Column 2: A, T, N  →  ATN
Column 3: A, C, D  →  ACD
Column 4: T, A, W  →  TAW

Ciphertext: TKAATNACDTAW
~~~

```{prf:example} Columnar Transposition (Key = "4312", Plaintext = "ATTACK AT DAWN")
:label: ex-columnar

**Key:** 4 3 1 2 — sorted column read order: 1st, 2nd, 3rd, 4th

Write plaintext row by row under the numeric key:

| Key order | 4 | 3 | 1 | 2 |
|-----------|---|---|---|---|
| Row 1     | A | T | T | A |
| Row 2     | C | K | A | T |
| Row 3     | D | A | W | N |

Read columns **in key order 1, 2, 3, 4**:
- Column labeled "1" (position 3): T, A, W → **TAW**
- Column labeled "2" (position 4): A, T, N → **ATN**
- Column labeled "3" (position 2): T, K, A → **TKA**
- Column labeled "4" (position 1): A, C, D → **ACD**

**Ciphertext:** TAWATNTKAAD
```

## 5. Product Ciphers

**Product ciphers** combine substitution and transposition to create stronger ciphers.

```{admonition} Design Principle
:class: note
Modern block ciphers (like AES) use multiple rounds of substitution and permutation—this is a form of product cipher.
```

## 6. Historical Cryptanalysis

### The Enigma Machine

The German Enigma machine was considered unbreakable but was eventually cracked by Allied cryptanalysts, including Alan Turing.

**Why it was broken:**
- Operators made mistakes
- Repeated message formats
- Known plaintext attacks
- Cribs (guessed plaintext sections)

## 7. Lessons for Modern Cryptography

Classical ciphers teach us:

1. **Security through obscurity fails** - Algorithm secrecy doesn't ensure security
2. **Key space matters** - But isn't everything
3. **Statistical properties persist** - Even with substitution
4. **Randomness is crucial** - Patterns can be exploited

## 8. Summary

::::{grid} 2
:gutter: 2

:::{grid-item-card} Substitution Ciphers
- Caesar: $C=(P+k)\bmod26$, $|\kappa|=26$
- Affine: $C=(aP+k)\bmod26$, $|\kappa|=312$
- General: $26!$ keys, broken by frequency analysis
:::

:::{grid-item-card} Polyalphabetic
- Vigenère: $|\kappa|=26^L$
- Uses Tabula Recta
- Broken by Kasiski + Index of Coincidence
:::

:::{grid-item-card} Transposition
- Rail Fence: zigzag pattern
- Columnar: column reordering by key
- Characters preserved, order changed
:::

::::

**Cipher Weaknesses and Attack Methods**

| Cipher Type | Primary Weakness | Attack Method |
|-------------|------------------|---------------|
| Caesar | Small key space | Brute force |
| Affine | Small key space | Brute force or frequency analysis |
| Substitution | Letter frequencies | Frequency analysis |
| Vigenère | Repeating key | Kasiski, IC, frequency analysis |
| Transposition | Pattern preservation | Anagramming, pattern recognition |

Classical ciphers introduced:
- ✅ Substitution ciphers (Caesar, Affine, General)
- ✅ Frequency analysis techniques
- ✅ Polyalphabetic ciphers (Vigenère)
- ✅ Transposition ciphers (Rail Fence, Columnar)
- ✅ Cryptanalysis methods (brute force, Kasiski, IC)

```{admonition} Next Steps
:class: tip
In the next chapter, we'll dive deeper into cryptanalysis and learn systematic approaches to breaking ciphers.
```

## 9. Exercises

```{exercise} Decrypt a Caesar Cipher
:label: ch03-ex-caesar-decrypt

Decrypt the following Caesar cipher (unknown shift):
`WKLV LV D VHFUHW PHVVDJH`
```

```{solution} ch03-ex-caesar-decrypt
:label: sol-ch03-ex-caesar-decrypt
:class: dropdown

Try shift $k=3$: W→T, K→H, L→I, V→S → **"THIS IS A SECRET MESSAGE"** ✓
```

```{exercise} Affine Cipher Encryption
:label: ch03-ex-affine-encrypt

Encrypt "HELLO" using an affine cipher with $a = 7$ and $b = 3$.
```

```{solution} ch03-ex-affine-encrypt
:label: sol-ch03-ex-affine-encrypt
:class: dropdown

$C = (7P + 3) \bmod 26$

H=7: $(7\times7+3)\bmod26=52\bmod26=0$ → A  
E=4: $(7\times4+3)\bmod26=31\bmod26=5$ → F  
L=11: $(7\times11+3)\bmod26=80\bmod26=2$ → C  
L=11: $(7\times11+3)\bmod26=80\bmod26=2$ → C  
O=14: $(7\times14+3)\bmod26=101\bmod26=23$ → X  

**Result: "AFCCX"**
```

```{exercise} Find the Modular Inverse
:label: ch03-ex-affine-inverse

Find the modular inverse of $11$ modulo $26$ using brute-force and the Extended Euclidean Algorithm.
```

```{solution} ch03-ex-affine-inverse
:label: sol-ch03-ex-affine-inverse
:class: dropdown

**Brute-force:** Try $11\times x\bmod26=1$:

$x=1$: 11, $x=2$: 22, $x=3$: 33≡7, $x=4$: 44≡18, $x=5$: 55≡3, …, $x=19$: $11\times19=209=8\times26+1\equiv1$ ✓

So $11^{-1} \equiv 19 \pmod{26}$.

**Verification:** $11 \times 19 = 209 = 8 \times 26 + 1$ ✓
```

```{exercise} Negative Modular Arithmetic
:label: ch03-ex-negative-modulus

Compute: (a) $-45 \bmod 26$, (b) $-195 \bmod 26$.
```

```{solution} ch03-ex-negative-modulus
:label: sol-ch03-ex-negative-modulus
:class: dropdown

(a) $45 = 26\times1 + 19$, remainder $r=19$. Since negative: $26-19=\mathbf{7}$

(b) $195 = 26\times7 + 13$, remainder $r=13$. Since negative: $26-13=\mathbf{13}$
```

```{exercise} Vigenère Encryption
:label: ch03-ex-vigenere

Encrypt "CRYPTOGRAPHY" using the Vigenère cipher with keyword "MATH".
```

```{solution} ch03-ex-vigenere
:label: sol-ch03-ex-vigenere
:class: dropdown

Key repeats: M A T H M A T H M A T H

C=2,  M=12: $(2+12)\bmod26=14$ → O  
R=17, A=0:  $(17+0)\bmod26=17$ → R  
Y=24, T=19: $(24+19)\bmod26=17$ → R  
P=15, H=7:  $(15+7)\bmod26=22$ → W  
T=19, M=12: $(19+12)\bmod26=5$ → F  
O=14, A=0:  $(14+0)\bmod26=14$ → O  
G=6,  T=19: $(6+19)\bmod26=25$ → Z  
R=17, H=7:  $(17+7)\bmod26=24$ → Y  
A=0,  M=12: $(0+12)\bmod26=12$ → M  
P=15, A=0:  $(15+0)\bmod26=15$ → P  
H=7,  T=19: $(7+19)\bmod26=0$  → A  
Y=24, H=7:  $(24+7)\bmod26=5$  → F  

**Result: "ORRWFOZYMPAF"**
```

```{exercise} Frequency Analysis Steps
:label: ch03-ex-freq-analysis

Describe the step-by-step process for performing frequency analysis on a ciphertext.
```

## Further Reading

- {cite}`stinson2018cryptography` - Chapter on classical cryptography
- {cite}`schneier2015applied` - Historical ciphers and their weaknesses
