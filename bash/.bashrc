# .bashrc

# always load some common defaults
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi
if [ -f "$HOME/.bashrc.local" ]; then
    . "$HOME/.bashrc.local"
fi

# only load the extras if we're an interactive shell
if [[ "$-" =~ 'i' ]]; then
    if [ -d "$HOME/.bashrc.d/" ]; then
        for __file in "$HOME"/.bashrc.d/*; do
            # if no files exist this returns the un-globbed string
            # also, just ignore empty stuff
            if [ -s "$__file" ]; then
                . "$__file"
            fi
        done
    fi
fi
