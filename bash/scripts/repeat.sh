#!/bin/bash -u

function repeat() {
    "$@"
    [ $? -eq 0 ] \
        && echo -e "\n\033[1;32m -- SUCCESS --\033[0m" \
        || echo -e "\n\033[1;31m -- FAIL: $? --\033[0m"
    read -n 1 -p '(press a key to repeat) ' || return 1
}

while true; do
    repeat "$@"
    echo -e "\n\n"
done
