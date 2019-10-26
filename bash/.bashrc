# system bashrc
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# local customizations for interative terminals
if [[ "$-" =~ 'i' ]]; then
    if [ -f "$HOME/.bashrc.local" ]; then
        . "$HOME/.bashrc.local"
    fi
    if [ -d "$HOME/.bashrc.d/" ]; then
        __files=$(find "$HOME/.bashrc.d" -maxdepth 1 \( -type f -o -type l \) \! -name .\*)
        if [ ${#__files} -ge 1 ]; then
            for __file in $__files; do
                . "$__file"
            done
        fi
        unset __files
        unset __file
    fi
fi
