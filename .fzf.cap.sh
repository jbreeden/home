# This script wraps all existing compspecs with fzf.

# HACK (copied from fzf):
# We query the device status, after running fzf, via `printf '\e[5n'`.
# The terminal reponds '\e0n' to indicate status ok.
# We bind this to redraw the current line.
# https://www.cse.psu.edu/~kxc104/class/cmpen472/16s/hw/hw8/vt100ansi.htm
bind '"\e[0n": redraw-current-line' 2> /dev/null
function _fzf_cap_redraw_line() {
    printf '\e[5n'
}

# Processes COMPREPLY by prompting the user to select an option via fzf
function _fzf_cap_refine_compreply() {
    local ORIG_COMPREPLY=( "${COMPREPLY[@]}" )
    COMPREPLY=()
    while read -r line; do
        if [[ "$line" ]]; then
            if [[ -z "$COMPREPLY" ]]; then
                COMPREPLY="$line"
            else
                COMPREPLY="$COMPREPLY $line"
            fi
        fi
    done < <(
        printf '%s\n' "${ORIG_COMPREPLY[@]}" |
            sort |
            uniq |
            fzf -1 --height="~14" --layout=reverse "$@"
    )
}

# Usage: _fzf_cap [(-F|-C) <original_completer>] <opt_string> [...<args>]
#
# <args> should be passed in as with 'complete -F'.
#
# todo: process complete -o & -A options.
function _fzf_cap() {
    local mode="$1"; shift
    COMPREPLY=()

    case "$mode" in
        -F)
            local func="$1"; shift
            local opts="$1"; shift
            "$func" "$@"
            ;;
        -C)
            local cmd="$1"; shift
            local opts="$1"; shift
            while read -r line; do
                [[ "$line" ]] && COMPREPLY+=( "$line" )
            done < <( "$cmd" "$@" )
            ;;
        *)
            opts="$mode"
            ;;
    esac

    if [[ "${#COMPREPLY}" == 0 ]]; then
        while read -r line; do
            [[ "$line" ]] && COMPREPLY+=( "$line" )
        done < <( compgen $opts "$2" )
    fi

    if [[ "${#COMPREPLY}" == 0 ]]; then
        return 0
    fi

    _fzf_cap_refine_compreply
    _fzf_cap_redraw_line
}

. <(complete -p | awk '$0 !~ /\s(-E|-I)/{
  command = $NF
  mode = ""
  completer = ""
  complete_opts = ""

  for (f=2; f<NF; f++) {
    if ($f == "-F" || $f == "-C") {
      mode = $f
      completer = $(f+1)
      f++
      continue
    }

    complete_opts = complete_opts " " $f
  }

  print "function _fzf_cap_" command  "() { _fzf_cap " mode " " completer " \"" complete_opts "\" \"$@\"; }"
  print "complete -F _fzf_cap_" command " " command
}')

function _fzf_cap-I() {
    COMPREPLY=()
    while read -r line; do
        [[ "$line" ]] && COMPREPLY+=( "$line" )
    done < <( compgen -A command -A builtin -A function | grep -v '^[-_.:!]' | fgrep "$2" )
    _fzf_cap_refine_compreply -q "$2"
    _fzf_cap_redraw_line
}

complete -I -F _fzf_cap-I
