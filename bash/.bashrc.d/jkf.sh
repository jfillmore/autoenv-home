function setPrompt {
    echo -n -e "\033]0;$@\007"
}

function grim {
    vim -c "/$1" $(grep -R --binary-files=without-match "$1" . | awk -F: '{sub(/ /, "\\ "); print $1}' | sort -u)
}


[ $(uname) = 'Darwin' ] && {
    alias ls="ls -G"
} || {
    alias ls="ls --color=auto"
}

if [ $UID -eq 0 ]; then
    shell_sym='#'
    host_clr='\033[1;33m'  # yellow
    alias l="ls -la"
else
    shell_sym='$'
    host_clr='\033[1;31m'  # red
    alias l="ls -l"
fi
export PS1="\[\033[1;30;40m# [\033[0;37;40m\$(echo \$?)\033[1;30;40m|\$(date)]\n\[\033[1;37m\][\[$host_clr\]\h \[\033[1;34m\]\w\[\033[1;37m\]]$shell_sym\[\033[0m\] "
unset shell_sym host_clr

alias grep="grep --color=auto"
alias jdiff="diff -yb --suppress-common-lines"
alias ssh='ssh -o TCPKeepAlive=yes -o ServerAliveInterval=90'
alias swp_vim="for file in \$(find . -iname .\*.swp); do vim -r "\$file" && rm "\$file"; done"
alias doco=docker-compose

which nvim &>/dev/null && {
    alias vi=nvim
    alias vim=nvim
}

if [ -d $HOME/scripts ]; then
    PATH="$PATH:$HOME/scripts"
fi
if [ -d $HOME/bin ]; then
    PATH="$PATH:$HOME/bin"
fi

export PATH
export HISTSIZE=100000
export EDITOR=vim

unset PROMPT_COMMAND
setPrompt "${HOSTNAME%%.*}"
