egrim() {
    [ $# -eq 2 ] || {
        echo "usage: egrim FILE_GLOB STRING"
        return 1
    }
    local file ext="$1"
    shift
    vim $(
        find ./ -name "$ext" | while read file; do
            grep -Hn "$@" $file \
                | awk -F: '{sub(/ /, "\\ "); print $1}' | sort -u
        done
    )
}
