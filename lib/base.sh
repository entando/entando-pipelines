#!/bin/bash

# shellcheck disable=SC2034
BASE.init_default_vars() {
  ENTANDO_PIPELINE=true
  if [ -n "$GITHUB_ACTIONS" ]; then
    export ENTANDO_IN_REAL_PIPELINE=true
  else
    export ENTANDO_IN_REAL_PIPELINE=false
  fi
  ENTANDO_DEFAULT_DOCKER_ORG="entando"
  ENTANDO_OPERATOR_POD_NAME_PATTERN="^entando-operator-.*"
  ENTANDO_OPERATOR_STARTUP_TIMEOUT="60"
  # SNYK
  ENTANDO_SNYK_LOCAL_FILE="./.snyk"
}

# Setups the enviroment for a macro execution
#
# Params:
# $1   macro name
# $..  macro-specific parameters
#
# shellcheck disable=SC2034
START_MACRO() {
  # BASICS
  
  START_SIMPLE_MACRO --full "$@"

  # FEATURES
  _itmlst_from_string PPL_FEATURES "${ENTANDO_OPT_FEATURES}"
  _ppl_is_feature_enabled "INHERIT-GLOBAL-FEATURES" true && {
    _itmlst_from_string PPL_FEATURES "${ENTANDO_OPT_GLOBAL_FEATURES},${ENTANDO_OPT_FEATURES}"
  }

  _ppl_is_feature_enabled "$PPL_CURRENT_MACRO" true || {
    _EXIT "Macro of id \"$PPL_CURRENT_MACRO\" is not enabled"
  }
}

START_SIMPLE_MACRO() {
  set +e
  
  local FULL=false;[ "$1" == "--full" ] && { FULL=true;shift; }

  if [[ "$ENTANDO_OPT_STEP_DEBUG" = "true" || "$ENTANDO_OPT_STEP_DEBUG" = "###true" ]]; then
    sys_trace_ctl enable
  fi
  
  # shellcheck disable=SC2034
  ARGS_FLAGS=(--no-skip --no-repo)
  PARSE_ARGS "$@"
  
  # shellcheck disable=SC2034
  local noSkip defaultMacroName=""
  _get_arg defaultMacroName 1
  _shift_positional_args 1
  _get_arg noSkip --no-skip
  _get_arg PPL_CURRENT_MACRO --id "$defaultMacroName"
  _get_arg PPL_NO_REPO --no-repo
  
  _get_arg PPL_LOCAL_CLONE_DIR --lcd
  _get_arg PPL_TOKEN_OVERRIDE --token
  _get_arg PPL_OUTPUT_FILE --out

  _pp PPL_CURRENT_MACRO FULL PPL_NO_REPO 1>&2
  
  $FULL && {
    if _log_on_level DEBUG; then
      echo -e "\n▒▒▒" 1>&2
      echo "▒▒▒ ${comment}${PPL_CURRENT_MACRO} invoked on $(date +'%Y-%m-%d %H-%M-%S')" 1>&2
      echo -e "▒▒▒\n" 1>&2
    else
      _log_i "~~ ${comment}${PPL_CURRENT_MACRO} invoked" 1>&2
    fi

    # PIPELINES CONTEXT
    _ppl-load-context "$PPL_CONTEXT"
    
    # PARTIAL INFO ABOUT THE CURRENT BRANCHING
    _ppl_determine_branch_info
      
    # READS CONFIGURATIONS FROM THE DATA REPO
    _ppl_clone_and_configure_data_repo
  }

  _load_entando_opts
  
  if [ "${PPL_CURRENT_MACRO:0:1}" = "@" ]; then
    # shellcheck disable=SC2034
    PPL_CURRENT_MACRO_PREFIX="@"
    PPL_CURRENT_MACRO="${PPL_CURRENT_MACRO:1}"
    local comment="user macro "
  fi

  # MISC
  TEST__EXECUTION="${TEST__EXECUTION:-false}"
  
  if [ "$ENTANDO_OPT_SUDO" != "-" ]; then
    ENTANDO_OPT_SUDO="${ENTANDO_OPT_SUDO:-"sudo"}"
  else
    ENTANDO_OPT_SUDO=""
  fi

  # LOG LEVEL
  ENTANDO_OPT_LOG_LEVEL="${ENTANDO_OPT_LOG_LEVEL:-INFO}"
}

# Stops the execution with a success result and an info message
#
# Params:
# $1  message
#
# Options:
# -d logs using _log_d instead of _log_i
#
_EXIT() {
  if [ "$1" = "-d" ]; then
    shift
    _log_d "$@"
  else
    _log_i "$@"
  fi
  _exit 0
}

# Stops the execution with a fatal error
# and prints the callstack
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
  set +x
  local rv=77
  sys_trace_ctl disable

  {
    # shellcheck disable=SC2076
    if [[ -n "$TEST__EXPECTED_ERROR" && "$*" =~ "$TEST__EXPECTED_ERROR" ]]; then
      LOGGER() { _log_d "==== EXPECTED ERROR DETECTED ====: $*" 1>&2; }
    else
      LOGGER() { _log_e "$*" 1>&2; }
    fi

    if [ "$1" != "-s" ]; then
      SKIP=1;[ "$1" = "-S" ] && { SKIP="$((SKIP+$2))"; shift 2; }
      [ "$1" = "-99" ] && shift && rv=99
      _print_callstack "$SKIP" 5 "" LOGGER "$@"  1>&2
    else
      shift
      [ "$1" = "-99" ] && shift && rv=99
      LOGGER "$@"
    fi
  }

  _exit "$rv"
}

_LOW_LEVEL_FATAL() {
  if [[ -n "$TEST__EXPECTED_ERROR" && "$*" =~ $TEST__EXPECTED_ERROR ]]; then
    LOGGER() { _log_d "==== EXPECTED ERROR DETECTED ====: $*"; }
  else
    LOGGER() { _log_e "$*" 1>&2; }
  fi
  LOGGER "$*" 1>&2
  _print_callstack "$SKIP" 5 "" LOGGER "$@" 1>&2
  _exit 66
}

# STOP ON ERROR
#
# Options:
# --pipe N  checks the result of the part #N of a pipe expression
#
_SOE() {
  local R="$?" PPS=("${PIPESTATUS[@]}")
  [ "$1" == "--pipe" ] && { shift; R="${PPS[$1]}"; shift; }
  [ "$R" = 0 ] && return 0
  exit "$R"
}

# Sets a variable given the name and the value
#
# WARNING:
# This function can be used to set a variable of the caller's scope and this tecnique
# is commonly used to return values to the caller.
# But note that if there is a variable with same name in the local scope, the local one
# is preferred leaving the caller's variable untouched.
# That's why functions that returns values uses a special naming convention for their
# internal variables (_tmp_...).
#
# Params:
# - $1: variable to set
# - $2: value
#
_set_var() {
  [ -z "$1" ] && _LOW_LEVEL_FATAL "null var_name provided"
  _is_valid_var_name "$1" || _LOW_LEVEL_FATAL "invalid var_name \"$1\" provided"
  if [ -z "$2" ]; then
    read -r -d '' "$1" <<< ""
  else
    read -r -d '' "$1" <<< "$2"
  fi

  return 0
}

_is_valid_var_name() {
  # shellcheck disable=SC2234
  ([[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]])  # NOTE: the subshell restricts the side effects, don't remove it
}

_exit() {
  if [ "$ENTANDO_OPT_STOP_ON_EXIT" == "true" ]; then
    kill -INT $$
  else
    exit "$@"
  fi
}

# Executes a command in an expty enviroment
#
_exec_with_empty_env() {
  env -i "$@"
}

__assert_valid_identifier() {
  local N V i=1 P="$1"; shift
  while [ $# -gt 0 ]; do
    N="$1";V="$2";shift 2;
    # shellcheck disable=SC2234
    ([[ "$V" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]) || { # NOTE: the subshell restricts the side effects, don't remove it
      _FATAL "Invalid identifier detected in argument \"$N\" of procedure \"$P\""
    }
  done
}
