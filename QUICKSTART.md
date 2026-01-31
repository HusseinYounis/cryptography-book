# Quick Start Guide

## Getting Your Interactive Cryptography Book Online

Follow these steps to publish your book on GitHub Pages:

### Step 1: Create a GitHub Repository

1. Go to [GitHub](https://github.com) and sign in
2. Click "New repository" (or use "Use this template" if available)
3. Name it `cryptography-book` (or any name you prefer)
4. Choose "Public" (required for free GitHub Pages)
5. Click "Create repository"

### Step 2: Upload Your Files

**Option A: Using GitHub Web Interface**
1. Click "uploading an existing file"
2. Drag and drop all files and folders
3. Commit the changes

**Option B: Using Git Command Line**
```bash
cd "d:\Cources\Introduction to Cryptography\interactiveBook"
git init
git add .
git commit -m "Initial commit: Interactive Cryptography Book"
git branch -M main
git remote add origin https://github.com/yourusername/cryptography-book.git
git push -u origin main
```

### Step 3: Enable GitHub Pages

1. Go to your repository on GitHub
2. Click "Settings"
3. Scroll to "Pages" in the left sidebar
4. Under "Build and deployment":
   - Source: Select "GitHub Actions"
5. Click "Save"

### Step 4: Enable Workflows

1. Go to the "Actions" tab
2. Click "I understand my workflows, go ahead and enable them"
3. The workflow should start automatically

### Step 5: Wait for Build

1. Go to "Actions" tab
2. Click on the running workflow
3. Wait for it to complete (usually 2-5 minutes)
4. Green checkmark means success!

### Step 6: View Your Book

Your book will be available at:
```
https://yourusername.github.io/cryptography-book/
```

(Replace `yourusername` with your actual GitHub username)

## Updating Your Book

Every time you push changes to GitHub:
1. The workflow runs automatically
2. Your book rebuilds
3. Changes appear on the website

To make changes:
```bash
# Edit your files
git add .
git commit -m "Describe your changes"
git push
```

## Local Development

To preview changes before publishing:

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Build the book:
```bash
jupyter-book build book
```

3. Open `book/_build/html/index.html` in your browser

## Troubleshooting

### Build Fails
- Check the Actions tab for error messages
- Ensure all required files are present
- Verify `_config.yml` syntax

### Pages Not Showing
- Confirm GitHub Pages is enabled
- Check that the workflow completed successfully
- Wait a few minutes for DNS propagation

### Code Cells Not Working
- Ensure `sphinx-thebe` is in requirements.txt
- Check that `thebe: true` is in `_config.yml`
- Verify notebook cells are properly formatted

## Next Steps

1. **Customize**: Update author names, repository URLs
2. **Add Content**: Expand chapters with your material
3. **Add Images**: Place logo and favicon in `book/figures/`
4. **Share**: Give the link to your students!

## Support

- [TeachBooks Manual](https://teachbooks.io/manual/)
- [Jupyter Book Documentation](https://jupyterbook.org/)
- [GitHub Pages Docs](https://docs.github.com/en/pages)

## Tips

💡 Commit often with descriptive messages
💡 Test locally before pushing
💡 Keep backup copies of your work
💡 Use issues to track TODOs

Happy teaching! 📚✨
