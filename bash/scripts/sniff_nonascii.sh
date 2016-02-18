#!/bin/sh -u

BASE_DIR=$(cd $(dirname "$0") && pwd -P)
SCRIPT_NAME=$(basename "$0")

fail() {
	echo "$@"
	exit 1
}

rem() {
    [ "$VERBOSE" -eq 1 ] && echo "+ [$@]" >&2
}

usage() {
    cat <<EOI
Usage: $SCRIPT_NAME [ARGUMENTS] [EXT1] [EXT2] [...]
(e.g.)

Finds files containing non-ascii characters matching the supplied file extensions. Recursively searches the current diretory.

OPTIONS:
    -h|--help             This information
    -v|--verbose          Print debugging information to stdout
EOI
}

cmd() {
    if [ $DRYRUN -eq 1 ]; then
        echo "# $@"
    else
        $@
        [ $VERBOSE -eq 1 ] && echo "> $@" >&2
    fi
}

# collect args
# ==========================================

VERBOSE=0
DRYRUN=0

extensions=()

while [ $# -gt 0 ]; do
    arg="$1"
    shift
    case "$arg" in 
        --dry-run|-d)
            DRYRUN=1
            ;;
        --verbose|-v)
            VERBOSE=1
            ;;
        --help|-h)
            usage
            exit
            ;;
        *)
            extensions[${#extensions[*]}]="$arg"
            ;;
    esac
done

num_exts=${#extensions[*]}

find_args=( . -type f )
[ $num_exts -gt 0 ] && {
    find_args[${#find_args[*]}]="("
    for ((i=0; i<$num_exts; i++)); do
        ext=${extensions[$i]}
        [ $i -gt 0 ] && find_args[${#find_args[*]}]="-o"
        find_args[${#find_args[*]}]="-iname"
        find_args[${#find_args[*]}]="*.$ext"
    done
    find_args[${#find_args[*]}]=")"
}

# horrible, horrible performance... but its a dirty job anyway
find "${find_args[@]}" | while read fname; do
    [ -f "$fname" ] || fail "Failed to read file name '$fname' correctly"
    found=$(pcregrep -c "[\x80-\xFF]+" "$fname" 2>/dev/null)
    [ $? -ne 0 ] && {
        echo ">> Failed to parse file '$fname'; line lengths way too long, maybe? <<"
        echo
    }
    [ $found -gt 0 ] && {
        # first line of many of these has a byte order mark at the start
        errors=$(pcregrep -o -n "[\x80-\xFF]+" "$fname" | grep -v '^1:' 2>/dev/null)
        [ ${#errors} -gt 0 ] && {
            echo "====> $fname (~$found found) <===="
            pcregrep -o --color=auto -n "[\x80-\xFF]+" "$fname" 2>/dev/null
            echo
            echo
        }
    }
done | less -R

exit 0
