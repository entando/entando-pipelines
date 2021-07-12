#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# EXECUTES PRELIMINAR CHECKS ABOUT THE CURRENT PR
#
# Business Rules:
# - The PR title must match the given format rules
#
# Params:
# $1: the label to check
#
ppl--gate-check() {
  (
    START_MACRO "GATE-CHECK" --no-skip "$@"

    if [ "$?" -eq 101 ]; then
      _ppl-set-persistent-var ENABLED false
      _ppl-job-update-status "$EE_COMMIT_ID" "skip" "Skipped" "Skipped"
      _EXIT "$EE_CURRENT_MACRO will be skipped due to skip-label: \"skip-${EE_CURRENT_MACRO,,}\"" 1>&2
    else
      _ppl-set-persistent-var ENABLED true
    fi
  )
}
