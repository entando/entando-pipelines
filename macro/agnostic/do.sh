#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../base.sh"

_require "lib/shared/cli.sh"
_require "lib/local/macro.sh"
_require "lib/local/project.sh"

# PROXY FUNCTION FOR MULTI-BUILD-SYSTEM MACRO OPERATIONS
# 
# Params:
# $1: action to apply
# $*: action dependent params
#
ppl--do() {
  _cli.parse_args "" "$@"
  _cli.get_arg action 1; shift
  _cli.get_arg PPL_LOCAL_CLONE_DIR --lcd 1
  ppl.enter_local_clone_dir

  project_type="$(prj.current.determine_type)"
  
  ppl--do.safe-dynamic-invokation "$project_type" "$action"
}

ppl--do.safe-dynamic-invokation() {
  local MODULE FUNCTION
  
  # --------------------------------------------------------
  # WARNING:
  # anti-shell-injection-alert
  # ~
  # The following "routing" code is ==INTENTIONALY==
  # redundant and verbose, ==DON'T== optimize it.
  # ~
  # Don't even trust a perfect dynamic version of this code
  # as your future self, others, or the shell implementation
  # may introduce bugs or dangerous changes.
  # ~
  # --------------------------------------------------------
  
  case "$1" in
    "MVN") MODULE="mvn";;
    "NPM") MODULE="npm";;
    "ENP") MODULE="enp";;
    *) _FATAL "Unknown module \"$1\"";;
  esac
  
  case "$2" in
    "FULL-BUILD") FUNCTION="full-build";;
    "PUBLISH") FUNCTION="publish";;
    *) _FATAL "Unknown function \"$2\"";;
  esac

  shift 2 || _FATAL "Internal error"

  "macro.$MODULE.$FUNCTION" "$@"    
}
