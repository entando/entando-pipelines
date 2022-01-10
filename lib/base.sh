#!/bin/bash


BASE.init_default_vars() {
  # shellcheck disable=SC2034
  ENTANDO_DEFAULT_DOCKER_ORG="entando"
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
  START_SIMPLE_MACRO "$@"
  
  # PIPELINES CONTEXT
  _ppl-load-context "$PPL_CONTEXT"
  
  # INFO ABOUT THE CURRENT BRANCHING
  _ppl_determine_branch_info
  
  # FEATURES
  _itmlst_from_string PPL_FEATURES "${ENTANDO_OPT_FEATURES}"
  _ppl_is_feature_enabled "INHERIT-GLOBAL-FEATURES" true && {
    _itmlst_from_string PPL_FEATURES "${ENTANDO_OPT_GLOBAL_FEATURES},${ENTANDO_OPT_FEATURES}"
  }

  _ppl_is_feature_enabled "$PPL_CURRENT_MACRO" true || {
    _EXIT "Macro of id \"$PPL_CURRENT_MACRO\" is not enabled"
  }
  
  # CUSTOM ENVIRONMENT
  _ppl_load_settings "$ENTANDO_OPT_CUSTOM_ENV"
  
  # ..
  if _log_on_level DEBUG; then
    echo -e "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~~ ${comment}${PPL_CURRENT_MACRO} invoked on $(date +'%Y-%m-%d %H-%M-%S')"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    _log_i "~~ ${comment}${PPL_CURRENT_MACRO} invoked"
  fi
}

START_SIMPLE_MACRO() {
  set +e
  
  _auto_decode_entando_opts
  
  ${ENTANDO_OPT_STEP_DEBUG:-false} && {
    #export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    export PS4='\033[0;33m+[${SECONDS}][${BASH_SOURCE}:${LINENO}]:\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    set -x
  }

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

  ENTANDO_OPT_REPO_BOM_URL="${ENTANDO_OPT_REPO_BOM_URL}"

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
  local rv=77

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
# --pipe N  checks the result of the part #N of a pipe expression, can be specified up to 3 times
#
_SOE() {
  local R="$?"
  [[ "$1" == "--pipe" ]] && { R="${PIPESTATUS["$2"]}"; shift 2; }
  [[ "$R" = "0" && "$1" == "--pipe" ]] && { R="${PIPESTATUS["$2"]}"; shift 2; }
  [[ "$R" = "0" && "$1" == "--pipe" ]] && { R="${PIPESTATUS["$2"]}"; shift 2; }
  [ -n "$1" ] && _log_e "$1 didn't complete properly"
  [ "$R" != 0 ] && _exit "$R"
  return "$R"
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
