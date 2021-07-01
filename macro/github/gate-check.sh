#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# EXECUTES PRELIMINAR CHECKS ABOUT THE CURRENT PR
#
# Business Rules:
# - The PR title must match the given format rules
#
# Params:
# $1: the id of execution
# $2: the label to check
#
ppl--gate-check() {
  (
    START_MACRO --no-skip "$1" "$PPL_CONTEXT"
    
    if [ "$?" -eq 99 ]; then
      echo "::set-output name=ENABLED::false"
      _EXIT "$1 will be skipped due to skip-label: \"skip-${1,,}\"" 1>&2
    else
      echo "::set-output name=ENABLED::true"
    fi
  )
}
