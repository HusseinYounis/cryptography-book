# Chapter Authoring Guide

Complete reference for adding, updating, and modifying chapters in this TeachBooks/Jupyter Book project.

---

## 1. Project Structure

```
interactiveBook/
├── book/
│   ├── _config.yml          ← Sphinx/JupyterBook configuration
│   ├── _toc.yml             ← Table of contents (register every chapter here)
│   ├── intro.md             ← Book landing page (root)
│   ├── references.bib       ← BibTeX reference database
│   ├── chapters/            ← All chapter .md and .ipynb files
│   │   ├── 01_introduction.md
│   │   ├── 02_1_mathematical_foundations.md
│   │   └── ...
│   ├── figures/             ← Static images, organised by chapter
│   │   ├── ch01/
│   │   ├── ch02_1/
│   │   └── README.md
│   └── _static/
│       └── custom.css       ← Custom CSS overrides
└── CHAPTER_GUIDE.md         ← This file
```

---

## 2. Adding a New Chapter

### Step 1 — Create the file

Place `.md` files in `book/chapters/`. Use the naming convention:
```
NN_slug.md           → e.g. 15_block_cipher_modes.md
NN_N_sub_topic.md    → e.g. 02_2_computer_fundamentals.md
```

For notebook-based chapters use `.ipynb` instead (see §8).

### Step 2 — Register in `_toc.yml`

Open `book/_toc.yml` and add the file under the correct `part`:

```yaml
parts:
  - caption: My Part Title
    chapters:
    - file: chapters/15_block_cipher_modes.md
```

### Step 3 — Add figures folder (if needed)

```
book/figures/ch15/
```

### Step 4 — Build

```bash
cd "/run/media/hussein/New Volume1/Cources/Introduction to Cryptography/interactiveBook"
source .venv/bin/activate        # activate virtualenv (if needed)
jupyter-book build book/
```

Output: `book/_build/html/index.html`

> **Important:** Use `jupyter-book build book/`, not `teachbooks build book/`
> (teachbooks requires `sphinxcontrib.mermaid` to be installed system-wide).

---

## 3. Chapter File Structure

Every chapter follows this skeleton in order:

```markdown
# Chapter N: Title

```{figure} ../figures/chNN/banner.jpg
:align: center
:width: 60%
```

---

## Warm-Up: [Engaging Puzzle or Question]

[Short problem that motivates the topic]

```{admonition} Solution
:class: dropdown
[Answer with explanation]
```

---

## 1. First Section

...content...

---

## Summary

| Concept | Definition | Cryptographic Use |
|:---|:---|:---|
| ... | ... | ... |

---

## Exercises

[exercise + solution blocks]

[interactive question blocks]
```

---

## 4. All Available Directives & Syntax

### 4.1 `{prf:definition}` — Numbered Definitions

Use for all formal definitions.

```markdown
```{prf:definition} Definition Title
:label: def-slug

Definition text with $math$ inline or

$$block math$$
```
```

Cross-reference: `` {prf:ref}`def-slug` ``

---

### 4.2 `{prf:theorem}` — Numbered Theorems

```markdown
```{prf:theorem} Theorem Title
:label: thm-slug

Statement of the theorem, usually with a formal equation.
```
```

---

### 4.3 `{prf:algorithm}` — Numbered Algorithms

```markdown
```{prf:algorithm} Algorithm Title
:label: algo-slug

**Input:** Description

**Output:** Description

1. Step one
2. Step two
3. Return result
```
```

---

### 4.4 `{prf:example}` — Numbered Examples

```markdown
```{prf:example} Example Title
:label: ex-slug

Problem statement and worked solution.
```
```

> **Nesting note:** If the example body contains a `::::{grid}` block (multi-column layout),
> use **5-colon fencing** for the outer directive:
>
> ````markdown
> :::::{prf:example} Title with grid inside
> :label: ex-slug
>
> ::::{grid} 1 2 2 2
> ...
> ::::
> :::::
> ````

---

### 4.5 `{prf:criterion}` — Numbered Principles/Criteria

Use for named principles (e.g. Kerckhoffs's Principle).

```markdown
```{prf:criterion} Criterion Title
:label: crit-slug

Statement of the principle.
```
```

---

### 4.6 `{exercise}` + `{solution}` — Graded Exercises

```markdown
```{exercise} Exercise Title
:label: chNN-ex-slug

Exercise question text. Can contain math, lists, tables.
```

```{solution} chNN-ex-slug        ← must match the exercise label exactly
:label: sol-chNN-ex-slug
:class: dropdown                   ← makes the solution collapsible

Full worked solution.
```
```

---

### 4.7 `{question}` — Interactive Self-Assessment Questions

#### Multiple Choice — Single Select

```markdown
::::{question} Question Title
:type: multiple-choice
:variant: single-select
:showanswer:

Question text?
---
[ ] Wrong option
> Feedback shown when this is selected.
[x] Correct option
> Feedback for correct answer.
[ ] Another wrong option
> Feedback for this distractor.
---
::::
```

#### Multiple Choice — Multi-Select

```markdown
::::{question} Question Title
:type: multiple-choice
:variant: multiple-select
:showanswer:

Which of the following are true? (Select all that apply)
---
[x] Correct item A
> Feedback A.
[ ] Wrong item B
> Feedback B.
[x] Correct item C
> Feedback C.
---
::::
```

#### Short Answer — Math Input

```markdown
::::{question} Question Title
:type: short-answer
:variant: blocks
:showanswer:

Compute $\phi(7)$ (enter a whole number):
---
M[6] $\phi(7) =$
= Correct! Because 7 is prime, $\phi(7) = 7-1 = 6$.
> Incorrect. Hint: For a prime $p$, $\phi(p) = p-1$.
---
::::
```

> **Fence depth rule:** `{question}` requires `::::` (4 colons).
> If `{question}` is nested inside another directive, increase to `:::::`+.

---

### 4.8 `{admonition}` — Styled Call-Out Boxes

```markdown
```{admonition} Box Title
:class: tip | note | important | warning | danger | dropdown

Content here.
```
```

| Class | Rendered as | Use for |
|:---|:---|:---|
| `tip` | Green tip box | Key takeaways, summaries |
| `note` | Blue note box | Supplementary information |
| `important` | Orange box | "Why this matters in cryptography" |
| `warning` | Red warning box | Common mistakes, security gotchas |
| `dropdown` | Collapsible | Hints, warm-up solutions |

---

### 4.9 `{figure}` — Images

```markdown
```{figure} ../figures/chNN/image_name.png
:align: center
:width: 70%
:alt: Descriptive alt text
Caption text shown below the figure.
```
```

Supported formats: `.png`, `.jpg`, `.svg`

Put files in `book/figures/chNN/` (create the folder if needed).

---

### 4.10 Math

- **Inline:** `$a \equiv b \pmod{n}$`
- **Block:** `$$a^{\phi(n)} \equiv 1 \pmod{n}$$`
- **AMSmath environments** (enabled via `myst_enable_extensions`):

```markdown
```{math}
:label: eq-label
a^{\phi(n)} \equiv 1 \pmod{n}
```
```

Reference an equation: `` {eq}`eq-label` ``

---

### 4.11 Tables

Use standard Markdown tables. For centered columns:

```markdown
| Expression | Result | Note |
|:---:|:---:|:---:|
| $23 \bmod 6$ | **5** | $a > b$ |
```

For left-aligned:
```markdown
| Concept | Definition |
|:---|:---|
```

---

### 4.12 `{mermaid}` — Diagrams

```markdown
```{mermaid}
graph LR
    A[Plaintext] -->|Encrypt with Key| B[Ciphertext]
    B -->|Decrypt with Key| C[Plaintext]
```
```

Mermaid supports: `graph`, `sequenceDiagram`, `flowchart`, `classDiagram`, `stateDiagram`

---

### 4.13 Multi-Column Grid Layout

```markdown
::::{grid} 1 2 2 2
:gutter: 3

:::{grid-item}
Left column content
:::

:::{grid-item}
Right column content
:::
::::
```

The four numbers are column counts for xs / sm / md / lg screen sizes.

---

### 4.14 `{tabset}` — Tabbed Content

```markdown
:::::{tab-set}
::::{tab-item} Method A
Content for tab A
::::

::::{tab-item} Method B
Content for tab B
::::
:::::
```

---

### 4.15 Citation References

```markdown
{cite}`bibtex_key`           ← inline citation
{cite:t}`bibtex_key`         ← textual citation: "Author (Year)"
{cite:p}`bibtex_key`         ← parenthetical citation: "(Author, Year)"
```

Add entries to `book/references.bib`:

```bibtex
@book{stinson2018cryptography,
  author    = {Stinson, Douglas R.},
  title     = {Cryptography: Theory and Practice},
  year      = {2018},
  edition   = {4},
  publisher = {CRC Press}
}
```

Render full bibliography at end of chapter:

```markdown
```{bibliography}
:filter: docname in docnames
```
```

---

## 5. Label Naming Convention

Consistent labels enable cross-referencing between chapters.

| Element | Prefix | Example |
|:---|:---|:---|
| Definition | `def-` | `def-cryptography` |
| Theorem | `thm-` | `thm-shannon` |
| Algorithm | `algo-` | `algo-euclidean` |
| Example | `ex-` | `ex-mod14` |
| Criterion | `crit-` | `crit-kerckhoffs` |
| Exercise | `chNN-ex-slug` | `ch02-ex-mod` |
| Solution | `sol-chNN-ex-slug` | `sol-ch02-ex-mod` |
| Equation | `eq-` | `eq-euler` |

---

## 6. Cross-Referencing

| Type | Syntax | Renders as |
|:---|:---|:---|
| prf: element | `` {prf:ref}`def-cryptography` `` | Definition 1.1 |
| Exercise | `` {ref}`ch02-ex-mod` `` | Exercise 1 |
| Equation | `` {eq}`eq-euler` `` | (1.1) |
| Section | `` {ref}`section-anchor` `` | Section title |
| Figure | `` {numref}`fig-slug` `` | Figure 1 |

To target a section, add a label above it:

```markdown
(section-anchor)=
## My Section
```

---

## 7. Chapter Checklist

Before finishing a chapter, verify each item:

- [ ] File added and registered in `_toc.yml`
- [ ] Banner figure at top (`../figures/chNN/banner.jpg`)
- [ ] Warm-up puzzle with `{admonition} Solution :class: dropdown`
- [ ] All formal definitions use `{prf:definition}` with `:label: def-*`
- [ ] All theorems use `{prf:theorem}` with `:label: thm-*`
- [ ] All algorithms use `{prf:algorithm}` with `:label: algo-*`
- [ ] All worked examples use `{prf:example}` with `:label: ex-*`
- [ ] Named principles use `{prf:criterion}` with `:label: crit-*`
- [ ] "Why this matters in cryptography" `{admonition} :class: important` near each key theorem
- [ ] At least one `{question}` interactive block per major section
- [ ] Summary table at end of content sections
- [ ] `{exercise}` + paired `{solution} :class: dropdown` for every exercise
- [ ] BibTeX keys referenced exist in `references.bib`
- [ ] All labels are unique book-wide
- [ ] Book builds with zero new warnings: `jupyter-book build book/`

---

## 8. Notebook Chapters (`.ipynb`)

For chapters with executable code (like `14_practical_applications.ipynb`):

- Use `.ipynb` format instead of `.md`
- Register in `_toc.yml` the same way
- Code cells are run if `execute_notebooks: "auto"` in `_config.yml` (currently `"off"`)
- To enable live code (Thebe), the `thebe_config` is already set in `_config.yml`
- Add interactive Plotly figures in code cells for interactive visualizations

---

## 9. `_config.yml` Key Settings

| Setting | Current Value | Notes |
|:---|:---|:---|
| `execute.execute_notebooks` | `"off"` | Change to `"auto"` to run notebooks on build |
| `sphinx.extra_extensions` | `teachbooks_favourites`, `sphinxcontrib.mermaid` | Do not remove `teachbooks_favourites` |
| `html_theme_options.launch_buttons.thebe` | `true` | Enables Live Code button in browser |
| `bibtex_bibfiles` | `[references.bib]` | Add more `.bib` files here if needed |
| `myst_enable_extensions` | list | Add `"colon_fence"` if not present (required for `:::` directives) |

---

## 10. Extensions Bundled in `teachbooks_favourites`

All of these are available without additional installation:

| Extension | Directives | Description |
|:---|:---|:---|
| `sphinx-proof` | `{prf:definition}`, `{prf:theorem}`, `{prf:algorithm}`, `{prf:example}`, `{prf:criterion}`, `{prf:lemma}`, `{prf:corollary}`, `{prf:remark}` | Numbered, cross-referenceable math elements |
| `sphinx-exercise` | `{exercise}`, `{solution}` | Graded exercise blocks with collapsible solutions |
| `teachbooks-questions` | `{question}` | Interactive multiple-choice and short-answer questions with instant browser feedback |
| `sphinx-design` | `{grid}`, `{card}`, `{tab-set}`, `{tab-item}`, `{dropdown}`, `{badge}` | Layout and UI components |
| `sphinx-thebe` | (automatic) | Live code execution via Binder/Thebe in browser |
| `sphinx-book-theme` | (automatic) | The visual theme of the book |
| `sphinxcontrib.mermaid` | `{mermaid}` | Flowcharts and diagrams (separately installed) |

---

## 11. Build Commands Reference

```bash
# Standard build
jupyter-book build book/

# Build and show only warnings/errors
jupyter-book build book/ 2>&1 | grep -i "warning\|error"

# Clean build (removes cached environment — use after major structural changes)
jupyter-book clean book/
jupyter-book build book/

# View built book
xdg-open book/_build/html/index.html
```

Current build warnings (pre-existing, not caused by chapter edits):

| File | Warning | Fix |
|:---|:---|:---|
| `03_classical_ciphers.md` | missing bibtex keys | Add to `references.bib` |
| `05_symmetric_encryption.md` | missing bibtex keys | Add to `references.bib` |
| `09_rsa.md` | missing bibtex key `rivest1978method` | Add to `references.bib` |
| `10_elliptic_curves.md` | missing bibtex key `koblitz1987elliptic` | Add to `references.bib` |
| `13_key_exchange.md` | missing bibtex key `diffie1976new` | Add to `references.bib` |

---

## 12. One-Page Quick Reference

```
{prf:definition}   → numbered definitions        label: def-*
{prf:theorem}      → numbered theorems           label: thm-*
{prf:algorithm}    → numbered algorithms         label: algo-*
{prf:example}      → numbered worked examples    label: ex-*
{prf:criterion}    → named principles            label: crit-*
{exercise}         → exercise block              label: chNN-ex-*
{solution} X       → solution for exercise X     label: sol-chNN-ex-*  :class: dropdown
{question}         → interactive quiz            ::::{question} ... ::::
{admonition}       → call-out box                :class: tip|note|important|warning|dropdown
{figure}           → image                       ../figures/chNN/file.ext
{mermaid}          → diagram
{tab-set}/{card}   → layout components
$...$  /  $$...$$  → inline / block math
{cite}`key`        → bibliography citation
{prf:ref}`label`   → cross-reference prf element
```
