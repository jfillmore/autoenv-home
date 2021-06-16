#!/bin/bash -u

BASE_DIR=$(cd $(dirname "$0") && pwd -P)
SCRIPT_NAME=$(basename "$0")


# functions
# ==========================================

usage() {
    cat <<EOI
Usage: $SCRIPT_NAME [ARGS] DIR|FILE

ARGUMENTS:

    SCAN_DIR              Directory to scan (recursively); default=PWD

    -g|--grep-only        Skip 2to3 checks
    -F|--failfast         Exit as soon as one file is identified to need changes
    -f|--fixer FIXER      Base fixer to use (default: all)
    -h|--help             This information
    -q|--quiet            Do not print diffs
    -s|--search GLOB_STR  Pattern to search for when handling a dir (def: *.py)
    -v|--verbose          Print debugging information to stdout
    -w|--write            Automatically rewrite files with 2to3 changes
    -x|--exclude FIXER    Exclude a fixer (repeatable)

EXAMPLE:

    \$ $SCRIPT_NAME
EOI
}

fail() {
    echo "${1-$SCRIPT_NAME command failed}" >&2
    exit ${2:-1}
}

# Quick y/n prompt w/ an optional message
prompt_yn() {
    local msg="${1:-confinue?}"
    local resp=''
    while [ "$resp" != 'y' -a "$resp" != 'n' ]; do
        read -n 1 -p "$msg (y|n) > " resp
        echo >&2
    done
    [ "$resp" = 'y' ] && return 0 || return 1
}



# collect args
# ==========================================

VERBOSE=0
DRYRUN=0

write=0
grep_only=0
target_dir=
base_fixer=all
fail_fast=0
quiet=0
scan_args=(
    -f all
    -f idioms
    -f buffer
    -f ws_comma
)
search_args=()
search='*.py'

while [ $# -gt 0 ]; do
    arg="$1"
    shift
    case "$arg" in
        --fail-fast|-f)
            fail_fast=1
            ;;
        --verbose|-v)
            [ $VERBOSE -eq 1 ] && set -x
            VERBOSE=1
            ;;
        --grep|-g)
            grep_only=1
            ;;
        --help|-h)
            usage
            exit
            ;;
        --write|-w)
            write=1
            ;;
        --quiet|-q)
            quiet=1
            ;;
        --search|-s)
            [ $# -ge 1 ] || fail "Missing arg to --search|-s"
            search="$1"
            shift
            ;;
        --exclude|-x)
            [ $# -ge 1 ] || fail "Missing arg to --exclude|-x"
            scan_args+=(-x "$1")
            shift
            ;;
        *)
            [ ${#target_dir} -eq 0 ] || fail "Folder '$target_dir' already given"
            if [ -d "$arg" ]; then
                target_dir="$arg"
            elif [ -f "$arg" ]; then
                target_dir=$(dirname "$arg")
                search=$(basename "$arg")
                search_args+=(-maxdepth 1)
            else
                fail "Not a file/folder: $arg"
            fi
            ;;
    esac
done


# --- GREP Magic ---  (hopefully all redundant?)
# ------------------------------------------------------------------------------
warn_patterns=(
    # e.g. extra byte vs string handling that likely needs love
    '\wfrom base64\w'
    '\wfrom hashlib\w'
    # `long` is now just int, but sometimes direct conversion isn't wanted or
    # this is a word in a string
    '\Wlong\W'
    # string.maketrans issues; need str.maketrans or bytes.maketrans
    '\w+\.maketrans\W'
)
error_patterns=(
    # use codecs.encode instead probably
    '\.encode\(\s*.rot13.\s*\)'
    '\.encode\(\s*.base64.\s*\)'
    '\.decode\(\s*.rot13.\s*\)'
    '\.decode\(\s*.base64.\s*\)'
)


search_args+=(-name "$search")
find "$target_dir" "${search_args[@]}" | while read name; do
    # Do our sniffin'
    has_py2=0
    warnings="$(grep --color=always -n -E "($(IFS='|'; echo "${warn_patterns[*]}"))" "$name")"
    errors="$(grep --color=always -n -E "($(IFS='|'; echo "${error_patterns[*]}"))" "$name")"
    [ $grep_only -eq 1 ] && diff= || diff="$(2to3- "${scan_args[@]}" "$name" 2>/dev/null)"
    [ ${#warnings} -gt 0 ] && has_py2=1
    [ ${#errors} -gt 0 ] && has_py2=1
    [ ${#diff} -gt 0 ] && has_py2=1
    [ $has_py2 -eq 0 ] && continue

    # Print the results, if wanted
    [ $quiet -eq 0 ] && {
        echo -e "\033[1;37m---------------- $name ----------------\033[0m"
        [ ${#warnings} -gt 0 ] && {
            echo -e "\033[1;37;45m   --- Python2 Warnings ---   \033[0m" >&2
            echo "$warnings"
        }
        [ ${#errors} -gt 0 ] && {
            echo -e "\033[1;37;41m   ---  Python2 Errors  ---   \033[0m" >&2
            echo "$errors"
        }
        [ ${#diff} -gt 0 ] && {
            echo -e "\033[1;37;44m   ---   2to3 Changes   ---   \033[0m" >&2
            # add some color to make it easier to see
            echo "$diff" \
                | sed "/^--- /d" \
                | sed "/^\+\+\+ /d" \
                | sed -E "s/^@@ (.*)/[1;37m@@ \1[0;0m/" \
                | sed -E "s/^-(.*)/[1;31m-\1[0;0m/" \
                | sed -E "s/^\+(.*)/[1;32m+\1[0;0m/"
            # Sometimes 2to3 does goofy things we wanna call out!
            double_p=$(echo "$diff" | grep -E 'print\(\(')
            [ ${#double_p} -gt 0 ] \
                && echo -e "\n\033[1;33;41m WARNING: \033[1;33;40m unwanted double parenthesis from missed __future__.print_function?\033[0m\n$double_p" >&2
        }
        echo
        echo
    }
    [ $fail_fast -eq 1 ] && exit 1

    # Make automated changes, if wanted
    [ $write -eq 0 ] && continue
    [ ${#diff} -eq 0 ] && continue
    [ $grep_only -eq 1 ] && continue
    2to3- "${scan_args[@]}" "$name" 2>/dev/null | patch "$name"
    # ensure we have no newlines from __future__ removal up top
    sed '/./,$!d' "$name" > ".tmp.$$"; mv ".tmp.$$" "$name"

done || exit 1
