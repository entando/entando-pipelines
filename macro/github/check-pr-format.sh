#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# EXECUTES PRELIMINAR CHECKS ABOUT THE CURRENT PR
#
# Business Rules:
# - The PR title must match the given format rules
#
# Params:
# $1: the format rules to respect or nothing for the default
#
ppl--check-pr-format() {
  (
    START_MACRO "CHECK-PR-FORMAT" "$@"
    
    __ppl_enter_local_clone_dir
    __exist -f "pom.xml"
    
    ppl--check-pr-format.CHECK_TITLE_FORMAT
    ppl--check-pr-format.CHECK_PROJECT_VERSION_FORMAT
  )
}

ppl--check-pr-format.CHECK_PROJECT_VERSION_FORMAT() {
  _pkg_get "xmlstarlet" -c "xmlstarlet"

  # shellcheck disable=SC2034
  local projectVersion
  _pom_get_project_version projectVersion "pom.xml"
  
  if [[ "$projectVersion" =~ .*-SNAPSHOT ]]; then
    _log_i "Project version number is a snapshot as request"
  else
    _ppl-job-update-status "$EE_COMMIT_ID" "failure" "Failed" "Invalid project version"
    _FATAL "The project version \"$projectVersion\" is not a snapshot"
  fi
}

ppl--check-pr-format.CHECK_TITLE_FORMAT() {
  local formatRules
  _get_arg formatRules 1 "${ENTANDO_OPT_PR_TITLE_FORMAT:-"SINGLE|HIERARCHICAL"}"
  _NONNULL formatRules

  local olFormatRules=",${formatRules//\|/,}," # conversion to itmlst

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
    _ppl-job-update-status "$EE_COMMIT_ID" "failure" "Failed" "Ill-formatted PR title"
    _FATAL "The Pull Request title \"$EE_PR_TITLE\" violates the required format ($formatRules)"
  fi
}
