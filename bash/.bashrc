# .bashrc

if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

function psuc {
    ps fu -u "$1" --cumulative
}

function setPrompt {
    echo -en "\e]2;$@\a"
    if [ "$TERM" == "Eterm" ]; then
        echo -en "\e]1;$@\a"
    fi
}

function grim {
    [ $# -eq 1 ] && {
        vim $(grep "$1" * | awk -F: '{sub(/ /, "\\ "); print $1}' | sort -u)
    } || {
        vim $(grep "$1" "$2" | awk -F: '{sub(/ /, "\\ "); print $1}' | sort -u)
    }
}

# javascript checking
function jslint() {
    local options='browser:true, nomen:false'
    local globals='$ jQuery om window document escape'
    # validate params
    [ $# -eq 1 ] || {
        echo "usage: jslint file.js" >&2
        return 1
    }
    [ -s "$1" ] || {
        echo "'$1' does not exist or contains no data." >&2
        return 1
    }
    # pass it to jslint via rhino
    {
        echo "/*jslint $options */"
        echo "/*global $globals */"
        cat "$1"
        # due to shitty EOF detection
        for ((i=0; i<10; i++)); do
            echo
        done
    } | rhino ~/scripts/jslint.js
}

if [[ "$-" =~ 'i' ]]; then
    #set -o vi

    alias jscc='java -jar $HOME/scripts/compiler.jar'
    alias ls="ls -G"
    if [ $UID -eq 0 ]; then
        alias l="ls -la"
        export PS1="\[\033[1;37m\][\[\033[1;33m\]\h \[\033[1;34m\]\w\[\033[1;37m\]]#\[\033[0m\] "
    else
        export PS1="\[\033[1;37m\][\[\033[1;31m\]\h \[\033[1;34m\]\w\[\033[1;37m\]]\$\[\033[0m\] "
        alias l="ls -l"
    fi
    alias grep="grep --color=auto"
    alias mailme="mail -s 'gud stuff' jonny@uk2group.com"
    alias jdiff="diff -yb --suppress-common-lines"
    alias ssh='ssh -o TCPKeepAlive=yes -o ServerAliveInterval=90'
    alias swp_vim="for file in \$(find -iname .\*.swp); do vim -r "\$file" && rm "\$file"; done"
    alias halt='poweroff'

    if [ -d $HOME/scripts ]; then
        PATH="$PATH:$HOME/scripts"
    fi
    if [ -d $HOME/bin ]; then
        PATH="$PATH:$HOME/bin"
    fi
    export PATH
    export HISTSIZE=100000

    unset PROMPT_COMMAND
    setPrompt "${HOSTNAME%%.*}" 

    if [ -f "$HOME/.bashrc.local" ]; then
        . "$HOME/.bashrc.local"
    fi
fi

