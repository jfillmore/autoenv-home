#!/bin/sh

fail() {
    echo "! $@" >&2
    exit 1
}

base_dir=$(cd $(dirname "$0") && pwd -P)

cd "$base_dir" || fail "Failed to change dir to '$base_dir'."

find . -maxdepth 1 -type d -not -name '.*' | while read dir; do
    autoenv.sh sync-index "$dir" \
        || fail "Failed to generate index files for $dir."
done
