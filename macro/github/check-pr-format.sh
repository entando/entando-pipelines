#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# EXECUTES PRELIMINAR CHECKS ABOUT THE CURRENT PR
#
# Business Rules:
# - The PR title must match the given format rules
#
# Params:
# $1: the folder containing the related repo/branch
# $2: the format rules to respect or nothing for the default
#
ppl--check-pr-format() {
  (
    set +e
    START_MACRO "CHECK-PR-FORMAT" "$PPL_CONTEXT"
    
    local repoFolder="$1"
    local formatRules="${2:-"${ENTANDO_OPT_PR_TITLE_FORMAT:-"SINGLE|HIERARCHICAL"}"}"
    local olFormatRules=",${formatRules//\|/,}," # conversion to itmlst
    
    _NONNULL repoFolder formatRules

    __cd "$repoFolder"
    __exist -f "pom.xml"

    local TICKET_ID_REGEX="[A-Z]{2,5}-[0-9]{1,5}"
    local REGEX_S="^${TICKET_ID_REGEX}([[:space:]]|:)"
    local REGEX_H="^${TICKET_ID_REGEX}\/${TICKET_ID_REGEX}([[:space:]]|:)"
    local prTitleIsValid=false
    
    _itmlst_contains "$olFormatRules" "ANY" && {
        prTitleIsValid=true
    }
    _itmlst_contains "$olFormatRules" "SINGLE" && {
        [[ "$EE_PR_TITLE" =~ $REGEX_S ]] && prTitleIsValid=true
    }
    _itmlst_contains "$olFormatRules" "HIERARCHICAL" && {
        [[ "$EE_PR_TITLE" =~ $REGEX_H ]] && prTitleIsValid=true
    }

    if $prTitleIsValid; then
      _log_i "Pull Request title \"$EE_PR_TITLE\" is valid"
      true
    else
      _ppl-job-update-status "$STATUSES_URL" "$CURRENT_COMMIT_ID" "failure" "Failed" "Ill-formatted PR Summary"
      _FATAL "The Pull Request title \"$EE_PR_TITLE\" violates the required format ($formatRules)"
    fi
  )
}
