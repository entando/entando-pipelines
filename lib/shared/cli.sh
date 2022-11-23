#/bin/bash

_require "lib/shared/log.sh"
_require "lib/shared/sys.sh"
_require "lib/shared/vars.sh"

# Program Arguments Parser
# 
# Parses argumets array for positional and optional arguments
# and sends the result to _CLI_ARGS_POS (array) and _CLI_ARGS_OPT (map)
#
# Params:
# $1  which optional aruments are just flags (space separed list)
# $.. arguments to parse
#
# See also:
# - _cli.get_arg
# - _cli.test.parse_args
#
_cli.parse_args() {
  local flags="$1"
  shift
  
  [ -z "$1" ] && _sys.fatal "No argument to parse was provided"
  
  local K
  local eoo=false
  local cli_args_flags=()

  _CLI_ARGS_POS=("")
  _CLI_ARGS_POS_SHIFT=0
  unset _CLI_ARGS_OPT
  declare -A -g _CLI_ARGS_OPT
  
  while read -r -d ' ' flag; do
    [ -n "$flag" ] && {
      cli_args_flags+=("$flag")
      _CLI_ARGS_OPT["$flag"]=false
    }
  done <<<"${flags} "
  
  while [[ $# -gt 0 ]]; do
    K="$1"

    if ! $eoo; then
      case "$K" in
        --)
          eoo=true
          shift
          continue
          ;;
        --*|-*)
          shift
          #~ FLAGS..
          if [[ " ${cli_args_flags[*]} " == *" ${K} "* ]]; then
            #.. NORMAL FLAG
            _CLI_ARGS_OPT["$K"]=true
            continue
          fi          
          if [[ " --no-${cli_args_flags[*]} " == *" --no-${K} "* ]]; then
            #.. FLAGS NEGATION
            _CLI_ARGS_OPT["$K"]=false
            continue
          fi

          #~ ASSIGNMENTS..
          #~ .. --OPT=A-VAL
          IFS='=' read -r KK VV <<< "$K"
          if [[ -n "$VV" ]]; then
            _CLI_ARGS_OPT["$KK"]="$VV"
            continue
          fi
          #~ .. --OPT --NOT-A-VAL
          if [[ "${1:0:1}" = "-" && "${1:0:2}" != "-" ]]; then
            _log.w "Detected undeclared flag \"$1\""
            shift
            continue
          fi
          #~ .. --OPT A-VAL
          _CLI_ARGS_OPT["$K"]="$1"
          shift
          continue
          ;;
      esac
    fi
    
    _CLI_ARGS_POS+=("$1")
    shift
  done
}

# Extracts a positional or optional argument from the arguments passed to "PARSE_ARGS"
#
# Params:
# $1 the receiver var
# $2 the option name (prefix: "-" or "--") or the index of the positional argument (a number >= 1)
# $3 the fallback value
#
# Options:
# [-m] if specified the function fails if no value can be extracted from argument or fallback
# [-p] if specified the receiver var is not affected if no value can be extracted from argument or fallback
# [-e] if specified the receiver var is also exported
#
# Examples:
# _cli.get_arg arg1 1           # sets the var "arg1" with the first positional argument
# _cli.get_arg the_mode --mode  # sets the var "the_mode" with the optional argument "--mode"
#
_cli.get_arg() {
  local MANDATORY=false;[ "$1" = "-m" ] && { MANDATORY=true; shift; }
  local PRESERVE=false;[ "$1" = "-p" ] && { PRESERVE=true; shift; }
  local EXPORT=false;[ "$1" = "-e" ] && { EXPORT=true; shift; }
  local _tmp_
  case "$2" in
    ''|*[!0-9]*) _tmp_="${_CLI_ARGS_OPT[$2]}";;
    *) _tmp_="${_CLI_ARGS_POS[$((_CLI_ARGS_POS_SHIFT+$2))]}";;
  esac
  _tmp_="${_tmp_:-$3}"
  [ -n "${_tmp_}" ] || { "$MANDATORY" && _sys.fatal -S 1 "No value or fallback available for mandatory param \"$2\" ($1)" ; }
  $PRESERVE && [ -z "${_tmp_:-$3}" ] && return 1
  _vars.set_var "$1" "$_tmp_"
  [ -z "${_tmp_:-$3}" ] && return 1
  # shellcheck disable=SC2163
  $EXPORT && export "$1"
  return 0
}

# Shifts left the positional arguments of the given number of positions (equivalent of bash "shift")
# Doesn't affect the optional arguments
# 
_cli.shift_positional_args() {
  ((_CLI_ARGS_POS_SHIFT+=$1))
}
