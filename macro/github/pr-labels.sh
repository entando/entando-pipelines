#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# EXECUTES PRELIMINAR CHECKS ABOUT THE CURRENT PR
#
# Business Rules:
# - The PR title must match the given format rules
#
# Params:
# $1: the specific id of the macro
# $2: the action to perform (add,remove)
# $3: the label to add or delete
#
ppl--pr-labels() {
  (
    START_MACRO "$1" "$PPL_CONTEXT"
    
    local action="$2"
    local labelName="$3"
    
    _NONNULL action labelName

    case "$action" in
      "add") _ppl-pr-add-label "$EE_PR_NUM" "$labelName";;
      "remove") _ppl-pr-remove-label "$EE_PR_NUM" "$labelName";;
      *) _FATAL "Illegal action \"$action\"";;
    esac
  )
}
