#!/bin/bash -u

BASE_DIR=$(cd $(dirname "$0") && pwd -P)
SCRIPT_NAME=$(basename "$0")

EDITOR=${EDITOR:-vim}
EDITOR_ARGS=${EDITOR_ARGS:-}
[ -z "$EDITOR_ARGS" ] && [ "$EDITOR" = "vim" ] && EDITOR_ARGS="-O"


# functions
# ==========================================

usage() {
    cat <<EOI
Usage: $SCRIPT_NAME [ARGUMENTS] ACTION [ACTION_ARGS]

Given two directories containing the same repo, but on different branches, helps
walk through reviewing the differences between the oldest common parent, focusing
on recent per-file changes and diffs.

ARGUMENTS:

    # === Required ===

    # Defaults to PWD if not specified.
    -r|--repo PATH                Repo (or nested) dir, on branch to review.
    # Target commit region to review
    -T|--tail-hash HASH           Initial point of departure for target
    -H|--head-hash HASH           Where we intend to merge up to in source (HEAD usually)

    # === Optional ===

    # Helpers
    -m|--map src_path:dst_path    Reflect a path rename within current branch

    # Generic args
    -h|--help                     This information
    -v|--verbose                  Log debugging information; repeat for "set -x"

ACTIONS:

    # Summary information
    list-commits [GIT LOG ARGS]   List commits between tail and head hashes
    list-files [GIT DIFF ARGS]    List files changed between tail and head hashes
    compare [TARGET_BRANCH]   Show useful hashes for target branch

    # Walk commands step through each file changed (unless filtered to one).
    # FILE paths are relative to the repo root and must be in our list of files
    # changed.
    # --
    # Review changes between tail and head hashes in source
    walk-hist [FILE]
    # Diff files between source's head and target
    walk-diff [FILE]
    # Edit files in target and source together
    walk-edit [FILE]

EXAMPLES:

    # Ensure all refs will be found w/ the latest data.
    $ git fetch

    # Be sure you're on the branch you want to review.
    $ git checkout some-tricky-branch

    # Edit a specific file found within our change set between two commits. It
    # reflects that the folder "MyPackageV1" was moved to "src/MyPackage" in the
    # current branch.
    $ git-review.sh -vv \\
        -m MyPackageV1:src/MyPackage \\
        -r ./MyPackageV1 \\
        -T a7a66b6d429b27b6eb62648781ed53b1aa26f61f \\
        -H HEAD \\
        walk-edit \\
        MyPackageV1/MyFile.ext
EOI
}


# Fail and quit w/ the error given
fail() {
    echo "${1-$SCRIPT_NAME command failed}" >&2
    exit ${2:-1}
}

# Print a comment
rem() {
    local force="${2:-0}"
    [ "$VERBOSE" -eq 0 ] && [ $force -eq 0 ] && return
    echo -e "+ [\033[1;37;40m$1\033[0;0m]" >&2
}

# Run (maybe log) a key command
cmd() {
    # no need to repeat our output w/ "set -x"
    if [ $VERBOSE -eq 1 ]; then
        echo -e "\033[0;33;40m# $(printf "'%s' " "$@")\033[0;0m" >&2
    fi
    "$@"
}

# Quick y/n prompt w/ an optional message
prompt_yn() {
    local msg="${1:-continue?}"
    local yes="${2:-y}"
    local no="${3:-n}"
    local resp=''
    while [ "$resp" != "$yes" -a "$resp" != "$no" ]; do
        read -n 1 -p "$msg ($yes|$no) > " resp
        echo >&2
    done
    [ "$resp" = "$yes" ] && return 0 || return 1
}


# script-specific functions
# ==========================================

# Apply path mappings and echo final target path
apply_path_maps() {
    local path="$1"
    local reverse="${2:-0}"

    # Tricky now! we need to apply all our  mappings. We assume absolute
    # paths to help with matching.
    local tgt="/$path"
    local map src_map dst_map
    if [ ${#map_paths[@]} -gt 0 ]; then
        for map in "${map_paths[@]}"; do
            # e.g. "foo:src/foo" indicates that "foo" was moved inside "src"
            src_map="/$(echo "${map%%:*}" | sed 's|/$||')/"  #.g. foo, foo/ => /foo/
            dst_map="/$(echo "${map##*:}" | sed 's|/$||')/"
            if [ $reverse -eq 1 ]; then
                tgt="${tgt//$dst_map/$src_map}"
            else
                tgt="${tgt//$src_map/$dst_map}"
            fi
        done
    fi

    # Clean up our leading slash
    echo "$tgt" | sed 's|^/||'
}


# collect args
# ==========================================

VERBOSE=0

repo_dir="$PWD"
repo_path=
head_hash=  # will contain full, validated path
tail_hash=  # will contain full, validated path
action=
action_args=()
map_paths=()

while [ $# -gt 0 ]; do
    case "$1" in
        --verbose|-v*)
            [ "${1:0:2}" = '--' ] \
                && VERBOSE=$((VERBOSE + 1)) \
                || VERBOSE=$((VERBOSE + ${#1} - 1))
            ;;
        --help|-h)
            usage
            exit
            ;;
        -r|--repo)
            [ $# -ge 2 ] || fail "Missing arg to --repo|-r"
            [ -d "$2" ] || fail "Target repo path '$2' does not exist"
            [ -n "$repo_dir" ] && fail "Only one repo path allowed"
            repo_dir="$(cd "$2" && git rev-parse --show-toplevel)" \
                || fail "Could not get git repo path"
            repo_path="$(cd "$2" && pwd -P)" \
                || fail "Could not get full path"
            # Trim shared prefix to just get the subdir
            repo_path="${repo_path#$repo_dir}"
            shift
            ;;
        -T|--tail-hash)
            [ $# -ge 2 ] || fail "Missing arg to --tail-hash|-T"
            [ -n "$tail_hash" ] && fail "Only one tail hash allowed"
            tail_hash="$2"
            shift
            ;;
        -H|--head-hash)
            [ $# -ge 2 ] || fail "Missing arg to --head-hash|-H"
            [ -n "$head_hash" ] && fail "Only one head hash allowed"
            head_hash="$2"
            shift
            ;;
        -m|--map)
            [ $# -ge 2 ] || fail "Missing arg to --map|-m"
            map_paths+=("$2")
            shift
            ;;
        *)
            [ -z "$action" ] && action="$1" || action_args+=("$1")
            ;;
    esac
    shift
done

[ $VERBOSE -ge 2 ] && set -x


# prep & error checking
# ==========================================

# Required args
[ -z "$repo_dir" ] && fail "No repo specified via -r|--repo"
[ -z "$tail_hash" ] && fail "No tail hash specified via -T|--tail-hash"
[ -z "$head_hash" ] && fail "No head hash specified via -H|--head-hash"
[ -z "$action" ] && fail "No action specified"
[ -z "$repo_path" ] && repo_path=.

# Verify args
cmd cd "$repo_path" || fail "Could not cd to repo"
git rev-parse --verify "$tail_hash" >/dev/null \
    || fail "Invalid tail hash in repo; 'git fetch' maybe?"
git rev-parse --verify "$head_hash" >/dev/null \
    || fail "Invalid head hash in repo; 'git fetch' maybe?"


# script body
# ==========================================


if [ "$action" = 'list-commits' ]; then
    tgt_path="$(apply_path_maps "$repo_path" 1)"
    git_args=("$tail_hash..$head_hash" -- "$tgt_path")
    [ ${#action_args[@]} -gt 0 ] && git_args+=("${action_args[@]}")
    cmd git log "${git_args[@]}" || fail "git log failed"

elif [ "$action" = 'list-files' ]; then
    tgt_path="$(apply_path_maps "$repo_path" 1)"
    git_args=("--name-only" "$tail_hash..$head_hash" -- "$tgt_path")
    [ ${#action_args[@]} -gt 0 ] && git_args+=("${action_args[@]}")
    cmd git diff "${git_args[@]}" || fail "git diff failed"

elif [ "$action" = 'compare' ]; then
    cur_branch="$(git rev-parse --abbrev-ref HEAD)" \
        || fail "Failed to get branch name"
    target_branch=
    [ ${#action_args[@]} -ne 1 ] && fail "Expected one argument for compare"
    [ ${#action_args[@]} -ge 1 ] && target_branch="${action_args[0]}"

    rem "=== Last commit merged from $target_branch: ===" 1
    last_merged_hash="$(cmd git merge-base "$cur_branch" "$target_branch")" \
        || fail "Could not get merge base hash"
    cmd git log -1 "$last_merged_hash" || fail "Could not get merge base info"
    echo

    rem "=== Last commit in $target_branch: ===" 1
    last_hash="$(cmd git rev-parse "$target_branch")" \
        || fail "Could not get target branch info"
    cmd git log -1 "$last_hash" || fail "Could not get target branch info"
    echo

    rem "=== Difference between $target_branch and --head-hash"
    cmd git diff --stat "$last_hash..$head_hash" || fail "Could not get diff info"
    echo

    rem "=== Difference between --tail-hash and --head-hash"
    cmd git diff --stat "$tail_hash..$head_hash" || fail "Could not get diff info"
    echo

    rem "=== Useful hashes ==="
    cat <<EOI
tail_hash=$last_merged_hash  # last commit merged from $target_branch
head_hash=$last_hash  # last commit in $target_branch
EOI

elif [ "$action" = 'walk-hist' ]; then
    only_path=
    [ ${#action_args[@]} -gt 1 ] && fail "Too many arguments for walk-hist"
    [ ${#action_args[@]} -ge 1 ] && only_path="${action_args[0]}"

    # For each file, show what was changed
    tgt_path="$(apply_path_maps "$repo_path" 1)"
    cmd git diff --name-only "$tail_hash..$head_hash" -- "$tgt_path" \
        | while read -r path; do
            [ -n "$only_path" ] && [ "$path" != "$only_path" ] && continue
            rem "Source file: $path"
            cmd git diff \
                --color=always \
                $tail_hash..$head_hash -- "$path" \
                | less -RK \
                || break
        done

elif [ "$action" = 'walk-diff' ]; then
    only_path=
    [ ${#action_args[@]} -gt 1 ] && fail "Too many arguments for walk-log"
    [ ${#action_args[@]} -ge 1 ] && only_path="${action_args[0]}"

    # For each file, diff source and target versions between repos
    tgt_path="$(apply_path_maps "$repo_path" 1)"
    cmd git diff --name-only "$tail_hash..$head_hash" -- "$tgt_path" \
        | while read -r path; do
            [ -n "$only_path" ] && [ "$path" != "$only_path" ] && continue
            {
                tgt_path="$(apply_path_maps "$path")"
                echo "Source: git show $head_hash:$path"
                echo "Target: $repo_dir/$tgt_path"
                # Snag source file via git show to get right version w/ hash
                cmd git show "$head_hash:$path" \
                    | cmd diff -b -u --color=always \
                    - \
                    "$repo_dir/$tgt_path"
            } | less -RK || break
        done

elif [ "$action" = 'walk-edit' ]; then
    only_path=
    [ ${#action_args[@]} -gt 1 ] && fail "Too many arguments for walk-edit"
    [ ${#action_args[@]} -ge 1 ] && only_path="${action_args[0]}"

    # For each file, edit source and target versions together

    # We don't want to hijack stdin (e.g. maybe it's vim and there is a prompt).
    # We'll assume no newlines, but we need to handle spaces in paths.
    tgt_path="$(apply_path_maps "$repo_path" 1)"
    IFS=$'\n' path_list=($(cmd git diff --name-only "$tail_hash..$head_hash" -- "$tgt_path"))
    for path in "${path_list[@]}"; do
        [ -n "$only_path" ] && [ "$path" != "$only_path" ] && continue
        rem "File: $path"
        new_path="$(apply_path_maps "$path")"
        # Some editors are hard to quit w/ non-zero status (vim tip: use `:cq`).
        echo "Target: $repo_dir/$new_path"
        echo "Source: git show $head_hash:$path"
        echo
        prompt_yn \
            "Editing with $EDITOR. (c)ontinue or (q)uit?" \
            c q \
            || break
        # Best to have a similar name for any syntax highlighting hints.
        tmp_dir=$(mktemp -d) || fail "Could not create temp dir"
        tmp_file=$(mktemp "$tmp_dir/$(basename "$path")") \
            || fail "Could not create temp file"
        (
            {
                echo "# ================================"
                echo "# TEMPORARY FILE: $tmp_file"
                echo "# GENERATED VIA: git show $head_hash:$path"
                echo "# ================================"
            } > "$tmp_file"
            cmd git show "$head_hash:$path" >> "$tmp_file" \
                || fail "Could not get source file"
            quit=0
            cmd "$EDITOR" $EDITOR_ARGS "$repo_dir/$new_path" "$tmp_file" \
                || quit=1
            rm -rf "$tmp_dir" &>/dev/null
            [ $quit -eq 1 ] && exit 1
        ) || break
    done

else
    fail "Unknown action: $action"
fi
