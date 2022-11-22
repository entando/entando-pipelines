#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# PROXY FUNCTION FOR MULTI-BUILD-SYSTEM MACRO OPERATIONS
# 
# Params:
# $1: action to apply
# $*: action dependent params
#
ppl--do() {
  START_MACRO "BUILD" "$@"
  _get_arg action 1; shift
  __ppl_enter_local_clone_dir

  project_type="$(__ppl_determine_current_project_type)"
  
  macro.build.safe-dynamic-invokation "$action" "$project_type"
}


macro.build.safe-dynamic-invokation() {
  local MODULE FUNCTION
  
  # --------------------------------------------------------
  # WARNING:
  # anti-shell-injection-caution
  # ~
  # The following "routing" code is ==INTENTIONALY==
  # redundant and verbose, ==DON'T== optimize it.
  # ~
  # Don't even trust a perfect dynamic version of this code
  # as your future self, others, or the shell implementation
  # may introduce bugs or dangerous changes.
  # ~
  # --------------------------------------------------------
  
  case "$1":
    "MVN") MODULE="mvn";;
    "NPM") MODULE="npm";;
    "ENP") MODULE="enp";;
    *) _FATAL "Unknown module \"$1\""
  esac
  
  case "$2" in
    "FULL-BUILD") FUNCTION="full-build"
    "PUBLISH") FUNCTION="publish"
    *) _FATAL "Unknown function \"$2\""
  esac

  shift 2 || _FATAL "Internal error"

  "macro.$MODULE.$FUNCTION" "$@"    
}
