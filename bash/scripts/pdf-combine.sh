#!/bin/bash -u

fail() {
    echo "$@" >&2
    exit 1
}

# need at least the output file and two input files
[ $# -ge 3 ] || {
    echo "Usage: $0 OUTPUT_PDF_FILE SRC_FILE1 SRC_FILE2 [...]"
    exit 1
}

output_file="$1"; shift
gs -dBATCH -dNOPAUSE -dQUIET -sDEVICE=pdfwrite -sOutputFile="$output_file" "$@" \
    || fail "failed to create $output_file from $@"
