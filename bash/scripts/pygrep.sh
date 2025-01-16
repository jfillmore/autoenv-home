#!/bin/bash -u

BASE_DIR=$(cd $(dirname "$0") && pwd -P)
SCRIPT_NAME=$(basename "$0")


fail() {
    echo "${1-$SCRIPT_NAME command failed}" >&2
    exit ${2:-1}
}

cd "$BASE_DIR" || fail


[ $# -ge 1 ] || fail "Usage: $SCRIPT_NAME QUERY [GREP ARGS]"
query="$1"; shift

grep \
    -R \
    --include='*.py' \
    "$query" \
    ./ \
    "$@"
