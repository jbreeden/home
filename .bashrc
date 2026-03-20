#!/usr/bin/env bash

if (( "${BASHRC_ONCE:=0}" == 0 )); then
    [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

    export NODE_NO_WARNINGS=1

    export PATH="\
$HOME/bin\
:$HOME/.tools/bin\
:$HOME/go/bin\
:$HOME/.cargo/bin\
:/opt/homebrew/bin\
:/usr/local/go/bin\
:/usr/local/bin\
:${PATH}"

    export CLICOLOR=1 # For ls on BSD (so, OSX)
    export GOPATH="$HOME/go"
    export GOFLAGS=-buildvcs=false
    export EDITOR='emacs -nw'
    export HISTFILESIZE=50000
    export HISTSIZE=50000
    export HISTCONTROL=ignoreboth:erasedups

    TERMINFO_GUESS1=/usr/share/terminfo
    [ -f $TERMINFO_GUESS1 ] && export TERMINFO=$TERMINFO_GUESS1

    export BASHRC_ONCE=1
fi

# Interactive shells
if [[ "$-" == *i* ]]; then
    [[ -f ~/.secrets.sh ]] && source ~/.secrets.sh
    prompt_cmd_once=0
    function prompt_cmd()  {
        status="$?"
        PS1='\n'
        PS1+='\[$(tput bold)\]\w'

        local git_ref="$(git branch --show-current 2>/dev/null)"
        if [ -z "$git_ref" ]; then
            git_ref="$(git rev-parse --short HEAD 2>/dev/null)"
        fi
        if [ "$git_ref" ]; then
            PS1+=" \[$(tput setaf 6)\]${git_ref}\[$(tput sgr0)\]"
        fi
        if [ "$VIRTUAL_ENV" ]; then
            PS1+=" \[$(tput setaf 3)\]$(basename $(dirname "${VIRTUAL_ENV}"))/$(basename "${VIRTUAL_ENV}")\[$(tput sgr0)\]"
        fi


        PS1+='\n\[$(tput setaf $(( ${status:-0} == 0 ? 2 : 1 )) )\]❯ \[$(tput sgr0)\]'
    }

    export PROMPT_DIRTRIM=4
    export PROMPT_COMMAND=prompt_cmd

    # Note: nullglob was tempting, but breaks bash-completion,
    # such that it can't filter completions correctly.
    shopt -s \
        cmdhist \
        histappend \
        globstar \
        extglob

    alias grep="grep --color=auto"
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias less="less -R"
    alias k=kubectl

    # Common ls aliases
    alias ll='ls -l'
    alias la='ls -a'
    alias l='ls -CF'

    bind -x '"\C-xr":source ~/.bashrc'
    bind -x '"\C-xm":man "${READLINE_LINE%% *}"'

    if ! shopt -oq posix; then
	if [ -f /usr/share/bash-completion/bash_completion ]; then
	    . /usr/share/bash-completion/bash_completion
	elif [ -f /etc/bash_completion ]; then
	    . /etc/bash_completion
	fi

	if type -t brew >&/dev/null; then
            brew_completions="$(brew --prefix)/etc/bash_completion"
            if [ -f "$brew_completions" ]; then
		source "$brew_completions"
            else
		echo 'WARN: bash completions missing. Install with `brew install bash-completion`' >&2
            fi
	fi
    fi

    type kubectl &>/dev/null && source <(kubectl completion bash)
    type minikube &>/dev/null && source <(minikube completion bash)
    type helm &>/dev/null && source <(helm completion bash)
    type deno &>/dev/null && source <(deno completions bash)

    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"

    # (Installed by 'pnpm install-completions')
    # tabtab source for packages
    # uninstall by removing these lines
    [ -f ~/.config/tabtab/bash/__tabtab.bash ] && . ~/.config/tabtab/bash/__tabtab.bash || true

    [[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"
    [[ -r ~/.config/bash_completion/git-completion.bash ]] && . ~/.config/bash_completion/git-completion.bash

    # FZF things
    export FZF_DEFAULT_OPTS="--height=~50% --layout=reverse --bind=ctrl-k:kill-line,ctrl-v:page-down,alt-v:page-up"

    function _my_fzf_history () {
        READLINE_LINE="$(
          fc -rnl 1 $HISTSIZE |
             grep -Eo '\S.*' |
             uniq |
             fzf --no-sort -e -q "$READLINE_LINE"
        )"
        READLINE_POINT="${#READLINE_LINE}"
    }
    bind -x '"\C-r":_my_fzf_history'

    [[ -r ~/.fzf.cap.sh ]] && . ~/.fzf.cap.sh

    alias magit="emacs -nw -f magit-status"
    alias grep="grep --color=auto"
    alias less="less -R"
    alias t=tmux
    alias tf=terraform
    complete -F _fzf_cap_tmux t
    alias k=kubectl
    complete -F _fzf_cap_kubectl k
fi

if test -f "$HOME"/.docker/init-bash.sh; then
    source "$HOME"/.docker/init-bash.sh
fi

if test -f /home/jared/miniconda3/bin/conda; then
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
    __conda_setup="$('/home/jared/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
	eval "$__conda_setup"
    else
	if [ -f "/home/jared/miniconda3/etc/profile.d/conda.sh" ]; then
            . "/home/jared/miniconda3/etc/profile.d/conda.sh"
	else
            export PATH="/home/jared/miniconda3/bin:$PATH"
	fi
    fi
    unset __conda_setup
# <<< conda initialize <<<
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
