# Project Structure and Overview

## 📁 Directory Structure

```
interactiveBook/
├── .github/
│   └── workflows/
│       └── call-deploy-book.yml    # GitHub Actions workflow for deployment
├── book/
│   ├── _config.yml                  # Main configuration file
│   ├── _toc.yml                     # Table of contents
│   ├── _static/
│   │   └── custom.css              # Custom styling
│   ├── figures/
│   │   └── README.md               # Instructions for logos
│   ├── chapters/
│   │   ├── 01_introduction.md
│   │   ├── 02_mathematical_foundations.md
│   │   ├── 03_classical_ciphers.md
│   │   ├── 04_cryptanalysis_basics.md
│   │   ├── 05_symmetric_encryption.md
│   │   ├── 06_block_ciphers.md
│   │   ├── 07_public_key_cryptography.md
│   │   ├── 08_rsa.md
│   │   ├── 09_elliptic_curves.md
│   │   ├── 10_hash_functions.md
│   │   ├── 11_digital_signatures.md
│   │   ├── 12_key_exchange.md
│   │   └── 13_practical_applications.ipynb  # Interactive notebook
│   ├── intro.md                    # Welcome page
│   ├── references.md               # Bibliography page
│   ├── references.bib              # BibTeX references
│   └── credits.md                  # Credits and license
├── .gitignore                      # Git ignore file
├── LICENSE                         # CC BY 4.0 License
├── README.md                       # Main documentation
├── CONTRIBUTING.md                 # Contribution guidelines
├── QUICKSTART.md                   # Quick start guide
└── requirements.txt                # Python dependencies
```

## 🎯 Key Features

### Interactive Elements
- **Live Code Execution**: Run Python code directly in browser
- **Mathematical Rendering**: Beautiful LaTeX equations
- **Collapsible Sections**: Hide/show content
- **Dark/Light Mode**: User preference support

### Content Organization

#### Part 1: Getting Started
- Introduction to cryptography concepts
- Mathematical foundations (number theory, modular arithmetic)

#### Part 2: Classical Cryptography
- Historical ciphers and their analysis
- Frequency analysis and cryptanalysis techniques

#### Part 3: Modern Cryptography
- Symmetric encryption (AES, DES, modes of operation)
- Public key cryptography (RSA, Diffie-Hellman)
- Elliptic curve cryptography

#### Part 4: Applications
- Hash functions
- Digital signatures
- Key exchange protocols
- **Interactive Python implementations**

## 🛠️ Technologies Used

- **Jupyter Book**: Main framework
- **MyST Markdown**: Extended Markdown syntax
- **Sphinx**: Documentation generator
- **TeachBooks Extensions**: Educational features
- **Thebe**: Live code execution
- **GitHub Pages**: Hosting
- **GitHub Actions**: Automated deployment

## 📚 Extensions Included

1. **sphinx-proof**: Theorems, definitions, algorithms
2. **sphinx-exercise**: Exercise blocks
3. **sphinx-togglebutton**: Collapsible content
4. **sphinx-design**: Cards, tabs, grids
5. **sphinx-thebe**: Live code execution
6. **sphinxcontrib-bibtex**: Bibliography management
7. **sphinx-named-colors**: Colored admonitions
8. **sphinx-image-inverter**: Dark mode images
9. **teachbooks-sphinx-tippy**: Tooltips

## ⚙️ Configuration Highlights

### _config.yml
- **Title**: Introduction to Cryptography
- **Execute notebooks**: off (for performance)
- **Live code**: Enabled via Thebe
- **Math**: KaTeX for fast rendering
- **Theme**: sphinx_book_theme with dark mode

### _toc.yml
- Organized into 4 parts
- 13 chapters total
- Progressive difficulty

## 🎨 Customization Options

### Branding
1. Update author in `_config.yml`
2. Add logos to `book/figures/`
3. Modify colors in `custom.css`
4. Update repository URL

### Content
1. Edit existing chapters
2. Add new chapters to `chapters/`
3. Update `_toc.yml` to include new content
4. Add references to `references.bib`

### Features
1. Enable/disable extensions in `_config.yml`
2. Adjust theme settings
3. Configure Thebe settings
4. Modify launch buttons

## 🚀 Deployment

### Automatic Deployment
- Triggers on push to `main` branch
- GitHub Actions builds the book
- Deploys to GitHub Pages
- Usually takes 2-5 minutes

### Manual Build
```bash
# Install dependencies
pip install -r requirements.txt

# Build the book
jupyter-book build book

# View locally
open book/_build/html/index.html
```

## 📖 Writing Guidelines

### Markdown Files
```markdown
# Chapter Title

## Section

Content with **bold** and *italic*.

### Math
$E = mc^2$

$$
\int_a^b f(x)dx
$$

### Code
` ``python
print("Hello, Crypto!")
` ``
```

### Admonitions
```markdown
` ```{note}
This is a note
` ```

` ```{warning}
This is a warning
` ```

` ```{tip}
This is a tip
` ```
```

### Cross-References
```markdown
See [Chapter 1](chapters/01_introduction.md)

Refer to {ref}`section-label`
```

### Citations
```markdown
As shown in {cite}`rivest1978method`
```

## 🔧 Maintenance

### Regular Updates
1. Keep dependencies updated
2. Review and merge contributions
3. Fix broken links
4. Update content accuracy

### Performance
- Optimize images (compress, resize)
- Limit notebook cell outputs
- Use lazy loading where possible

### Accessibility
- Add alt text to images
- Use semantic HTML
- Ensure color contrast
- Test with screen readers

## 📊 Analytics (Optional)

Add Google Analytics in `_config.yml`:
```yaml
html:
  analytics:
    google_analytics_id: "G-XXXXXXXXXX"
```

## 🔒 Security

### Best Practices
- Never commit sensitive data
- Use environment variables for secrets
- Keep dependencies updated
- Review contributed code

### Cryptographic Examples
- Use standard libraries
- Include security warnings
- Emphasize best practices
- Note when code is educational only

## 🎓 Educational Design

### Learning Objectives
Each chapter should:
- State clear objectives
- Build on previous knowledge
- Include examples
- Provide exercises

### Progressive Complexity
1. **Chapters 1-4**: Foundations
2. **Chapters 5-9**: Core concepts
3. **Chapters 10-13**: Applications

### Assessment
- Inline exercises
- End-of-chapter problems
- Interactive coding challenges
- Self-check questions

## 🌐 Internationalization (Future)

The book structure supports:
- Multiple languages
- Regional examples
- Localized resources

## 📝 TODO List

Potential enhancements:
- [ ] Add video tutorials
- [ ] Create solution manual
- [ ] Develop quiz system
- [ ] Add more visualizations
- [ ] Expand exercise sets
- [ ] Create study guides
- [ ] Add supplementary materials

## 💬 Community

### Getting Help
- GitHub Issues
- TeachBooks community
- Jupyter Book forums

### Sharing
- Social media
- Academic networks
- Course websites
- Conference presentations

## 📜 License

CC BY 4.0 - Share and adapt with attribution

---

**Version**: 1.0.0
**Last Updated**: January 2026
**Status**: Production Ready

For questions or support, please open an issue on GitHub.
