#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# MACRO OPERATIONS RELATED TO THE BOM
#
# Params:
# $1: action to apply
#
# Actions:
# - update-bom    if the projects belong to a bom automatically updates the bom when a new project version is generated
#
# Requires:
# - maven projects
# - ENTANDO_OPT_REPO_BOM_URL
# - ENTANDO_OPT_REPO_BOM_MAIN_BRANCH
#
ppl--bom() {
  (
    START_MACRO "BOM" "$@"

    _pkg_get "xmlstarlet"
    
    local action
    _get_arg action 1


    case "$action" in
      update-bom)

        local projectArtifactId projectVersion bomQualifier
        ppl--bom.update-bom.SHOULD_RUN || return 0
        ppl--bom.EXTRACT_PROJECT_INFORMATION projectArtifactId projectVersion "$PPL_LOCAL_CLONE_DIR"
        ppl--bom.DETERMINE_BOM_QUALIFIER bomQualifier "${PPL_REF_NAME:1}"
        ppl--bom.UPDATE-PROJECT_REFERENCE_ON_BOM "$projectArtifactId" "$projectVersion" "$PPL_TOKEN_OVERRIDE" "$bomQualifier"
        ;;
      *)
        _FATAL "Invalid bom action \"$action\""
        ;;
    esac
  )
}

ppl--bom.update-bom.SHOULD_RUN() {
  case "${PPL_REF_NAME}" in
    v*) return 0;;
    *) _log_d "update-bom skipped"; return 1;;
  esac
}

ppl--bom.EXTRACT_PROJECT_INFORMATION() {
  __cd "$3"
  _ppl_get_current_project_artifact_id "$1"
  _ppl_get_current_project_version "$2"
}

ppl--bom.UPDATE-PROJECT_REFERENCE_ON_BOM() {
  local projectArtifactId="$1" projectVersion="$2" token="$3" bomQualifier="$4"
  _NONNULL projectArtifactId projectVersion
  
  local bom_branch="$ENTANDO_OPT_REPO_BOM_MAIN_BRANCH"
  [ -z "$bom_branch" ] && bom_branch="$PPL_NEAREST_WELL_KNOWN_BRANCH"
  [ -z "$bom_branch" ] && bom_branch="$DEFAULT_BOM_BRANCH"
  _git_full_clone --as-work-area "$ENTANDO_OPT_REPO_BOM_URL" "" "$bom_branch" "$token"
  
  # set the new version
  _log_i "Setting $projectArtifactId => $projectVersion"
  _pom_set_project_property "$projectVersion" "pom.xml" "${projectArtifactId}.version"
  
  local maj min ptc bomVersionTag
  _pom_get_project_version bomProjectVersion "pom.xml"
  # shellcheck disable=SC2154
  _semver_parse maj min ptc "" "$bomProjectVersion"
  bomVersionTag="v${maj}.${min}.${ptc}-$bomQualifier"
  
  _git_auto_setup_commit_config
  
  __git_ACTP --tolerant --force-tag \
    "Update the reference to \"${projectArtifactId}\" to version ${projectVersion}" \
    "${bomVersionTag}" "-" \
  ;
}

ppl--bom.DETERMINE_BOM_QUALIFIER() {
  local _tmp_base_ _tmp_qualifier_p1_ _tmp_qualifier_p2_ _tmp_fixed_ _tmp_pr_
  # shellcheck disable=SC2034
  IFS="-" read -r _tmp_base_ _tmp_qualifier_p1_ _tmp_qualifier_p2_ _tmp_fixed_ _tmp_pr_ <<<"$2"
  
  if [ "$_tmp_fixed_" != "PR" ] || [ "$_tmp_qualifier_p2_" == "" ]; then
    _FATAL "Unrecognised PR tag format: I need a proper PR tag"
  fi
  
 _set_var "$1" "${_tmp_qualifier_p1_}-${_tmp_qualifier_p2_}" 
}
