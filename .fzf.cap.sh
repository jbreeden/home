# This script wraps all existing compspecs with fzf.

FZF_CAP_DEFAULT_OPTS="-0 -1 --height=~80% --layout=reverse"

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
        # TODO: SPECIAL CASE FOR COBRA COMMANDS.
        # They add description output when there are multiple matches,
        # and omit them when there is only one match so the completion
        # works as expected. Since we're refining the list with fzf
        # we need to strip the description.
        #
        # This should probably be an option on a per-command basis,
        # rather than a global default. This works for now, and in practice
        # I don't expect to see many false positives. The description must
        # be preceded by 2 spaces and enclosed in parens to match this regexp.
        # We could further validate that all elements in COMPREPLY fit this
        # criteria before applying this rule, but I've foregone this so far.
        if [[ "$line" =~ (.*[^[:space:]])[[:space:]]*[[:space:]]{2}\(.*\)[[:space:]]*$ ]]; then
            line="${BASH_REMATCH[1]}"
        fi

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
            FZF_DEFAULT_OPTS="$FZF_CAP_DEFAULT_OPTS" fzf "$@"
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
        printf '\e[s'
        printf '\e[u'
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
        COMPREPLY+=( "$line" )
    done < <( compgen -A command -A builtin -A function -A file "$2")
    _fzf_cap_refine_compreply -q "$2"
    _fzf_cap_redraw_line
}

complete -o filenames -I -F _fzf_cap-I
