Auto-env shell script and my preferred default resource files. Requires cURL or wget.


Download auto_env
-------------------
    mkdir -p ~/scripts && cd ~/scripts
    wget --no-check-certificate \
        https://raw.githubusercontent.com/jfillmore/auto_env/master/auto_env/scripts/auto_env.sh
    chmod 755 auto_env.sh
    ./auto_env.sh --help

Examples
------------------
    # Silently sync items in background
    [ -x ~/scripts/auto_env.sh ] && \
        ~/scripts/auto_env.sh -s \
            bash vim bash webdev fluxbox home & disown -r
