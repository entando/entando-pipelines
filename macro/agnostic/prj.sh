#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../base.sh"

_require "lib/local/macro.sh"
_require "lib/local/project.sh"

# PROXY FUNCTION FOR MULTI-BUILD-SYSTEM MACRO OPERATIONS
# 
# Params:
# $1: action to apply
# $*: action dependent params
#
macro.prj.run() {
  (
    ppl.start_macro "${FUNCNAME[0]}" --enter-local-clone "$@"
    
    local MACRO_PRJ_RUN_AUTH=(
      "macro.mvn.full-build" 
    )
    
    ppl.safe-dynamic-invokation MACRO_PRJ_RUN_AUTH "$PPL_PROJECT_TYPE" "$PPL_ACTION"
  )
}
