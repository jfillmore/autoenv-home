# .bashrc

if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

function psuc {
    ps fu -u "$1" --cumulative
}

function setPrompt {
    echo -n -e "\033]0;$@\007"
}

function grim {
    vim $(grep -R --binary-files=without-match "$@" . | awk -F: '{sub(/ /, "\\ "); print $1}' | sort -u)
}

if [[ "$-" =~ 'i' ]]; then

    [ $(uname) = 'Darwin' ] && {
        alias ls="ls -G"
    } || {
        alias ls="ls --color=auto"
    } 

    if [ $UID -eq 0 ]; then
        alias l="ls -la"
        export PS1="\[\033[1;37m\][\[\033[1;33m\]\h \[\033[1;34m\]\w\[\033[1;37m\]]#\[\033[0m\] "
    else
        export PS1="\[\033[1;37m\][\[\033[1;31m\]\h \[\033[1;34m\]\w\[\033[1;37m\]]\$\[\033[0m\] "
        alias l="ls -l"
    fi

    alias grep="grep --color=auto"
    alias jdiff="diff -yb --suppress-common-lines"
    alias ssh='ssh -o TCPKeepAlive=yes -o ServerAliveInterval=90'
    alias swp_vim="for file in \$(find . -iname .\*.swp); do vim -r "\$file" && rm "\$file"; done"

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
    if [ -d "$HOME/.bashrc.d/" ]; then
        files=$(find "$HOME/.bashrc.d/" -maxdepth 1 -type f)
        if [ ${#files} -gt 1 ]; then
            for file in $files; do
                . "$file"
            done
        fi
    fi
fi
