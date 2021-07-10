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
    _pkg_get "xmlstarlet" -c "xmlstarlet"
    
    __ppl_enter_local_clone_dir
    __exist -f "pom.xml"
    
    local projectVersion
    _pom_get_project_version projectVersion "pom.xml"
    
    ppl--check-pr-format.CHECK_TITLE_FORMAT
    ppl--check-pr-format.CHECK_MAINLINE "$projectVersion"
    ppl--check-pr-format.CHECK_PROJECT_VERSION_FORMAT "$projectVersion"
  )
}

ppl--check-pr-format.CHECK_MAINLINE() {
  if [ -z "${ENTANDO_OPT_MAINLINE}" ]; then
    _leg_d "Mainline check is not enabled"
    return 0
  fi
  
  local projectVersion="$1" mMaj mMin maj min
  _semver_parse mMaj mMin "" "" "${ENTANDO_OPT_MAINLINE}"
  _semver_parse maj min "" "" "${projectVersion}"
  
  _pp projectVersion mMaj mMin maj min
  
  if [ "$mMaj" != "$maj" ] || [ "$mMin" != "$min" ]; then
    if [ "${EE_REF_NAME:0:8}" != "release/" ]; then
      _ppl-job-update-status "$EE_COMMIT_ID" "failure" "Failed" "Invalid project version (incompatible with mainline)"
      _FATAL "In non-release branches the project version (\"$projectVersion\") must be compatible with the current mainline: \"${ENTANDO_OPT_MAINLINE}\""
    fi
  fi
}

ppl--check-pr-format.CHECK_PROJECT_VERSION_FORMAT() {
  local projectVersion="$1" 
  
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
  
  local currentPrTitle
  _ppl-query-pr-info currentPrTitle title
  
  _itmlst_contains "$olFormatRules" "SINGLE" && {
      [[ "$currentPrTitle" =~ $REGEX_S ]] && prTitleIsValid=true
  }
  _itmlst_contains "$olFormatRules" "HIERARCHICAL" && {
      [[ "$currentPrTitle" =~ $REGEX_H ]] && prTitleIsValid=true
  }

  if $prTitleIsValid; then
    _log_i "Pull Request title \"$currentPrTitle\" is valid"
    true
  else
    _ppl-job-update-status "$EE_COMMIT_ID" "failure" "Failed" "Ill-formatted PR title"
    _FATAL "The Pull Request title \"$currentPrTitle\" violates the required format ($formatRules)"
  fi
}
