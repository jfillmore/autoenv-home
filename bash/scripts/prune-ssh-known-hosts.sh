#!/bin/bash -u

BASE_DIR=$(cd $(dirname "$0") && pwd -P)
SCRIPT_NAME=$(basename "$0")


# functions
# ==========================================

usage() {
    cat <<EOI
Usage: $SCRIPT_NAME PREFIX_STR [PREFIX_STR]

Prune out entries from \$HOME/.ssh/known-hosts based on prefix strings.

ARGUMENTS:

    -h|--help             This information

EXAMPLE:

    \$ $SCRIPT_NAME 127.0.0 localhost
EOI
}


# Fail and quit w/ the error given
fail() {
    echo "${1-$SCRIPT_NAME command failed}" >&2
    exit ${2:-1}
}


# collect args
# ==========================================

to_prune=";"  # poor man ';'.join(...); we'll skip this char

while [ $# -gt 0 ]; do
    arg="$1"
    shift
    case "$arg" in
        --help|-h)
            usage
            exit
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

tmp_file="/tmp/$SCRIPT_NAME.$$"
sed "${to_prune[*]}" < ~/.ssh/known_hosts > "$tmp_file" || {
    rm "$tmp_file" &>/dev/null
    fail "Failed to create '$tmp_file' with pruned hosts"
}
diff ~/.ssh/known_hosts "$tmp_file"
mv "$tmp_file" ~/.ssh/known_hosts || fail
chmod 644 ~/.ssh/known_hosts || fail
