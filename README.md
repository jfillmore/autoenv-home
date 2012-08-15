Auto-env shell script and my preferred default resource files. Requires cURL or wget.


Download auto_env
-------------------
    mkdir ~/bin && cd ~/bin
    wget https://raw.github.com/jfillmore/auto_env/master/auto_env/bin/auto_env.sh
    chmod 755 auto_env.sh
    ./auto_env.sh --help

Examples
------------------
    # Silently sync items in background
    [ -x ~/bin/auto_env.sh ] && ~/bin/auto_env.sh -s bash vim bash webdev fluxbox home & disown -r
