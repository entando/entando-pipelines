#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# MACRO OPERATIONS RELATED TO THE BOM
#
# Params:
# $1: the ID of the macro
# $2: action to apply
# $3: directory of the project
#
ppl--bom() {
  (
    START_MACRO "$1" "$PPL_CONTEXT"

    _pkg_get "xmlstarlet" -c "xmlstarlet"

    local currentArtifactVersionInBom newArtifactVersion artifactId tmp

    case "$2" in
      update-bom)
        local currentBranch="${EE_REF##*/}"

        case "${currentBranch}" in
          release-*) ;;
          p) _log_d "Skipped"; return 0;;
        esac

        bomFolder="entando-core-bom-folder"

        __cd "$3"
        __exist -f "pom.xml"
        _pom_get_project_artifact_id artifactId "pom.xml"
        _pom_get_project_version newArtifactVersion "pom.xml"

        _NONNULL artifactId newArtifactVersion ENTANDO_OPT_REPO_BOM_URL

        # clone entando-core-bom
        mkdir "bom-tmp" && cd "bom-tmp" \
           && _git_full_clone "$ENTANDO_OPT_REPO_BOM_URL" "$bomFolder" "$GIT_TOKEN"
        __cd "$bomFolder"
        
        __git switch "$ENTANDO_OPT_REPO_BOM_MASTER_BRANCH"

        # update the current artifact version in the entando-core-bom pom.xml file
        _pom_get_project_property currentArtifactVersionInBom "pom.xml" "${artifactId}.version"
        _NONNULL currentArtifactVersionInBom
        _semver_cmp tmp "$currentArtifactVersionInBom" "$newArtifactVersion"
        if [ "$tmp" -ge 0 ]; then
          _EXIT "Current artifact version in the BOM is >= the artifact version to set"
        fi

        _pom_set_project_property "$newArtifactVersion" "pom.xml" "${artifactId}.version"
        
        _git_auto_setup_commit_config

        __git_ACTP "Generated version $newArtifactVersion"
        __git push
        ;;
      *)
        _FATAL "Illegal bom action \"$1\""
        ;;
    esac
  )
}
