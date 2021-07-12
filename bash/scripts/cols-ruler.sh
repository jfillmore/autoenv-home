#!/bin/bash -u


# $1 = num of 10 space indents
add_indent() {
    indent=$(($1 * 10 + 1))
    echo -en "\033[${indent}G"
}


breakquit() {
    echo -e "\033[0m\n\n\n"
    exit 1
}

colors=(
    '0;41;30'
    '0;101;30'
    '0;103;30'
    '0;43;30'
    '0;42;30'
    '0;102;30'
    '0;106;30'
    '0;46;30'
    '0;104;30'
    '0;44;30'
)

max_cols=$(tput cols)
tens=$((max_cols / 10 + 1))

done=0
loop=0


echo "cols: $max_cols"
while [ $done -eq 0 ]; do

    i=0
    while [ $done -eq 0 ]; do
        add_indent $i
        echo -e "\033[${colors[i % 10]}m$i"
        add_indent $i

        for n in {0..9}; do
            echo -en "\033[${colors[i % 10]}m$n"
            [ $(( (i * 10) + n + 1 )) -ge $max_cols ] && done=1
            [ $done -eq 1 ] && break
        done

        [ $done -eq 1 ] && break
        echo -en "\033[1F"
        [ $loop -eq 1 -a $i -eq 3 ] && breakquit
        i=$((i + 1))
    done
    loop=$((loop + 1))

done

echo -e "\033[0m\n"

