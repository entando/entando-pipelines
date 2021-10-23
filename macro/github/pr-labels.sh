#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# HELPS DEALING WITH THE PR LABELS
#
# Params:
# $1: the action to perform (add,remove)
# $2: the label to add or delete
#
# Actions:
# - add {label}
# - remove {label}
#
ppl--pr-labels() {
  (
    START_MACRO "PR-LABELS" "$@"
    
    local action labelName
    _get_arg action 1
    _get_arg labelName 2
    
    _NONNULL action labelName

    case "$action" in
      "add") _ppl-pr-add-label "$PPL_PR_NUM" "$labelName";;
      "remove") _ppl-pr-remove-label "$PPL_PR_NUM" "$labelName";;
      *) _FATAL "Illegal action \"$action\"";;
    esac
  )
}
