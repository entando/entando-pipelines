#!/bin/bash

# Setups the enviroment for a macro execution
#
# Params:
# $1 macro name
# $2 pipeline context to parse
#
# shellcheck disable=SC2034
START_MACRO() {
  local defaultMacroName="$1"; shift
  set +e

  ${ENTANDO_OPT_STEP_DEBUG:-false} && {
    set -x
  }
  
  ARGS_FLAGS=(--no-skip)
  PARSE_ARGS "$@"
  
  local noSkip
  _get_arg noSkip --no-skip
  
  EE_CURRENT_MACRO="${ARGS_OPT[--id]}"
  [ -z "$EE_CURRENT_MACRO" ] && EE_CURRENT_MACRO="$defaultMacroName"
  EE_LOCAL_CLONE_DIR="${ARGS_OPT[--lcd]}"
  EE_TOKEN_OVERRIDE="${ARGS_OPT[--token]}"
  
  if [ "${EE_CURRENT_MACRO:0:1}" = "@" ]; then
    EE_CURRENT_MACRO_PREFIX="@"
    EE_CURRENT_MACRO="${EE_CURRENT_MACRO:1}"
    local comment="user macro "
  fi

  if _log_on_level DEBUG; then
    echo -e "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~~ ${comment}${EE_CURRENT_MACRO} invoked on $(date +'%Y-%m-%d %H-%M-%S')"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    _log_i "~~ ${comment}${EE_CURRENT_MACRO} invoked"
  fi

  TEST__EXECUTION="${TEST__EXECUTION:-false}"
  if [ "$ENTANDO_OPT_SUDO" != "-" ]; then
    ENTANDO_OPT_SUDO="${ENTANDO_OPT_SUDO:-"sudo"}"
  else
    ENTANDO_OPT_SUDO=""
  fi
  ENTANDO_OPT_LOG_LEVEL="${ENTANDO_OPT_LOG_LEVEL:-INFO}"
  ENTANDO_OPT_REPO_BOM_URL="${ENTANDO_OPT_REPO_BOM_URL}"
  ENTANDO_OPT_REPO_BOM_MAIN_BRANCH="${ENTANDO_OPT_REPO_BOM_MAIN_BRANCH:-develop}"
  ENTANDO_OPT_LOG_LEVEL=TRACE
  _ppl-load-context "$PPL_CONTEXT"

  #_pp EE_CLONE_URL ENTANDO_OPT_REPO_BOM_URL EE_HEAD_REF
  _ppl-pr-has-label "skip-${EE_CURRENT_MACRO,,}" && {
    if "$noSkip"; then
      return 101
    else
      _EXIT "$EE_CURRENT_MACRO skipped due to skip-label: \"skip-${EE_CURRENT_MACRO,,}\""
    fi
  }
}

# Stops the execution with success result and a message
#
# Params:
# $1  message
#
_EXIT() {
  _log_i "$@"
  exit 0
}

# Stops the execution with a fatal error
# and optionally prints the callstack
#
# Options
# [-s]  simple: omits the stacktrace
# [-S n] skips n levels of the call stack
# [-99] uses 99 as exit code, which indicates test assertion
#
# Params:
# $1  error message
#
_FATAL() {
  local rv=77
  if [ "$1" != "-s" ]; then
    SKIP=1;[ "$1" = "-S" ] && { SKIP="$2"; shift 2; }
    [ "$1" = "-99" ] && shift && rv=99
    LOGGER() { _log_e "$*" 1>&2; }
    _print_callstack "$SKIP" 5 "" LOGGER "$@" 1>&2
  else
    shift
    [ "$1" = "-99" ] && shift && rv=99
    _log_e "$@" 1>&2
  fi

  exit "$rv"
}

# STOP ON ERROR
#
_SOE() {
  local R="$?"
  [ -n "$1" ] && _log_e "$1 didn't complete properly"
  [ "$R" != 0 ] && exit "$R"
}

# Sets a variable
#
# Params:
# - $1: variable to set
# - $2: value
_set_var() {
  [ -z "$1" ] && _FATAL "null var_name provided"
  if [ -z "$2" ]; then
    read -r -d '' "$1" <<< ""
  else
    read -r -d '' "$1" <<< "$2"
  fi
  return 0
}
