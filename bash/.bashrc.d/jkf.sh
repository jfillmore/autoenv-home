setPrompt() {
    echo -n -e "\033]0;$@\007"
}


_cmd() {
    echo -e "\033[0;33;40m# $(printf "'%s' " "$@")\033[0;0m" >&2
    "$@"
}


grim() {
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
    nvim "$@" -c "/$query" "${files[@]}"
}


git() {
    if [ $# -gt 0 -a "$1" = commit ]; then
        grep -R \
            --include="*.py" \
            --exclude-dir=".git" \
            --exclude-dir="venv" \
            --exclude-dir=".venv" \
            "import pdb; pdb\.set_trace\(\)" \
            "$(/usr/bin/git rev-parse --show-toplevel)" \
            && {
                echo -e "\033[1;31m***JKF PDB FAIL***\033[0m" >&2
                return 1
            }
    fi
    /usr/bin/git "$@"
}


# Ensure we're in the same dir as our yml file so .env files are always found
doco() {
    (
        while true; do
            [ -f docker-compose.yml -o -f docker-compose.yaml ] && break
            [ "$PWD" = "/" ] && {
                echo "No docker-compose.yml found in any parent dir" >&2
                exit 1
            }
            cd ..
        done
        docker compose "$@"
    )
}


# $1 = service name
# $2..$n = extra docker compose commands to run on the service before starting
doco-loop() {
    local svc="$1"; shift
    _cmd docker compose stop "$svc"
    _cmd docker compose rm -f "$svc"
    while [ $# -gt 0 ]; do
        _cmd docker compose "$1" "$svc" || {
            echo "Command 'docker compose $1 $svc' failed"
            return 1
        }
        shift
    done
    _cmd docker compose up -d "$svc"
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
