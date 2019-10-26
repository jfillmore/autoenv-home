#!/bin/bash -u

fail() {
    echo "$@" >&2
    exit 1
}

split_pdf() {
    local file="$1"
    local dir="${file%%.pdf}"
    local page_count=$(gs -q -dNODISPLAY -c "($file) (r) file runpdfbegin pdfpagecount = quit") \
        || fail "Failed to get page count for $file"
    local i

    mkdir "$dir"
    for ((i=1; i<=$page_count; i++)); do
        gs -dBATCH -dNOPAUSE -dQUIET -dFirstPage=$i -dLastPage=$i -sDEVICE=pdfwrite -sOutputFile="$dir/page-$i.pdf" "$file" \
            || fail "Failed to fetch page $i from $file"
    done
    echo "Wrote $page_count pages to '$dir'"
}

while [ $# -gt 0 ]; do
    file="$1"; shift
    split_pdf "$file"
done
