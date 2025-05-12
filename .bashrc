#!/usr/bin/env bash

export PATH="\
$HOME/bin\
:$HOME/.tools/bin\
:$HOME/.de-tools/bin\
:$HOME/.cargo/bin\
:$HOME/go/bin\
:$HOME/bin\
:/opt/homebrew/bin\
:/usr/local/go/bin\
:/usr/local/bin\
:/usr/bin\
:/usr/sbin\
:/bin\
:/sbin\
"

export AWS_PROFILE=dev

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

export CLICOLOR=1 # For ls on BSD (so, OSX)
export GOFLAGS=-buildvcs=false
export GOPATH="$HOME/go"
export GOPRIVATE="github.com/decodableco"
export EDITOR='emacs -nw'
export HISTFILESIZE=50000
export HISTSIZE=50000

TERMINFO_GUESS1=/usr/share/terminfo
[ -f $TERMINFO_GUESS1 ] && export TERMINFO=$TERMINFO_GUESS1

[ -f ~/.decodable.bashrc ] && . ~/.decodable.bashrc

# Interactive shells
if [[ "$-" == *i* ]]; then
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

    bind -x '"\C-xr":source ~/.bashrc'
    bind -x '"\C-xm":man "${READLINE_LINE%% *}"'

    if type -t brew >&/dev/null; then
        brew_completions="$(brew --prefix)/etc/bash_completion"
        if [ -f "$brew_completions" ]; then
            source "$brew_completions"
        else
            echo 'WARN: bash completions missing. Install with `brew install bash-completion`' >&2
        fi
    fi

    type kubectl &>/dev/null && source <(kubectl completion bash)
    type minikube &>/dev/null && source <(minikube completion bash)
    type helm &>/dev/null && source <(helm completion bash)
    type decodable &>/dev/null && source <(decodable completion bash)
    type de-tools &>/dev/null && source <(de-tools completion bash)
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
    complete -F _fzf_cap_decodable de
    alias da=de-admin
    alias dt=de-tools
    eval "$(complete -p de-tools | sed 's/de-tools$/dt/')"
fi

function dj() {
    worktree=$(
        cd ~/decodable/repos/decodable.d && ls -t |
            fzf -f "$*" |
            fzf -1 -q "$*" --prompt "worktree: "
    )

    if [ "$worktree" ]; then
        cd "$HOME/decodable/repos/decodable.d/$worktree"
    fi
}

# Created by `pipx` on 2025-01-14 18:05:56
export PATH="$PATH:/Users/jbreeden/.local/bin"
