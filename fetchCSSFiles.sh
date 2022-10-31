#!/bin/bash

dir_name="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# This script simply fetches
# - the most recent version of normalize.css
#     from https://github.com/necolas/normalize.css/
# - the most recet version of github-markdown.css
#     from https://github.com/sindresorhus/github-markdown-css

file="$dir_name/css/normalize.css"

if [ ! -f "$file" ]; then
    curl https://raw.githubusercontent.com/necolas/normalize.css/master/normalize.css > "$file"
fi

file="$dir_name/css/github-markdown.css"

if [ ! -f "$file" ]; then
    curl https://raw.githubusercontent.com/sindresorhus/github-markdown-css/gh-pages/github-markdown.css > "$file"
fi
