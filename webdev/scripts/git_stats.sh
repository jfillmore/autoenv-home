#!/bin/sh -u

alias echo=/bin/echo

fail() {
    echo -e "$@"
    exit 1
}

blue_gr() {
    echo -ne "\033[0;36m$@\033[0;0m"
}

blue_lt() {
    echo -ne "\033[1;34m$@\033[0;0m"
}

blue() {
    echo -ne "\033[0;34m$@\033[0;0m"
}

blue_gr "=-=-= GIT STATUS =-=-=\n"
for dir in $@; do
    cd $dir || fail "Failed to cd to '$dir'."
    name=$(basename $(pwd -P))
    branch=$(git branch -v | grep -v '^ ' | sed 's/^* \+//')
    blue_lt "$name: "
    blue "$branch"
    echo
    git status --porcelain
done
