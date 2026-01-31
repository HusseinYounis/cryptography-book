(credits)=
# Credits and License

You can refer to this book as:

> Introduction to Cryptography Course Team (2026) _Introduction to Cryptography: An Interactive Textbook_. https://yourusername.github.io/cryptography-book/. Source files at https://github.com/yourusername/cryptography-book. CC BY 4.0.

You can refer to individual chapters or pages within this book as:

> `<Title of Chapter or Page>`. In Introduction to Cryptography Course Team (2026) _Introduction to Cryptography: An Interactive Textbook_. `<url to specific page on book website>`. Source files at `<link to specific commit / file in github repo>`. CC BY 4.0.

We anticipate that the content of this book will change significantly as cryptography evolves. Therefore, we recommend using the source code directly with the citation above that refers to the GitHub repository and lists the date and name of the file.

## How the book is made

This website is written in Markdown and Jupyter Notebook files, which are converted to HTML using tools from [TeachBooks](https://teachbooks.io/). The files are stored on a [public GitHub repository](https://github.com/yourusername/cryptography-book). The website can be viewed at https://yourusername.github.io/cryptography-book/.

To recreate the website you have two options (more information in the [TeachBooks manual](https://teachbooks.io/manual/)):

- In the GitHub interface: fork this repository, enable GitHub Pages from the source GitHub actions (Settings - Code and automation - Pages - Build and deployment - Source - GitHub Actions), enable workflows (Actions - I understand my workflows, go ahead and enable them) and run the call-deploy-book workflow (Actions - call-deploy-book - Run workflow - Run workflow). The website is released on the URL as shown on the workflow summary when the workflow has finished (Actions - call-deploy-book - call-deploy-book - Summary).
- On your own computer: clone this repository, install the required packages (`pip install -r requirements.txt`) and build the book (`jupyter-book build book`). The website is stored locally in `book/_build/html/index.html`.

## License

This work is licensed under a [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).

You are free to:
- **Share** — copy and redistribute the material in any medium or format
- **Adapt** — remix, transform, and build upon the material for any purpose, even commercially

Under the following terms:
- **Attribution** — You must give appropriate credit, provide a link to the license, and indicate if changes were made.

## About the Authors

This interactive textbook was developed by cryptography educators and researchers passionate about making cryptographic concepts accessible and engaging through modern teaching technologies.

## Acknowledgments

We would like to thank:
- The [TeachBooks](https://teachbooks.io/) team for providing the platform
- The open-source community for cryptographic libraries and tools
- Our students for feedback and suggestions
- The cryptography research community for foundational work {cite}`diffie1976new,rivest1978method`

## Contributing

If you find errors or have suggestions for improvements, please:
- Open an issue on our [GitHub repository](https://github.com/yourusername/cryptography-book/issues)
- Submit a pull request with corrections or enhancements
- Contact us through the repository

Your contributions help make this resource better for everyone!
