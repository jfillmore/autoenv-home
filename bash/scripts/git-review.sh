#!/bin/bash -u

BASE_DIR=$(cd $(dirname "$0") && pwd -P)
SCRIPT_NAME=$(basename "$0")

EDITOR=${EDITOR:-vim}
EDITOR_ARGS=${EDITOR_ARGS:-}
GIT_RENAME_THRESHOLD=${GIT_RENAME_THRESHOLD:-25}  # Default to more aggressive detection
[ -z "$EDITOR_ARGS" ] && {
    [ "$EDITOR" = "nvim" ] && EDITOR_ARGS="-O"
    [ "$EDITOR" = "vim" ] && EDITOR_ARGS="-O"
}


# DREAM Maybe a way for FILE paths to indicate they are relative to repo, not target?


# functions
# ==========================================

usage() {
    cat <<EOI
Usage: $SCRIPT_NAME [ARGUMENTS] ACTION [ACTION_ARGS]

Helps walk through reviewing the differences between two git refs (branches,
commits, etc), as reflected by the --head and --tail args.

Compares the current branch/state of a repo against a target branch (e.g. the
parent branch), which is presumed to have changed (frequently) a lot since.


ARGUMENTS:

    # === Repo and branch info ===
    # Defaults to PWD
    -r|--repo REPO_PATH           Path to (or within) git repo.
    # Guesses based parent using 'git reflog' when needed (e.g. for "compare")
    -b|--branch BRANCH            Target branch we're aiming to merge with

    # === Commit region ===
    # Defauts to target branch's latest commit
    -H|--head GIT_REF             Where we intend to merge to (e.g. origin/main)
    # Defaults to the last commit merged from the target branch
    -T|--tail GIT_REF             How far back to compare

    # === Helpers ===
    # Path mappings handle relocated files w/ changes over the rename threshold
    -m|--map src_path:dst_path    Reflect a path rename within current branch
    -f|--fuzzy                    Allow partial file name matches

    # === Generic args ===
    -h|--help                     This information
    -v|--verbose                  Debugging information; -vv or repeat = "set -x"

ACTIONS:

    # Summary information
    # ===
    - list-commits [GIT LOG ARGS]   List commits between tail and head
    - list-files [GIT DIFF ARGS]    List files changed between tail and head
    - compare                       Misc comparisons between us and target branch

    # Walk commands step through each file changed (unless filtered to one).
    #
    # FILE paths are ALWAYS relative to the target branch, so if they were moved
    # the --map option will help find the current location, when needed. Only
    # matches paths within the list of files changed.
    # ===
    # Review changes between tail and head in a single diff
    - walk-hist [FILE]
    # Diff changed files between target and our current branch
    - walk-diff [FILE]
    # Edit changed files in pairs: ours and the target branch version (for ref)
    - walk-edit [FILE]

    # Stand alone versions of the walk commands are also available:
    # ===
    - edit FILE
    - diff FILE
    - hist FILE

EXAMPLES:

    # Be up-to-date and on the branch to review.
    $ git fetch && git checkout some-tricky-branch

    # See what unmerged commits exist from our parent branch.
    $ git-review.sh -v compare

    # Diff each file changed in our target branch since a particular point.
    # Reflects that the folder "MyPackageV1" was moved to "src/MyPackage".
    $ git-review.sh -vv \\
        -m MyPackageV1:src/MyPackage \\
        -T a7a66b6d429b27b6eb62648781ed53b1aa26f61f \\
        -H origin/pre-release \\
        walk-diffs
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
    if [ ${#MAP_PATHS[@]} -gt 0 ]; then
        for map in "${MAP_PATHS[@]}"; do
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


guess_branch_source() {
    local dst="$1"
    # e.g. a7a66b6d429b27b6eb62648781ed53b1aa26f61f main
    git reflog --no-abbrev-commit \
        | grep -E ": checkout: moving from .* to $dst$" \
        | tail -n 1 \
        | sed -E 's|([^ ]+).*checkout: moving from (.*) to .*|\1 \2|'
}


_action_edit() {
    local path="$1"
    local git_ref="$2"
    local local_path="$(apply_path_maps "$path")"
    local_path=$(_get_rename "$path")

    # Best to have a similar name for any syntax highlighting hints.
    local tmp_dir="$(mktemp -d)" || fail "Could not create temp dir"
    local tmp_file="$(mktemp "$tmp_dir/$(basename "$path")")" \
        || fail "Could not create temp file"
    [ -f "$local_path" ] \
        || rem "File $local_path does not exist. You may need --map or it was recently created in $TARGET_BRANCH" 1

    # We use a subshell to ensure we clean up the temp files and retain the
    # exit status.
    (
        {
            echo "# ================================"
            echo "# TEMPORARY FILE: $tmp_file"
            echo "# GENERATED VIA: git show $git_ref:$path"
            echo "# ================================"
            cmd git show "$git_ref:$path" >> "$tmp_file" \
                || {
                    echo "#"
                    echo "# Failed to find $path in $git_ref"
                    echo "#"
                }
        } > "$tmp_file"
        quit=0
        cmd "$EDITOR" $EDITOR_ARGS "$local_path" "$tmp_file" \
            || quit=1
        rm -rf "$tmp_dir" &>/dev/null
        exit $quit
    )
}


# $1 = needle
# $2 = haystack
# $3 = fuzzy = 1|0 = 0
# Examples:
# _match 'foo' 'foobar' 1 && echo "Matched"
# _match 'foo' 'foobar' || echo "Not matched"
_match() {
    local match
    # Fuzzy vs exact match
    [ ${3:-0} -eq 1 ] && {
        [ -z "${2##*$1*}" ] && return 0
    } || {
        [ "$2" = "$1" ] && return 0
    }
    return 1
}


_git_diff() {
    local tail="$1"; shift
    local awk_fn="$1"; shift
    # We always ignore new files in our local repo
    cmd git diff \
        --name-status \
        --find-renames="$GIT_RENAME_THRESHOLD" \
        "$@" \
        "$HEAD_REF..$tail" -- . \
        | awk "\$1 != \"A\" {print \$$awk_fn}"
}


# $1 = path to match within target branch
# Prints the renamed path (e.g. for our local repo) if found, otherwise the same
# path as was searched for.
_RENAME_CACHE=
_get_rename() {
    local to_match="$1"
    [ -z "$_RENAME_CACHE" ] && {
        _RENAME_CACHE="$(_git_diff HEAD 0 | grep '^R')" \
            || fail "Could not get rename info"
    }
    echo "$_RENAME_CACHE" \
        | while read -r line; do
            IFS=$'\t' parts=($line)
            # We exit 1 on match to quit early and signal success (backwards :D)
            _match "$to_match" "${parts[1]}" "$FUZZY_MATCH" && {
                echo "${parts[2]}"
                exit 1
            } || continue
        done
    # If we didn't quit early w/ non-0, we didn't match so return the original
    [ $? -eq 0 ] && {
        echo "$to_match"
        exit 1
    }
    exit 0
}


# Finds a path, using fuzzy matching, based on a specific git ref (e.g. our
# target branch).
# $1 = git ref
# $2 = fuzzy_match_path
_find_git_path() {
    # Tricky: we quit on match, but w/ a return code... which we'll invert
    # for the final return to be more BASH like.
    # We don't want to match on new files.
    _git_diff "$1" 2 \
        | while read -r git_path; do
            _match "$2" "$git_path" 1 && echo "$git_path" && exit 1
        done \
            && return 1 \
            || return 0
}


# collect args
# ==========================================

VERBOSE=0

# Expected to be used in helper functions
REPO_DIR=
HEAD_REF=
TAIL_REF=
TARGET_BRANCH=  # w/o remote in path
MAP_PATHS=()
FUZZY_MATCH=0
# Filled in after arg validation
TARGET_BRANCH_FULL=   # w/ remote in path
CUR_BRANCH=
GIT_REMOTE=
LAST_MERGED_HASH=

# All left-over args after parsing action are action args.
action=
action_args=()

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
            [ -n "$REPO_DIR" ] && fail "Repo path already given as $REPO_DIR"
            REPO_DIR="$(cd "$2" && git rev-parse --show-toplevel)" \
                || fail "Could not get git repo path"
            shift
            ;;
        -T|--tail)
            [ $# -ge 2 ] || fail "Missing arg to --tail|-T"
            [ -n "$TAIL_REF" ] && fail "Only one tail hash allowed"
            TAIL_REF="$2"
            shift
            ;;
        -H|--head)
            [ $# -ge 2 ] || fail "Missing arg to --head-hash|-H"
            [ -n "$HEAD_REF" ] && fail "Only one head hash allowed"
            HEAD_REF="$2"
            shift
            ;;
        -m|--map)
            [ $# -ge 2 ] || fail "Missing arg to --map|-m"
            MAP_PATHS+=("$2")
            shift
            ;;
        -f|--fuzzy)
            FUZZY_MATCH=1
            ;;
        -b|--branch)
            [ $# -ge 2 ] || fail "Missing arg to --parent|-p"
            [ -n "$TARGET_BRANCH" ] && fail "Only one parent branch allowed"
            TARGET_BRANCH="$2"
            shift
            ;;
        *)
            [ -z "$action" ] && action="$1" || action_args+=("$1")
            ;;
    esac
    shift
done

[ $VERBOSE -ge 2 ] && set -x


# prep & error checkinstg
# ==========================================

# at least validate the repo bits first
[ -z "$REPO_DIR" ] && {
    REPO_DIR="$(git rev-parse --show-toplevel)" \
       || fail "Could not get git repo path"
    rem "Using repo dir: $REPO_DIR"
}

# With all paths finalized, we always want to play in the root.
cmd cd "$REPO_DIR" || fail "Could not cd to repo root: $REPO_DIR"

# Extra metadata about the repo (and to help seed default args)
GIT_REMOTE="$(git remote)" \
    || fail "Could not get remote for $REPO_DIR"
CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD)" \
    || fail "Failed to get branch name"
[ -z "$TARGET_BRANCH" ] && {
    _source="$(guess_branch_source "$CUR_BRANCH")" \
        || fail "Could not guess parent branch"
    # e.g. "a7a66b6d429b27b6eb62648781ed53b1aa26f61f main"
    _pre_branch_commit="${_source%% *}"
    TARGET_BRANCH="${_source#$_pre_branch_commit }" \
        || fail "Could not guess parent branch"
    rem "Guessed parent branch: $TARGET_BRANCH"
}
# Only add remote as needed
[ "${TARGET_BRANCH#$GIT_REMOTE/}" = "$TARGET_BRANCH" ] && {
    TARGET_BRANCH_FULL="$GIT_REMOTE/$TARGET_BRANCH"
} || {
    TARGET_BRANCH_FULL="$TARGET_BRANCH"
}
LAST_MERGED_HASH="$(cmd git merge-base "$CUR_BRANCH" "$TARGET_BRANCH_FULL")" \
    || fail "Could not get merge base hash for $CUR_BRANCH and $TARGET_BRANCH_FULL"

[ -z "$TAIL_REF" ] && {
    TAIL_REF="$LAST_MERGED_HASH"
    rem "Using last merged hash as tail: $TAIL_REF"
}
[ -z "$HEAD_REF" ] && {
    HEAD_REF="$TARGET_BRANCH_FULL" \
        || fail "Could not get remote for $TARGET_BRANCH"
    rem "Using remote parent branch as head: $HEAD_REF"
}

[ -z "$action" ] && fail "No action specified"

# Verify a few args
git rev-parse --verify "$TAIL_REF" >/dev/null \
    || fail "Invalid tail ref in repo; 'git fetch' maybe?"
git rev-parse --verify "$HEAD_REF" >/dev/null \
    || fail "Invalid head ref in repo; 'git fetch' maybe?"


# script body
# ==========================================

if [ "$action" = 'list-commits' ]; then
    git_args=("$TAIL_REF..$HEAD_REF" -- .)
    [ ${#action_args[@]} -gt 0 ] && git_args+=("${action_args[@]}")
    cmd git log "${git_args[@]}" || fail "git log failed"

elif [ "$action" = 'list-files' ]; then
    git_args=("--name-status" "$TAIL_REF..$HEAD_REF" -- .)
    [ ${#action_args[@]} -gt 0 ] && git_args+=("${action_args[@]}")
    cmd git diff "${git_args[@]}" || fail "git diff failed"

elif [ "$action" = 'compare' ]; then
    # Detect which branch we were branched from for default value:
    [ ${#action_args[@]} -eq 0 ] || fail "No arguments expected for compare"

    rem "=== Last commit merged from $TARGET_BRANCH_FULL: ===" 1
    cmd git log -1 "$LAST_MERGED_HASH" || fail "Could not get merge base info"
    echo

    rem "=== Last commit in $TARGET_BRANCH_FULL: ===" 1
    cmd git log -1 "$TARGET_BRANCH_FULL" || fail "Could not get target branch info"
    echo

    rem "=== Difference between $TARGET_BRANCH_FULL and --head" 1
    cmd git --no-pager diff --stat "$TARGET_BRANCH_FULL..$HEAD_REF" || fail "Could not get diff info"
    echo

    rem "=== Difference between --tail and --head" 1
    cmd git --no-pager diff --stat "$TAIL_REF..$HEAD_REF" || fail "Could not get diff info"
    echo

    rem "=== Useful hashes ===" 1
    last_hash="$(cmd git rev-parse "$TARGET_BRANCH_FULL")" \
        || fail "Could not get target branch info"
    cat <<EOI
head_hash=$(cmd git rev-parse $HEAD_REF)  # from --head (or default)
tail_hash=$(cmd git rev-parse $TAIL_REF)  # from --tail (or default)
target_hash_merged=$LAST_MERGED_HASH  # last commit merged from $TARGET_BRANCH
target_hash_head=$last_hash  # last commit in $TARGET_BRANCH
EOI

elif [ "$action" = 'walk-hist' ]; then
    only_path=
    [ ${#action_args[@]} -gt 1 ] && fail "Too many arguments for walk-hist"
    [ ${#action_args[@]} -ge 1 ] && only_path="${action_args[0]}"

    # For each file, show what was changed
    _git_diff "$TAIL_REF" 2 | while read -r path; do
        [ -n "$only_path" ] && {
            _match "$only_path" "$path" $FUZZY_MATCH  || continue
        }
        rem "Net Change: $path"
        cmd git diff \
            --color=always \
            $TAIL_REF..$HEAD_REF -- "$path" \
            | less -RK \
            || break
    done

elif [ "$action" = 'hist' ]; then
    [ ${#action_args[@]} -eq 1 ] || fail "Missing file path for hist"
    path="${action_args[0]}"
    [ $FUZZY_MATCH -eq 1 ] && {
        path="$(_find_git_path "$TAIL_REF" "$path")" \
            || fail "Could not find file path in $HEAD_REF"
    }
    git diff --color=always $TAIL_REF..$HEAD_REF -- "$path"

elif [ "$action" = 'walk-diff' ]; then
    only_path=
    [ ${#action_args[@]} -gt 1 ] && fail "Too many arguments for walk-log"
    [ ${#action_args[@]} -ge 1 ] && only_path="${action_args[0]}"

    # For each file, diff source and target versions between repos
    _git_diff "$TAIL_REF" 2 | while read -r path; do
        [ -n "$only_path" ] && {
            _match "$only_path" "$path" $FUZZY_MATCH  || continue
        }
        local_path="$(apply_path_maps "$path")"
        local_path="$(_get_rename "$local_path")"
        {
            echo "Source: git show $HEAD_REF:$path"
            echo "Target: $local_path"
            if [ -f "$local_path" ]; then
                # Snag source file via git show to get right version w/ hash
                cmd git show "$HEAD_REF:$path" \
                    | cmd diff -b -u --color=always \
                    - \
                    "$local_path"
            else
                rem "File $local_path does not exist. You may need --map or it was recently created in $TARGET_BRANCH" 1 2>&1
            fi
        } | less -RK || break
    done

elif [ "$action" = 'diff' ]; then
    [ ${#action_args[@]} -eq 1 ] || fail "Missing file path for diff"
    path="${action_args[0]}"
    [ $FUZZY_MATCH -eq 1 ] && {
        path="$(_find_git_path "$TAIL_REF" "$path")" \
            || fail "Could not find file path in $HEAD_REF"
    }
    cmd git diff --color=always $TAIL_REF..$HEAD_REF -- "$path"

elif [ "$action" = 'walk-edit' ]; then
    only_path=
    [ ${#action_args[@]} -gt 1 ] && fail "Too many arguments for walk-edit"
    [ ${#action_args[@]} -ge 1 ] && only_path="${action_args[0]}"

    # For each file, edit source and target versions together

    # We don't want to hijack stdin (e.g. maybe it's vim and there is a prompt).
    # We'll assume no newlines, but we need to handle spaces in paths.
    IFS=$'\n' path_list=($(_git_diff "$TAIL_REF" 2))
    for path in "${path_list[@]}"; do
        [ -n "$only_path" ] && {
            _match "$only_path" "$path" $FUZZY_MATCH  || continue
        }
        rem "File: $path"
        # No need to prompt w/ just one thing to edit
        [ -z "$only_path" ] && {
            # Some editors are hard to quit w/ non-zero status (vim tip: use `:cq`).
            echo "Target: $(_get_rename "$path")"
            echo "Source: git show $HEAD_REF:$path"
            echo "---"
            prompt_yn \
                "Editing with $EDITOR. (c)ontinue or (q)uit?" \
                c q \
                || break
            echo
        }
        _action_edit "$path" "$HEAD_REF" || break
    done

elif [ "$action" = 'edit' ]; then
        [ ${#action_args[@]} -eq 1 ] || fail "Missing file path for edit"
        path="${action_args[0]}"
        [ $FUZZY_MATCH -eq 1 ] && {
            path="$(_find_git_path "$TAIL_REF" "$path")" \
                || fail "Could not find partial path '$path' in $HEAD_REF"
        }
        _action_edit "$path" "$HEAD_REF"

else
    fail "Unknown action: $action"
fi
