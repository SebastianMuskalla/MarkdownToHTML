#!/bin/bash
set -eEuo pipefail
IFS=$'\n\t'

# set -x

# Fetch location of this script.
# This allows us to handle the case that the script is called from another location.
dir_name="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


#
# Arguments
#

# First argument should be either the path to a markdown file
#   that will be used as input
#   or '--stdin', in which case the script will read from the standard input.
#
# Second argument should be either the path to a file
#   to which the HTML output will be written,
#   or '--stdout', in which case the script will write to the standard output.
#

# check that we get exactly 2 arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: markdownToHTML.sh INPUTFILE OUTPUTFILE"
    echo "    INPUTFILE may be --stdin to read from the standard input"
    echo "    OUTPUTFILE may be --stdout to write to the standard output"
    exit 1
fi

using_stdin=false
if [ "${1,,}" == "--stdin" ]; # convert to lowercase
then
    using_stdin=true
    input_file=/dev/stdin
else
    input_file=${1}
fi

using_stdout=false
if [ "${2,,}" == "--stdout" ];  # convert to lowercase
then
    using_stdout=true
fi


#
# Processing environment variables
#

# This script uses the following environment variables.
#
# SKIP_REPLACEMENT: Whether to replace 'user-content-' in the HTML file.
#     Not set or set to "false" (default behavior):
#       ...
#     Set to "true":
#         Don't execute replacement.
#         (Links to headings will not work without JS magic.-)
#
# TITLE: The contents of the title tag in the HTML file.
#     Will be typically shown as the title of the browser window.
#     If not set (default), we will use the filename (without path and extension) as title.
#
# LINK_CSS: Whether to link to the CSS files or whether to paste them.
#     Not set or set to "false" (default):
#         Script will paste the contents of the CSS files into the output file.
#         CSS files DO need to be present when running this script.
#     Set to "true":
#         Script will emit a <link> tag.
#         CSS files do not need to be present when running this script.
#
# CSS_FILES: a comma-separated list of paths to css files.
#   Default value: "css/github-markdown.css,css/normalize.css,css/style.css"
#   Note that if LINK_CSS is not set (default behavior), the contents of these files will be pasted into the output file.
#   This in particular means that the files need to be present when running this script.
#   When using relative paths, this also means that the script needs to be called from the correct directory.
#


# set default value for CSS_FILES
if [ -z "${CSS_FILES+x}" ]
then
    if [ -z "${LINK_CSS+x}" ] || [ "$LINK_CSS" != "true" ];
    then
        # Using inline mode.
        # We prepend the directory path to make sure that the files can be found.
        CSS_FILES="$dir_name/css/normalize.css,$dir_name/css/github-markdown.css,$dir_name/css/style.css"
    else
        # Not using inline mode.
        # We simply use the relative path "css/"
        #   and hope that the user will put the CSS files there.
        CSS_FILES=css/github-markdown.css,css/normalize.css,css/style.css
    fi
fi


#
# Step 0: Acquire temporary file
#

temp_file=$(mktemp /tmp/styleincludes.template.html.XXXXXX)

# set up a trap that deltes the temp file when this script terminates
trap "rm -f $temp_file" 0 2 3 15


#
# Step 1: Head template
#

cat "$dir_name/templates/head.html" >> $temp_file


#
# Step 2: Title
#

# TITLE=testtitle

if [ -z "${TITLE+x}" ]
then
    # TITLE variable is not set.
    # If we are given a filename, we will use the filename as title.
    # If the input is given via STDIN, we omit the title.
    if [ "$using_stdin" != "true" ];
    then
        filename=$(basename -- "${1}") # get just the filename
        filename="${filename%.*}" # remove extension
        echo "<title>$filename</title>" >> $temp_file
    fi
else
    # TITLE is set, use it
    echo "<title>$TITLE</title>" >> $temp_file
fi


#
# Step 3: CSS files
#

# LINK_CSS=true

# process CSS_FILES as a comma separated list
oldIFS=$IFS
IFS=","
for style_file in ${CSS_FILES}
do
    style_file_without_path=$(basename -- "$style_file")

    # echo $style_file

    if [ -z "${LINK_CSS+x}" ] || [ "$LINK_CSS" != "true" ];
    then
        # Using inline mode.
        # Actually paste the contents of the css files into the output.
        echo "<!-- contents of $style_file_without_path -->" >> $temp_file
        echo "<style>" >> $temp_file
        cat "$style_file" >> $temp_file
        echo "</style>"  >> $temp_file
    else
        # Not using inline mode.
        # Simply emit a link tag.
        echo "<link rel="stylesheet" href=\"$style_file\">" >> $temp_file
    fi
done
IFS=$oldIFS


#
# Step 4: Center template
#

cat "$dir_name/templates/center.html" >> $temp_file


#
# Step 5: Markdown conversion using the GitHub API
#

jq --slurp --raw-input '{"text": "\(.)", "mode": "markdown"}' < "$input_file" |
    curl -s --data @- https://api.github.com/markdown >> $temp_file


#
# Step 6: Foot template
#

cat "$dir_name/templates/foot.html" >> $temp_file


#
# Step 7: Get rid of 'user-content-' (unless SKIP_REPLACEMENT has been specified)
#

# SKIP_REPLACEMENT=true

if [ -z "${SKIP_REPLACEMENT+x}" ] || [ "$SKIP_REPLACEMENT" != "true" ];
then
    sed -i 's/<a id="user-content-/<a id="/g' $temp_file
fi


#
# Step 8: Output
#

if [ "$using_stdout" == "true" ];
then
    cat $temp_file
else
    cp $temp_file ${2}
    echo "Succesfully written HTML to ${2}"
fi
