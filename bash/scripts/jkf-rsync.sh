#!/bin/bash -u

BASE_DIR=$(cd $(dirname "$0") && pwd -P)
SCRIPT_NAME=$(basename "$0")

# TODO:
# - add .jkf-ignore and opts to manage it


# functions
# ==========================================

usage() {
    cat <<EOI
Usage: $SCRIPT_NAME push|pull PATH [HOST] [HOST...] [ARGUMENTS]
(e.g.)

Sync directory with peers. Avoids syncing out-of-date dirs based on
last-updated timestamp files. Uses the same PATH (w/ symlinks resolved
first) locally and with each peer, but with home directories normalized.

Peers are auto-tracked via ".jkf-rsync-peers" files, which are NOT sync'd.
This file is looked for in parent directories, and if not found will be
created in PATH specified (which will also require an initial HOST).


ARGUMENTS:

    -p|--prune            Prune deleted files during sync (caution!)
    -d|--dry-run          Run without making any changes
    -h|--help             This information
    -v|--verbose          Print debugging information to stdout

EXAMPLE:

    \$ $SCRIPT_NAME
EOI
}

# Fail and quit w/ the error given
fail() {
    echo -e "\033[1;31m${1-$SCRIPT_NAME command failed}\033[0m" >&2
    exit ${2:-1}
}

# Print a comment
rem() {
    [ "$VERBOSE" -eq 1 ] && echo -e "+ [\033[1;37;40m$@\033[0;0m]" >&2
}

# Command runner that can print a quoted version out first
cmd() {
    [ $VERBOSE -eq 1 ] \
        && echo -e "\033[0;33;40m# $(printf "'%s' " "$@")\033[0;0m" >&2
    "$@"
}

# Scan the path given, including parent dirs (up to /) for .jkf-rsync-peers
# Prints out the path, if found
find_peer_file() {
    local path="$1"; shift
    (
        cd "$path"
        while true; do
        [ "$PWD" = '/' ] && exit 1
        [ -f .jkf-rsync-peers ] && {
            echo "$PWD/.jkf-rsync-peers"
            exit 0
        }
        cd ..
        done
    )
    return $?
}


# collect args
# ==========================================

VERBOSE=0
DRYRUN=0
JKF_USER="${JKF_USER:-jkf}"

do_prune=0
sync_path=
action=
hosts=()

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run|-d)
            DRYRUN=1
            ;;
        --verbose|-v)
            VERBOSE=1
            ;;
        --prune|-p)
            do_prune=1
            ;;
        --help|-h)
            usage
            exit
            ;;
        *)
            if [ -n "$action" ]; then
                [ -n "$sync_path" ] \
                    && hosts+=("$1") \
                    || sync_path="$1"
            else
                action="$1"
            fi
            ;;
    esac
    shift
done


# prep & error checking
# ==========================================
which rsync &>/dev/null || fail 'rsync not found'
[ -n "$sync_path" ] || { usage; fail "No path to sync given"; }
[ -n "$action" ] || { usage; fail "No action given"; }
[ -d "$sync_path" ] || fail "Not found or not a folder: $sync_path"
full_sync_path=$(cd "$sync_path" && pwd -P) \
    || fail "Failed to get real path to $sync_path"
rel_sync_path="${full_sync_path##$HOME/}"
[ "$rel_sync_path" = "$sync_path" ] \
    && fail "Cannot sync content outside of $HOME"
jkf_peer_file="$full_sync_path/.jkf-known-hosts"


# script body
# ==========================================

peer_file=$(find_peer_file "$full_sync_path") || {
    peer_file="$full_sync_path/.jkf-rsync-peers"
}
rem "Using peer file '$peer_file' for SSH known hosts"

ssh_args=(
    ssh
    -l "$JKF_USER"
    -o UserKnownHostsFile="$peer_file"
    -o HashKnownHosts=no
)
ssh_args_str="${ssh_args[@]}"
rsync_args=(
    --archive
    --recursive
    --itemize-changes
    --exclude=.jkf-rsync-peers
    # generic stuff to avoid including
    --exclude=.git/
    --exclude=.git*
    --exclude=.DS_Store
    --exclude='.*.sw?'
    --exclude='.sw?'
)
[ $VERBOSE -ge 1 ] && rsync_args+=(--verbose --progress)
[ $DRYRUN -ge 1 ] && rsync_args+=(--dry-run)
[ $do_prune -eq 1 ] && rsync_args+=(--delete)


# use known hosts by default for our peers
[ ${#hosts[*]} -eq 0 ] && {
    hosts=(
        $(awk -F'[, ]' '{print $1}' "$peer_file")
    )
    [ ${#hosts[*]} -eq 0 ] && fail "No hosts known yet"
}


# party hard!
failed=()
rem "$action peers: ${hosts[*]}"
for host in "${hosts[@]}"; do
    remote_path="$host:~/$rel_sync_path/"
    if [ $action = push ]; then
        path_args=("$full_sync_path/" "$remote_path")
    elif [ $action = pull ]; then
        path_args=("$remote_path" "$full_sync_path/")
    else
        fail "invalid action: $action"
    fi
    rem "\n=== $action - $remote_path ==="
    cmd rsync \
        -e "$ssh_args_str" \
        "${rsync_args[@]}" \
        "${path_args[@]}" || {
            failed+=("$host = $?")
        }
done

[ ${#failed[*]} -gt 0 ] && {
    echo -e "\n\033[1;31mFailed Hosts\033[0m" >&2
    for failed_host in "${failed[@]}"; do
        echo -e "\033[1;34m$failed_host\033[0m"
    done
}
exit ${#failed[*]}
