if [[ "$-" =~ 'i' ]]; then
	#set -o vi
		
	function rest {
		local method=''
		local api=''
		local args='{}'
		if [ $# -eq 0 ]; then
			method=get
		elif [ $# -ge 1 ]; then
			method="$1"
		fi
		method=$(echo "$method" | tr [a-z] [A-Z])
		if [ $# -ge 2 ]; then
			api="$2"
		fi
		if [ $# -ge 3 ]; then
			args="$3"
		fi
		curl -s -k -X $method \
			-H "Content-Type:application/json" \
			-H "Accept:application/json" \
			-d "$args" \
			"https://192.168.1.3:5800/$api" \
			| ~/repo/bin/json_decode
	}

	function psuc {
		ps fu -u "$1" --cumulative
	}

	function psme {
		psuc $USER
	}

	function set_prompt {
		echo -en "\e]2;$@\a"
		if [ "$TERM" == "Eterm" ]; then
			echo -en "\e]1;$@\a"
		fi
	}
	
	function fail {
		echo "$@" >&2
		exit 101
	}

	function kill_flash {
		kill $(ps auxf | grep libflash | grep -v grep | awk '{print $2}')
	}

	function home_tun {
		[ $# -eq 1 ] || {
			echo "Invalid parameters: '$@'" >&2
			echo "Usage: home_tun TUNNEL" >&2
			echo "Example: home_tun 5800/localhost/80" >&2
			return
		}
		ssh -N -p 222 wendel@jonnyb0y.name -L "$1"
	}

	function BG {
		while [ 1 ]; do
			clear
			jobs
			sleep 10
		done
	}

	function cvlc {
		/usr/bin/cvlc "$@" 2>/dev/null
	}

    alias ssh='ssh -o TCPKeepAlive=yes -o ServerAliveInterval=90'
	alias ls="ls --color=auto"
	alias grep="grep --color=auto"
	alias mailme="mail -s 'gud stuff' jonny@spamriot.com"
	alias jdiff="diff -yb --suppress-common-lines"
	alias duhm="du -h --max-depth=1"
	alias swp_vim="for file in \$(find -iname .\*.swp); do vim -r "\$file" && rm "\$file"; done"
	alias jscc="java -jar $HOME/repo/bin/compiler.jar"

	if grep -q repo /proc/mounts; then
		alias core='ssh -i ~/repo/memory/jkf-3-17-12b wendel@192.168.1.3 -o TCPKeepAlive=yes -o ServerAliveInterval=90'
	else
		if [ "$HOSTNAME" != 'core' ]; then
			alias core='ssh -i ~/repo/memory/jkf-3-17-12b wendel@jonnyb0y.name -p 222 -o TCPKeepAlive=yes -o ServerAliveInterval=90'
		fi
	fi
	alias bridge='ssh -i ~/repo/work/keys/jkf-4-9-12 dev_jfillmore@il-bridge.slc.westdc.net -p 8888'
	alias home='ssh -i ~/repo/memory/jkf-3-17-12b wendel@jonnyb0y.name -p 222'
	alias beefcake='ssh -i ~/repo/memory/jkf-3-17-12b jonny@192.168.1.2'
	alias sysadmin='ssh -i ~/repo/work/keys/jkf-4-9-12 dev_jfillmore@sysadmin.west-datacenter.net'
    alias chimera="ssh -i ~/repo/work/keys/jkf-3-17-12 jonny@10.1.30.80"
    alias chimera_db="ssh -i ~/repo/work/keys/jkf-3-17-12 jonny@10.1.30.2"

	# javascript checking
	function jslint() {
		local options='browser: true, nomen: false'
		local globals='$: false, jQuery:false, om:true, window: false, document: false, escape: false'
		# validate params
		[ $# -eq 1 ] || {
			echo "usage: jslint file.js" >&2
			return 1
		}
		[ -s "$1" ] || {
			echo "'$1' does not exist or contains no data." >&2
			return 1
		}
		if [ ${#options} -gt 0 ]; then
			# use a temp file that contains the options up top
			{
				echo "/*jslint $options */"
				echo "/*global $globals */"
				cat "$1"
			} > /tmp/.jslint.$$
			rhino ~/repo/bin/jslint.js /tmp/.jslint.$$
			rm /tmp/.jslint.$$
		else
			rhino ~/repo/bin/jslint.js "$1"
		fi
	}

	if [ $UID -eq 0 ]; then
		export PS1="\[\033[1;37m\][\[\033[1;33m\]\h \[\033[1;34m\]\w\[\033[1;37m\]]#\[\033[0m\] "
		alias l="ls -la"
	else
		export PS1="\[\033[1;37m\][\[\033[1;31m\]\h \[\033[1;34m\]\w\[\033[1;37m\]]$\[\033[0m\] "
		alias l="ls -l"
	fi  

	export HISTSIZE=100000
	export HISTFILE=$HOME/.bash_history
    if [ -d $HOME/scripts ]; then
        PATH="$PATH:$HOME/scripts"
    fi
    if [ -d $HOME/bin ]; then
        PATH="$PATH:$HOME/bin"
    fi
    if [ -d $HOME/repo ]; then
        PATH="$PATH:$HOME/repo/bin:$HOME/repo/apps/bin:$HOME/repo/www/omega/clients/python"
    fi
    export PATH
	#if [ "$HOSTNAME" == "core" ]; then
	#	export XMMS_PATH='tcp://192.168.1.3:5700'
	#elif [ $HOSTNAME == "jkf-pc" ]; then
	#	export XMMS_PATH='tcp://127.0.0:5700'
	#elif [ $HOSTNAME == "beefcake" ]; then
	#	export XMMS_PATH='tcp://192.168.1.2:6800'
	#fi

	export fail
	export psme
	export xm
	#unset PROMPT_COMMAND
	set_prompt "${HOSTNAME%%.*}"
fi

