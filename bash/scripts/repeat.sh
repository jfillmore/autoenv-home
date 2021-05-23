#!/bin/bash -u

BASE_DIR=$(cd $(dirname "$0") && pwd -P)
SCRIPT_NAME=$(basename "$0")


# TODO:
# repeat mode: quiet, bell, "say", etc


usage() {
    cat <<EOI
Usage: $SCRIPT_NAME [ARGS] [CMD] [CMD_ARGS...]

ARGS:

    -h|--help        This information
    -f|--fullscreen  Fullscreen mode using alternative buffer (e.g. like vim)
    -v|--verbose     Include extra output each iteration
    -N|--null        Null mode = don't actually repeat
    -1               Repeat only if there was a failure

Arguments must be given up front. All other args are used to run the final
command.
EOI
}

cleanup_screen() {
    # currenly only called via `trap ... EXIT` on fullscreen mode
    tput rmcup
}

fail() {
    echo "${1-$SCRIPT_NAME command failed}" >&2
    exit ${2:-1}
}


[ $# -eq 0 ] && {
    usage
    fail 'no arguments given'
}

# handle what few args we take, which all must be leading the command.
repeat_fail_only=0
repeat=1
fullscreen=0
verbose=0
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit
            ;;
        -f|--fullscreen)
            fullscreen=1
            ;;
        -N|--null)
            repeat=0
            ;;
        -v|--verbose)
            verbose=1
            ;;
        -1)
            repeat_fail_only=1
            ;;
        *)
            break
            ;;
    esac
    shift
done


# setup hacks
# ==============================================================================
# repeat, prompting each time, as long as needed; 80 chars per block
line_break='────────────────────────────────────────────────────────────────────────────────'
line_break="$line_break$line_break$line_break"

[ $fullscreen -eq 1 ] && {
    tput smcup || fail "failed to enter fullscreen/alt buffer mode"
    trap cleanup_screen EXIT
}


# setup hacks
# ==============================================================================
# print initial start header
loop=1
cols=$(tput cols)
[ $verbose -eq 1 ] \
    && echo -e "\033[0;33;40m# $(printf "'%s' " "$@")\033[0;0m"
echo -e "\033[1;37m╓${line_break:0:cols-1}\033[1D╖\033[0m"
echo -e "\033[1A\033[3C \033[1;37m$(date) \033[0;37m(# $loop)\033[0m "

# loop forever-ish!
while true; do
    # run command and prep output
    time_start=$(date +%s)
    "$@"
    retval=$?
    time_end=$(date +%s)
    [ $retval -eq 0 -a $repeat_fail_only -eq 1 ] && exit
    if [ $retval -eq 0 ]; then
        msg='SUCCESS'
        color_msg='1;32'
        color_line='0;32'
    else
        msg="FAIL: $retval"
        color_msg='1;31'
        color_line='0;31'
    fi

    # print footer + prompt
    cols=$(tput cols)
    echo -e "\n\033[${color_line}m╙${line_break:0:cols-1}\033[1D╜\033[0m"
    echo -e "\033[1A\033[3C \033[${color_msg}m$(date)\033[${color_line}m [$((time_end - time_start)) s]\033[0m "
    echo -en " \033[${color_msg}m  -- $msg -- \033[0m"
    echo -ne "\033[${color_line}m│\033[1;37m  (\033[1;33m\\\n\033[0;37m to repeat, \033[1;33m^c\033[0;37m to quit) "

    [ $repeat -eq 0 ] && exit

    # pause, hiding input so newlines don't cause goofy stuff
    stty -echo &>/dev/null
    read
    stty echo &>/dev/null

    # clear if fullscreen; else just add some buffering between commands
    if [ $fullscreen -eq 1 ]; then
        tput clear
    else
        echo -e "\n\n"
    fi

    # print next header
    let loop+=1
    cols=$(tput cols)
    [ $verbose -eq 1 ] \
        && echo -e "\033[0;33;40m# $(printf "'%s' " "$@")\033[0;0m"
    echo -e "\033[1;37m╓${line_break:0:cols-1}\033[1D╖\033[0m"
    echo -e "\033[1A\033[3C \033[1;37m$(date) \033[0;37m(# $loop)\033[0m "
done
