#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# EXECUTES PRELIMINAR CHECKS ABOUT THE CURRENT PR
#
# > Checks the format of the PR title:
# > Checks the format of the project version number on PR
# > Checks that the development PR is compatible with the current mainline version (optional via ENTANDO_OPT_MAINLINE)
# > Runs optional custom check (user provided script "custom-pr-check.sh")
#
ppl--pr-preflight-checks() {
  (
    START_MACRO "PREFLIGHT-CHECKS" "$@"
    _pkg_get "xmlstarlet"
    
    _get_arg ONLY --only
    
    __ppl_enter_local_clone_dir
    
    [[ -z "$ONLY" || "$ONLY" = "checks" ]] && {
      ppl--pr-preflight-checks.CHECK_TITLE_FORMAT
    }
    
    local projectVersion
    
    _ppl_get_current_project_version projectVersion
    
    [[ -z "$ONLY" || "$ONLY" = "checks" ]] && {
      ppl--pr-preflight-checks.CHECK_MAINLINE "$projectVersion"
      ppl--pr-preflight-checks.CHECK_PROJECT_VERSION_FORMAT "$projectVersion"
    }
    [[ -z "$ONLY" || "$ONLY" = "custom" ]] && {
      ppl--pr-preflight-checks.CHECK_WITH_CUSTOM_SCRIPT "$projectVersion"
    }
    [[ -z "$ONLY" || "$ONLY" = "flags" ]] && {
      ppl--pr-preflight-checks.SETUP_MERGE_RELATED_FLAGS
    }
    
    true
  )
}

ppl--pr-preflight-checks.CHECK_MAINLINE() {
  if [ -z "${ENTANDO_OPT_MAINLINE}" ]; then
    _log_d "Mainline check is not enabled"
    return 0
  fi
  
  local projectVersion="$1" mMaj mMin maj min
  _semver_parse mMaj mMin "" "" "${ENTANDO_OPT_MAINLINE}"
  _semver_parse maj min "" "" "${projectVersion}"

  # Snapshot X.Y must be equal to Mainline X.Y
  if [ "$mMaj" != "$maj" ] || [ "$mMin" != "$min" ]; then
    if [ "${PPL_REF_NAME:0:8}" != "release/" ]; then
      _ppl-job-update-status "$PPL_COMMIT_ID" "failure" "Failed" "Invalid project version (incompatible with mainline)"
      _FATAL "In non-release branches the project version (\"$projectVersion\") must be compatible with the current mainline: \"${ENTANDO_OPT_MAINLINE}\""
    fi
  fi
  
  _log_i "Mainline compliance validation passed (${projectVersion} vs ${ENTANDO_OPT_MAINLINE})"
}

ppl--pr-preflight-checks.CHECK_PROJECT_VERSION_FORMAT() {
  local projectVersion="$1"
  
  if [ "$PPL_BRANCHING_TYPE" = "release" ]; then
    # ON A RELEASE MAIN BRANCH OR PR BRANCH
  
    #_semver_ex_parse maj min ptc "" tag "$projectVersion"
    ## shellcheck disable=SC2154
    #if [[ "$tag" != "" && "${tag:0:3}" != "fix" ]]; then
    #  _FATAL "A null version tag or a fix version tag is required in release #branching"
    #fi
    true
  else
    # ON THE DEVELOPMENT MAIN BRANCH OR SUB-BRANCH
    
    if [[ "$projectVersion" =~ .*-SNAPSHOT ||  "$projectVersion" =~ .*-snapshot ]]; then
      _log_i "Project version number is a snapshot as required"
      true
    else
      _ppl-job-update-status "$PPL_COMMIT_ID" "failure" "Failed" "Invalid project version"
      _FATAL "The project version \"$projectVersion\" is not a snapshot"
    fi
  fi
}

ppl--pr-preflight-checks.CHECK_TITLE_FORMAT() {
  local formatRules
  _get_arg formatRules 1 "${ENTANDO_OPT_PR_TITLE_FORMAT:-"SINGLE|HIERARCHICAL"}"
  _NONNULL formatRules
  
  local olFormatRules="${formatRules//\|/,}" # conversion to itmlst

  local TICKET_ID_REGEX="[A-Z]{2,5}-[0-9]{1,5}"
  local REGEX_S="^${TICKET_ID_REGEX}([[:space:]]|:)"
  local REGEX_H="^${TICKET_ID_REGEX}\/${TICKET_ID_REGEX}([[:space:]]|:)"
  local REGEX_SNYK="^\[Snyk\]"
  local prTitleIsValid=false

  _itmlst_contains "$olFormatRules" "ANY" && {
      prTitleIsValid=true
  }
  
  local currentPrTitle _tmp_
  _ppl-query-pr-info currentPrTitle "title"

  #~ Support for revert PRs
  _tmp_="$currentPrTitle"
  [ "${_tmp_:0:8}" = "Revert \"" ] && _tmp_="${_tmp_:8}"
  
  #~ EPIC NAME CHECK
  if [ -n "$PPL_EPIC_NAME" ]; then
    local enlen="${#PPL_EPIC_NAME}"; ((enlen++))
    if [ "${_tmp_:0:$enlen}" = "$PPL_EPIC_NAME/" ]; then
      _tmp_="${_tmp_:$enlen}"
    else
      _FATAL "The Pull Request title \"$currentPrTitle\" violates the required format" \
             "(missing epic name when under epic branch)"
    fi
  fi
  
  #~ TITLE FORMAT CHECK
  [[ "$_tmp_" =~ $REGEX_SNYK ]] && prTitleIsValid=true
  
  _itmlst_contains "$olFormatRules" "SINGLE" && {
      [[ "$_tmp_" =~ $REGEX_S ]] && prTitleIsValid=true
  }
  _itmlst_contains "$olFormatRules" "HIERARCHICAL" && {
      [[ "$_tmp_" =~ $REGEX_H ]] && prTitleIsValid=true
  }

  if $prTitleIsValid; then
    _log_i "Pull Request title \"$currentPrTitle\" is valid"
    true
  else
    _FATAL "The Pull Request title \"$currentPrTitle\" violates the required format ($formatRules)"
  fi
}

ppl--pr-preflight-checks.CHECK_WITH_CUSTOM_SCRIPT() {
  [ ! -f "./.github/custom-pr-check.sh" ] && return 0
  if ./.github/custom-pr-check.sh; then
    _log_i "Custom PR validation script passed"
    true
  else
    _FATAL "Custom PR validation script failed with error code: \"$?\""
  fi
}

ppl--pr-preflight-checks.SETUP_MERGE_RELATED_FLAGS() {
  local parent_pr
  __git_get_parent_pr --tolerant parent_pr "$PPL_COMMIT_ID"

  if [ -n "$parent_pr" ]; then
    # MERGE COMMIT
    _ppl-set-persistent-var "MERGE_FLAG" true
    _ppl-set-persistent-var "BOM_UPDATE_FLAG" true
    _log_d "This is a merge commit"
  else
    # NON-MERGE COMMIT
    _ppl-set-persistent-var "MERGE_FLAG" false
    _ppl-set-persistent-var "BOM_UPDATE_FLAG" true
    #_ppl-set-persistent-var "BOM_UPDATE_FLAG" false
    _log_d "This is not a merge commit"
  fi
}
