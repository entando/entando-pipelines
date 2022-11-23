#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../base.sh"

_require "lib/shared/cli.sh"
_require "lib/shared/vars.sh"
_require "lib/local/macro.sh"
_require "lib/local/project.sh"

# PROXY FUNCTION FOR MULTI-BUILD-SYSTEM MACRO OPERATIONS
# 
# Params:
# $1: action to apply
# $*: action dependent params
#
macro.do.run() {
  _cli.parse_args "" "$@"
  _cli.get_arg action 1; shift
  _cli.get_arg PPL_LOCAL_CLONE_DIR --lcd 1
  ppl.enter_local_clone_dir

  project_type="$(prj.current.determine_type)"
  _NONNULL project_type

  local AUTH=( "macro.mvn.full-build" )
  macro.do.safe-dynamic-invokation AUTH "$project_type" "$action"
}

# ----------------------------------------------------------------------------------------------------------------------
# SUBORDINATE FUNCTIONS
#

macro.do.safe-dynamic-invokation() {
  local AUTHVAR="$1" MODULE="$2" FUNCTION="$3"
  shift 3 || _FATAL "Internal error"

  local spec="$MODULE.$FUNCTION"
  local fn="$(tr [:upper:] [:lower:] <<< "macro.$spec")"
  
  local arrname="$AUTHVAR[@]"
  _vars.array.contains "$fn" "${!arrname}" || _FATAL "Unautorized call \"$spec\""
  type "$fn" &>/dev/null || _FATAL "Unable to find the implementation of call \"$spec\""

  "$fn" "$@"
}
