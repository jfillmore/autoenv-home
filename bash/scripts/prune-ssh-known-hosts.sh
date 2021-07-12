#!/bin/bash -u

BASE_DIR=$(cd $(dirname "$0") && pwd -P)
SCRIPT_NAME=$(basename "$0")

DRYRUN=0
VERBOSE=0
TMP_FILE="/tmp/.$SCRIPT_NAME.$$"


# functions
# ==========================================

usage() {
    cat <<EOI
Usage: $SCRIPT_NAME PREFIX_STR [PREFIX_STR]

Prune host fingerprints from \$HOME/.ssh/known-hosts based on prefix strings.

ARGUMENTS:

    -d|--dry-run          Only print the changes that would have been made
    -h|--help             This information
    -r|--refresh          For each fingerprint, refresh the fingerprint instead
    -v|--verbose          Verbose debugging info

EXAMPLE:

    \$ $SCRIPT_NAME 127.0.0 localhost
EOI
}


# Fail and quit w/ the error given
fail() {
    echo "${1-$SCRIPT_NAME command failed}" >&2
    exit ${2:-1}
}

cleanup() {
    [ -f "$TMP_FILE" ] && rm "$TMP_FILE" &>/dev/null
}

# Command runner that can print a quoted version out first; skips execution w/
# DRYRUN=1
cmd() {
    [ $DRYRUN -eq 1 -o $VERBOSE -eq 1 ] \
        && echo -e "\033[0;33;40m# $(printf "'%s' " "$@")\033[0;0m" >&2
    if [ $DRYRUN -eq 0 ]; then
        "$@"
    fi
}


# collect args
# ==========================================

to_prune=";"  # poor man ';'.join(...); we'll skip this char
refresh=0

while [ $# -gt 0 ]; do
    arg="$1"
    shift
    case "$arg" in
        --help|-h)
            usage
            exit
            ;;
        --dry-run|-d)
            DRYRUN=1
            ;;
        --refresh|-r)
            refresh=1
            ;;
        --verbose|-v)
            VERBOSE=1
            ;;
        *)
            # sed expressions
            to_prune="$to_prune;/^${arg//./\\.}/d"
            ;;
    esac
done


# prep & error checking
# ==========================================
[ ${#to_prune} -eq 1 ] && {
    usage
    fail "No host names/ip prefixes given to prune"
}
[ -f ~/.ssh/known_hosts ] || fail "$HOME/.ssh/known_hosts does not exist"


# script body
# ==========================================
to_prune="${to_prune#;}"

trap cleanup EXIT
sed "${to_prune[*]}" < ~/.ssh/known_hosts > "$TMP_FILE" || {
    rm "$TMP_FILE" &>/dev/null
    fail "Failed to create '$TMP_FILE' with pruned hosts"
}
diff=$(diff ~/.ssh/known_hosts "$TMP_FILE")
echo "$diff" >&2

cmd mv "$TMP_FILE" ~/.ssh/known_hosts || fail
cmd chmod 644 ~/.ssh/known_hosts || fail

[ $refresh -eq 0 ] && exit 0

echo "$diff" \
    | awk '$1 == "<" {print $2}' \
    | while read addr; do
    fingerprint=$(ssh-keyscan "$addr" 2>/dev/null) || {
        echo -e "\033[1;31mFailed to refresh key for "$addr"\033[0m"
        continue
    }
    if [ $DRYRUN -eq 0 ]; then
        echo "$fingerprint" >> ~/.ssh/known_hosts \
            || fail "Failed to add '$fingerprint' to ~/.ssh/known_hosts"
    fi
done
