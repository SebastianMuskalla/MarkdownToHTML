MarkdownToHTML
==============


This is a bash script for converting markdown files into standalone fully styled HTML files using the GitHub API (<https://docs.github.com/en/rest/markdown>).

**MarkdownToHTML is available as the docker container `smuskalla/markdown-to-html` on Docker Hub: <https://hub.docker.com/r/smuskalla/markdown-to-html>.**


TL;DR
-----

Assume you want to convert the markdown file `input.md` into `output.html`.

### Run using docker:

```sh
# Option 1: Using standard input/output
cat input.md | docker run -i smuskalla/markdown-to-html --stdin --stdout > output.html
# Option 2: Mounting the current directory as a volume
docker run -v "$(pwd):/files" smuskalla/markdown-to-html /files/input.md /files/output.html
```

### Run natively:

Clone this repository and check that `bash`, `jq`, and `curl` are available
(On Ubuntu/Debian: `sudo apt install jq curl`). Then run

```sh
./markdownToHTML.sh input.md output.html
```


Details
-------

GitHub displays markdowns files on its web interface in a nice way (the README file you are currently looking at, for example).
GitHub even offers an API (<https://docs.github.com/en/rest/markdown>) for converting markdown into HTML.
However, the resulting files lack styling and parts of the HTML structure.
MarkdownToHTML helps you remedy these issues.

### Usage:

```sh
./markdownToHTML.sh INPUTFILE OUTPUTFILE
```
where
* `INPUTFILE` is the path to an input markdown (`.md`) file or `--stdin`.
   In the latter case, the script will read from the standard input.
* `OUTPUTFULE` is the path to an output file or `--stdout`.
  In the latter case, the script will write to the standard output.

**Note:** When using the script via `docker run` in combination with `--stdin`, it is important to pass the `-i` (`--interactive`) flag.

### Steps:

1. We convert the input markdown file into the body of the HTML file using the aforementioned GitHub API.
2. We add some HTML structure (`<html><head>...</head><body>...</body></html>`)
   using the files from the `templates` folder.
3. We add a `<title>` tag that sets the browser window title when viewing the HTML file.
   The title can be specified using the `TITLE` environment variable (see below).
   If this variable is not set, the title will be extracted from the filename (title = filename without path and extension).
4. We add some CSS styling.
   We use
   - [normalize.css](css/normalize.css) (from <https://necolas.github.io/normalize.css>) to ensure that the generated file looks the same in all browsers.
   - [github-markdown-css](css/github-markdown.css) (from <https://github.com/sindresorhus/github-markdown-css>) to replicate the look of markdown files in the GitHub web interface.
   - We wrap the body in `<article class="markdown-body">` and add some [styling](css/style.css) from for the `markdown-body` class, which is needed for github-markdown-css to work.

   By default, we will paste the files from the `css/` folder into the HTML code (using `<style>...</style>`). This behavior can be configured using the `CSS_FILES` and `LINK_CSS` environment variables (see below).

5. We get rid of all occurrences of `user-content-` in the HTML file in order to make sure that links to headings inside the file work.

   **Why?** A heading `My nice Heading` in the markdown file will be converted to an `<a>` tag with the id `user-content-my-nice-heading` by the GitHub API.
   In order to make links to headings like `#my-nice-heading` work, GitHub uses JavaScript on its site to remap `#my-nice-heading` to `#user-content-my-nice-heading`.
   In order to avoid having to embed such JavaScript code, we replace all occurrences of `<a id="user-content-` by `<a id="` in the HTML file.
   This behavior can be disabled using the `SKIP_REPLACEMENT` environment variable.


Environment variables
---------------------

The behavior of MarkdownToHTML can be changed using several environment variables.

### Setting environment variables when using docker

Use the `-e` flag to pass environment variables, e.g.
```sh
docker run \
    -v "$(pwd):/files" \
    -e TITLE="My Title" \
    smuskalla/markdown-to-html /files/input.md /files/output.html
```

### Setting environment variables using bash

Use the `export` command to set the environment variables before calling the script, e.g.
```sh
export TITLE="My Title"
./markdownToHTML.sh input.md output.html
```

### Environment variables

* **SKIP_REPLACEMENT**

  Default value: unset

  If this environment variable is set to true (`SKIP_REPLACEMENT=true`), MarkdownToHTML will **not** remove occurrences of `user-content-` in the HTML file as described above.
  Note that this means that links to headings (e.g. `#heading`) will not work.

* **TITLE**

  Default value: unset

  If this environment variable is set (e.g. `TITLE="My Title"`), the provided title will be used in the `<title>` tag of the HTML document.
  Otherwise, the title will be extracted from the filename, or omitted when reading from standard input.

* **LINK_CSS**

  Default value: unset

  By default, MarkdownToHTML will paste the contents of the CSS files into the HTML file.
  This leads to standalone HTML files, but also increases the size of each file by roughly 30 kilobytes, which is wasteful when multiple HTML files could share the same CSS file.

  If this environment variable is set to true (`LINK_CSS=true`), MarkdownToHTML will instead of pasting the CSS files just put a `<link>` tag for each CSS file.
  Note that this also means that the CSS files do not have to present when running MarkdownToHTML.

* **CSS_FILES**

  Default value: `css/github-markdown.css,css/normalize.css,css/style.css`

  A comma-separated list of CSS files that will be included in the HTML file.

  When LINK_CSS is unset (default behavior), MarkdownToHTML will paste these files into the output HTML file.
  This means that the files need to be present when running MarkdownToHTML.

  When LINK_CSS is set to true, MarkdownToHTML will simply emit a `<link>` tag for each file.
  The files do not need to present when running MarkdownToHTML.


Advanced usage
--------------

### Modifying the templates

In order to generate the HTML file, MarkdownToHTML uses three templates:

* [templates/head.html](templates/head.html) - Template for the beginning of the file (`<html><head>`).
* Then, the `<title>` tag and the CSS files (using `<style>` or `<link>`) will be embedded.
* [templates/center.html](templates/center.html) - Template for the end of the HTML header (`</head>`) and the beginning of the body (`<body>`).
* Then, the HTML code generated by the GitHub API will be inserted.
* [templates/foot.html](templates/foot.html) - Template for the end of the HTML file (`</body></html>`).

When running the script locally, these files can simply be modified.

When running MarkdownToHTML via docker, proceed as follows:
* Download this repository.
* Modify the `.html` files in the `template/` folder.
* Mount the `template/` folder to `/script/templates/`, e.g. run

``` sh
docker run \
    -v "$(pwd):/files" \
    -v "$(pwd)/templates/:/script/templates/" \
    smuskalla/markdown-to-html /files/input.md /files/output.html
```

### Modifying the CSS files

Assume you want to use `github-markdown-dark.css` instead of `github-markdown.css` from <https://github.com/sindresorhus/github-markdown-css>.
Additionally, you want to use your own CSS file `mystyle.css`.

When running locally, simply put these files into the `css/` folder and set the environment variable `CSS_FILES` accordingly, e.g.
```sh
export CSS_FILES="css/github-markdown-dark.css,css/mystyle.css"
./markdownToHTML.sh input.md output.html
```
(Note that if you use relative paths like `css/`, you have to make sure that you call `markdownToHTML.sh` from the directory that contains the `css/` folder.)

When running MarkdownToHTML via docker, proceed as follows:
* Download this repository.
* Modify the CSS files in the `css/` folder.
* Set the environment variable `CSS_FILES` accordingly and mount the `css/` folder to `/script/css/`, e.g. run

``` sh
docker run \
    -v "$(pwd):/files" \
    -v "$(pwd)/css/:/script/css/" \
    -e  CSS_FILES="css/github-markdown-dark.css,css/mystyle.css" \
    smuskalla/markdown-to-html /files/input.md /files/output.html
```

Note: If you use `LINK_FILES=true`, you can avoid having to mount the CSS files.

### FetchCSSFiles.sh

The provided script [fetchCSSFiles.sh](fetchCSSFiles.sh) can be used to update `normalize.css` and `github-markdown.css` to the newest version.


LICENSE
-------

Copyright 2022 Sebastian Muskalla

MarkdownToHTML is free and open-source software, licensed under the MIT License, see [LICENSE](LICENSE).

MarkdownToHTML comes with *normalize.css* (<https://necolas.github.io/normalize.css>), copyright Nicolas Gallagher and Jonathan Neal, licensed under the MIT License, see [css/normalize.css.LICENSE](css/normalize.css.LICENSE).

MarkdownToHTML comes with *github-markdown-css* (<https://github.com/sindresorhus/github-markdown-css>), copyright Sindre Sorhus, licensed under the MIT License, see [css/github-markdown-css.LICENSE](css/github-markdown-css.LICENSE).

MarkdownToHTML was inspired by jfroche's *docker-markdown* (<https://github.com/jfroche/docker-markdown>).
