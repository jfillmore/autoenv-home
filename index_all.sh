#!/bin/sh

fail() {
    echo "! $@" >&2
    exit 1
}

base_dir=$(cd $(dirname "$0") && pwd -P)
auto_env_opts="--verbose"

cd "$base_dir" || fail "Failed to change dir to '$base_dir'."
find -maxdepth 1 -type d -not -name \.\* -print0 \
    | xargs -0 auto_env/bin/auto_env.sh -i $auto_env_opts \
    || fail "Failed to generate index files."
