# Contributing to Introduction to Cryptography

Thank you for your interest in contributing! This document provides guidelines for contributing to this interactive textbook.

## Types of Contributions

We welcome various types of contributions:

### 📝 Content Improvements
- Fix typos or grammatical errors
- Clarify explanations
- Add examples or exercises
- Expand existing chapters

### 🐛 Bug Reports
- Report technical issues
- Identify broken links
- Note rendering problems

### 💡 New Features
- Suggest new chapters or topics
- Propose interactive demonstrations
- Recommend additional exercises

### 🎨 Design Enhancements
- Improve visual presentation
- Enhance accessibility
- Optimize mobile experience

## How to Contribute

### 1. Report Issues

Open an issue on GitHub describing:
- What you found
- Where it is located
- Suggested fix (if applicable)

### 2. Submit Pull Requests

1. Fork the repository
2. Create a new branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Test locally: `jupyter-book build book`
5. Commit: `git commit -m "Description of changes"`
6. Push: `git push origin feature/your-feature-name`
7. Open a pull request

### 3. Content Guidelines

When adding content:

#### Markdown Files (.md)
- Use clear headings
- Include examples
- Add exercises when appropriate
- Cite sources properly

#### Jupyter Notebooks (.ipynb)
- Include explanatory text
- Add comments in code
- Provide expected output
- Test all code cells

#### Mathematics
- Use LaTeX notation
- Define all symbols
- Provide intuitive explanations
- Include worked examples

### 4. Style Guide

**Writing Style:**
- Use clear, concise language
- Define technical terms
- Provide context and motivation
- Include practical examples

**Code Style:**
- Follow PEP 8 for Python
- Add docstrings to functions
- Include type hints where helpful
- Comment complex logic

**Citations:**
- Use BibTeX format in `references.bib`
- Cite using `{cite}` directive
- Prefer peer-reviewed sources

### 5. Testing

Before submitting:

```bash
# Install dependencies
pip install -r requirements.txt

# Build the book
jupyter-book build book

# Check for errors in the output
```

### 6. Review Process

1. Maintainers will review your PR
2. Feedback may be provided
3. Make requested changes
4. Once approved, changes will be merged

## Content Standards

### Accuracy
- Ensure technical accuracy
- Verify all code runs correctly
- Check mathematical notation

### Clarity
- Explain concepts clearly
- Use appropriate difficulty level
- Progress logically

### Completeness
- Include necessary background
- Provide sufficient examples
- Add exercises for practice

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Provide constructive feedback
- Focus on ideas, not individuals

## Questions?

- Open a discussion on GitHub
- Email the maintainers
- Join our community channels

## License

By contributing, you agree that your contributions will be licensed under the CC BY 4.0 License.

Thank you for helping make this resource better for everyone! 🎓
