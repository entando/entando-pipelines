#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# MACRO OPERATIONS RELATED TO THE BOM
#
# Params:
# $1: the ID of the macro
# $2: action to apply
# $3: directory of the project
# $4: optional token for the external repos
#
ppl--bom() {
  (
    START_MACRO "$1" "$PPL_CONTEXT"

    _pkg_get "xmlstarlet" -c "xmlstarlet"

    case "$2" in
      update-bom)
        local projectArtifactId projectVersion projectDir="$3" token="$4"
        
        ppl--bom.update-bom.SHOULD_RUN || return 0
        ppl--bom.EXTRACT_PROJECT_INFORMATION "$projectDir" projectArtifactId projectVersion
        ppl--bom.UPDATE-PROJECT_REFERENCE_ON_BOM "$projectArtifactId" "$projectVersion" "$token"
        ;;
      *)
        _FATAL "Illegal bom action \"$1\""
        ;;
    esac
  )
}

ppl--bom.update-bom.SHOULD_RUN() {
  case "${EE_REF_NAME}" in
    v*) return 0;;
    *) _log_d "update-bom skipped"; return 1;;
  esac
}

ppl--bom.EXTRACT_PROJECT_INFORMATION() {
  __cd "$1"
  __exist -f "pom.xml"
  _pom_get_project_artifact_id "$2" "pom.xml"
  _pom_get_project_version "$3" "pom.xml"
}

ppl--bom.UPDATE-PROJECT_REFERENCE_ON_BOM() {
  local projectArtifactId="$1" projectVersion="$2" token="$3"
  _NONNULL projectArtifactId projectVersion
  
  _git_full_clone --as-work-area "$ENTANDO_OPT_REPO_BOM_URL" "" "$ENTANDO_OPT_REPO_BOM_MAIN_BRANCH" "$token"

  # get current BOM version
  #local currentBomVersion
  #_pom_get_project_version currentBomVersion "pom.xml" "${projectArtifactId}.version"
  #_NONNULL currentBomVersion

  # get the currently project version referenced in BOM
  local currentArtifactVersionInBom
  _pom_get_project_property currentArtifactVersionInBom "pom.xml" "${projectArtifactId}.version"
  _NONNULL currentArtifactVersionInBom

  # proceed only if the version to set is higher than the current version
  local tmp
  _semver_cmp tmp "$currentArtifactVersionInBom" "$projectVersion"
  [ "$tmp" -ge 0 ] && _EXIT "Bom update skipped: Current artifact version in the BOM ($currentArtifactVersionInBom) >= the artifact version to set ($projectVersion)"

  # set the new version
  #_semver_add currentBomVersion "$currentBomVersion" 0 0 1
  _log_i "Setting $projectArtifactId => $projectVersion"
  #_pom_set_project_version "$currentBomVersion" "pom.xml"
  _pom_set_project_property "$projectVersion" "pom.xml" "${projectArtifactId}.version"
  _git_auto_setup_commit_config
  __git_ACTP "Generate version $projectVersion" "" "-"
}
