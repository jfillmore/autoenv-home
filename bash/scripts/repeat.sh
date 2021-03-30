#!/bin/bash -u

BASE_DIR=$(cd $(dirname "$0") && pwd -P)
SCRIPT_NAME=$(basename "$0")



usage() {
    cat <<EOI
Usage: $SCRIPT_NAME [ARGS] [CMD] [CMD_ARGS...]

ARGS:

    --help|-h       This information
    -1              Repeat only if there was a failure

Arguments must be given up front. All other args are used to run the final
command.
EOI
}


fail() {
    echo "${1-$SCRIPT_NAME command failed}" >&2
    exit ${2:-1}
}


[ $# -eq 0 ] && {
    usage
    fail 'no arguments given'
}

# handle what few args we take
repeat_fail_only=0
case "$1" in
    --help|-h)
        usage
        exit
        ;;
    -1):
        repeat_fail_only=1
        shift
        ;;
esac

# repeat, prompting each time, as long as needed; 80 chars per block
line_break='────────────────────────────────────────────────────────────────────────────────'
line_break="$line_break$line_break$line_break"

# print initial start marker
cols=$(tput cols)
echo -e "\033[1;37m╓${line_break:0:cols-1}\033[1D╖\033[0m\n"

# loop forever-ish!
while true; do
    # run command and prep output
    "$@"
    retval=$?
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

    cols=$(tput cols)
    echo -e "\n\033[${color_line}m╙${line_break:0:cols-1}\033[1D╜\033[0m"
    echo -en " \033[${color_msg}m  -- $msg -- \033[0m"
    echo -ne "\033[${color_line}m│\033[1;37m  (\033[1;33m\\\n\033[0;37m to repeat, \033[1;33m^c\033[0;37m to quit) "
    # pause, hiding input so newlines don't cause goofy stuff
    stty -echo &>/dev/null
    read
    stty echo &>/dev/null
    echo -e "\n\n\033[1;37m╓${line_break:0:cols-1}\033[1D╖\033[0m\n"
done
