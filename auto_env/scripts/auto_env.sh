#!/bin/sh -u

# Automatically sync scripts and resource files for bash, vim, fluxbox, etc.
# Downloaded files are all placed within the user home directory, possibly
# creating sub-directories as needed. Scripts and other executables will have
# the file permissions set automatically.

BASE_DIR=$(cd $(dirname "$0") && pwd -P)
SCRIPT_NAME=$(basename "$0")
HTTP_AGENT= # will be auto detected (e.g. wget/curl)
TMP_DIR="$HOME/.$SCRIPT_NAME"

# specified in arguments
#auto_env_url="https://localhost/auto_env"
auto_env_url="https://raw.github.com/jfillmore/auto_env/master/"
verbose=0
force=0
action=''
# no arrays in /bin/sh, ergo: target_* vars
# target_$target_ctr="/var/www/some path"
target_ctr=0
dryrun=0 # don't actually make changes...


# Generic helpers
# ==========================================
cleanup() {
    # clean up our temp dir files
    rm -rf "$TMP_DIR" 2>/dev/null
}

fail() {
    cleanup
    echo "! $@" >&2
    exit 1
}

usage() {
    cat <<EOI >&2
usage: $SCRIPT_NAME [OPTIONS] ACTION

ACTION
    -i, --index     FOLDERS     Build index file of specified directory.
    -s, --sync      TARGETS     Sync specified targets to local computer.

OPTIONS
    -d, --dryrun    Run to completion, but do not save/overwrite anything.
                    Takes precedence over '--force', if present.
    -f, --force     Force-update files, even if unchanged.
    -h, --help      Show this information and exit.
    -u, --url       Base URL for downloading files.
                    (Default: $auto_env_url)
    -v, --verbose   Show verbose debugging information in STDERR.

INDEX FOLDERS
    A list of all the files in the specified folders will be read. The SHA1
    sum, path, and whether the file is executable will be stored in the index
    file. Also skips any vim swap files.

SYNC TARGETS
    Each target specified will have the appropriate files downloaded, creating
    any directories as needed. All files are copied to your user home
    directory ($HOME). Uses curl if avalable; otherwise wget.

Examples:
---------
# Build (or rebuild) indexes for all folders in one spot:
$ $SCRIPT_NAME -i /var/www/html/auto_env/* -v

# Sync files for a few targets, but don't make any changes (e.g. see what would
# have been updated).
$ $SCRIPT_NAME -i /var/www/html/auto_env/* -v -d
EOI
}

# auto_env methods
# ==========================================
rem() {
    if [ $verbose -eq 1 ]; then
        if [ $# -eq 0 ]; then
            sed 's/^/+ /'
        else
            echo "+ $@" >&2
        fi
    fi
}

detect_http_agent() {
    local agent https
    # see if we are using HTTPs or not
    if echo "$auto_env_url" | tr '[a-z]' '[A-Z]' | grep -q "^HTTPS:"; then
        https=1
    else
        https=0
    fi
    # detect which HTTP agent is installed
    agent=$(which curl)
    if [ $? -eq 0 ]; then
        if [ $https -eq 1 ]; then
            agent="$agent --insecure"
        fi
        agent="$agent --silent --fail"
    else
        # no curl? how about wget?
        agent=$(which wget) || \
            fail "Unable to locate 'curl' or 'wget' to download files."
        if [ $https -eq 1 ]; then
            agent="$agent --no-check-certificate"
        fi
        agent="$agent --quiet"
        fail "Currently unable to use 'wget' due to a bug somewhere :)"
    fi
    echo "$agent"
}

# collect args
# ==========================================
if [ $# -eq 0 ]; then
    usage
    exit 1;
fi
while [ $# -gt 0 ]; do
    arg="$1"
    shift
    case "$arg" in 
        --url|-u)
            [ $# -ge 1 ] || fail "Missing argument to '--url' switch."
            auto_env_url="$1"
            shift
            ;;
        --sync|-s)
            if [ ${#action} -ne 0 ]; then
                fail "Action of '$action' already specified."
            fi
            action='sync'
            ;;
        --index|-i)
            if [ ${#action} -ne 0 ]; then
                fail "Action of '$action' already specified."
            fi
            action='index'
            ;;
        --dryrun|-d)
            dryrun=1
            ;;
        --force|-f)
            force=1
            ;;
        --verbose|-v)
            verbose=1
            ;;
        --help|-h)
            usage
            exit
            ;;
        *)
            # hack to handle possible spaces (e.g. in dirs to index)
            target_ctr=$((target_ctr+1))
            eval target_$target_ctr="\$arg" || fail "Failed to collect arg '$arg'."
            ;;
    esac
done

# quick sanity check...
if [ ${#action} -eq 0 ]; then
    fail "Please specify an action of either --index or --sync."
fi
if [ $target_ctr -eq 0 ]; then
    usage
    fail "No directories/targets specified."
fi
shasum="$(which shasum 2>/dev/null) -a 1" \
    || shasum=$(which sha1sum 2>/dev/null) \
    || fail "Failed to locate 'shasum' or 'sha1sum' binary."

# and do our job!
# ==========================================
if [ $action = 'index' ]; then
    # generate 'index.auto_env' for each dir given
    org_dir=$(pwd -P)
    for i in $(seq 1 $target_ctr); do
        dir=$(eval echo "\$target_$i")
        rem "Generating index '$(basename $dir)/index.auto_env'"
        cd "$org_dir" || fail "Failed to change directory back to '$org_dir'."
        if [ ! -d "$dir" ]; then
            fail "Invalid directory: '$dir'."
        fi
        cd "$dir" || fail "Failed to change to '$dir'."
        # generate checksums for everything in here
        # don't overwrite the existing index until we are done
        find . -type f -print0 | xargs -0 $shasum > .index.auto_env.$$
        if [ $? -ne 0 ]; then
            rm .index.auto_env.$$ &>/dev/null
            fail "Failed to generate checksum list for directory '$dir'."
        fi
        # TODO: look for things in the existing index file and report how many new/changed/added
        # filter and augument the list
        scripts=0 # out of curiosity, how many were scripts?
        while read checksum path; do
            skip=0
            # don't include our own checksum files in the index, or swap files
            if echo "$path" | grep -qE '^(.*/\..*\.sw.|\.\/\.?index\.auto_env(\.[0-9]+)?)$'; then
                skip=1
            fi
            if [ $skip -eq 0 ]; then
                # figure out which were executable files
                name=$(find "$path" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \))
                if [ ${#name} -ne 0 ]; then
                    exec_bit=1
                    scripts=$((scripts + 1))
                else 
                    exec_bit=0
                fi
                echo "$exec_bit  $checksum  "$(echo "$path" | sed 's/^\.\///')
            fi
        done < .index.auto_env.$$ > .index.auto_env.$$.done
        if [ $? -ne 0 ]; then
            rm .index.auto_env.$$ &>/dev/null
            rm .index.auto_env.$$.done &>/dev/null
            fail "Failed to generate index file for '$dir'."
        fi
        # put our new files in place
        rm .index.auto_env.$$ &>/dev/null
        if [ $dryrun -eq 0 ]; then
            mv .index.auto_env.$$.done index.auto_env
            if [ $? -ne 0 ]; then
                rm .index.auto_env.$$.done &>/dev/null
                fail "Failed to move auto_env index '$dir/index.auto_env'."
            fi
            lines=$(wc -l index.auto_env | awk '{print $1}')
        else
            lines=$(wc -l .index.auto_env.$$.done | awk '{print $1}')
            rm .index.auto_env.$$.done &>/dev/null
        fi
        rem "[files: $lines, scripts: $scripts]"
    done
# -------------------------------------------
elif [ "$action" = 'sync' ]; then
    HTTP_AGENT=$(detect_http_agent)
    cd "$HOME" || fail "Failed to change to user home directory ($HOME)."
    [ -d "$TMP_DIR" ] || {
        mkdir "$TMP_DIR" || fail "Failed to create temp directory ($TMP_DIR)."
    }
    # for each target download the auto_env index and listed files
    for i in $(seq 1 $target_ctr); do
        target=$(eval echo "\$target_$i")
        rem "Downloading index list for target '$target'"
        $HTTP_AGENT "$auto_env_url/$target/index.auto_env" \
            > "$TMP_DIR/index.auto_env" || \
            fail "Failed to retrieve file list for target '$target'."
        # download all the files listed
        while read exec_bit checksum path; do
            rem "- fetching file '$path'"
            base_dir=$(dirname "$path" | sed 's/^\.\///') \
                || fail "Failed to get base directory of '$path'."
            if [ -z "$base_dir" ]; then
                base_dir=.
            fi
            file_name=$(basename "$path") \
                || fail "Failed to get file name of '$path'."
            $HTTP_AGENT "$auto_env_url/$target/$path" \
                > "$TMP_DIR/$file_name" \
                || fail "Failed to download '$TMP_DIR/$target/$path'."
            # TODO: check return code for 200-299 http response
            # does the checksum match?
            new_checksum=$($shasum "$TMP_DIR/$file_name" | awk '{print $1}') \
                || fail "Failed to generate checksum for '$path'."
            if [ $new_checksum != $checksum ]; then
                preview_lines=6
                rem "-- File checksum mismatch (first $preview_lines lines)"
                rem "------------------------------------------"
                head -n $preview_lines "$TMP_DIR/$file_name" | rem
                rem "------------------------------------------"
                # file failed to download... odd. Permissions/misconfig, perhaps?
                fail "Checksum error on '$path' from '$target' (expected: $checksum, got: $new_checksum)."
            fi
            # do we have this file already, and with a matching checksum?
            file_changed=1
            if [ -e "$base_dir/$file_name" ]; then
                old_checksum=$($shasum "$base_dir/$file_name" | awk '{print $1}') \
                    || fail "Failed to generate checksum for exiting copy of '$path'."
                if [ $old_checksum = $checksum ]; then
                    if [ $force -ne 1 ]; then
                        rem "-- skipping unchanged file"
                        file_changed=0
                    fi
                else
                    rem "-- checksum mismatch: old=$old_checksum, new=$checksum"
                fi
                # regardless of the file changed make sure the exec bit is set right
                if [ $file_changed -eq 0 \
                    -a $exec_bit = '1' \
                    -a ! -x "$base_dir/$file_name" \
                    ]; then
                    rem "-- toggling execution bit"
                    chmod u+x "$base_dir/$file_name" \
                        || fail "Failed to chmod 'u+x' file '$base_dir/$file_name'."
                fi
            fi
            if [ $file_changed -eq 1 ]; then
                # was this a script?
                if [ $exec_bit = '1' ]; then
                    rem "-- toggling execution bit"
                    chmod u+x "$TMP_DIR/$file_name" \
                        || fail "Failed to chmod 'u+x' file '$TMP_DIR/$file_name'."
                fi
                # create any leading directories if needed
                if [ "$base_dir" != '.' ]; then
                    mkdir -p "$base_dir" \
                        || fail "Failed to create base directory '$base_dir'."
                fi
                # and move it into place
                if [ $dryrun -eq 0 ]; then
                    mv "$TMP_DIR/$file_name" "$base_dir/" || \
                        fail "Failed to move '$file_name' to '$base_dir'."
                fi
            fi
        done < "$TMP_DIR/index.auto_env"
    done
fi

# woot, all done!
cleanup
exit 0
