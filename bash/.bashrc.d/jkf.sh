function setPrompt {
    echo -n -e "\033]0;$@\007"
}

function grim {
    local query="$1"; shift
    local path="${1:-.}"; shift
    # We capture the files in an array first so we can use IFS to split on
    # newlines. Shame on you if your files have newlines in the names.
    local -a files
    IFS=$'\n' files=(
        $(
            grep -Ri --binary-files=without-match "$query" "$path" \
            | awk -F: '{print $1}' \
            | sort -u
        )
    )
    [ ${#files[@]} -eq 0 ] && {
        echo "No files in path '$path' matched '$query'" >&2
        return 1
    }
    vim "$@" -c "/$query" "${files[@]}"
}


git() {
    if [ $# -gt 0 -a "$1" = commit ]; then
        grep -qR \
            --include="*.py" \
            "import pdb; pdb\.set_trace\(\)" \
            "$(/usr/bin/git rev-parse --show-toplevel)" \
            && {
                echo -e "\033[1;31m***JKF PDB FAIL***\033[0m" >&2
                return 1
            }
    fi
    /usr/bin/git "$@"
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
export PS1="\[\033[1;30m# [\033[0;37m\$(echo \$?)\033[1;30m|\$(date)]\n\[\033[1;37m\][\[$host_clr\]\h \[\033[1;34m\]\w\[\033[1;37m\]]$shell_sym\[\033[0m\] "
unset shell_sym host_clr

alias grep="grep --color=auto"
alias jdiff="diff -yb --suppress-common-lines"
alias ssh='ssh -o TCPKeepAlive=yes -o ServerAliveInterval=90'
alias doco="docker compose"

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
export EDITOR=nvim
export VISUAL=nvim

unset PROMPT_COMMAND
setPrompt "${HOSTNAME%%.*}"
