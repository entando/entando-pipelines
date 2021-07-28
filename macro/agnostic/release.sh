#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# STARTS THE CREATION OF A VERSION
#
# Params:
# $1: the ID of the macro
# $3: the release operation
# $2: the folder where the PR has been checked out
#
ppl--release() {
  (
    START_MACRO "RELEASE" "$@"

    _pkg_get "xmlstarlet" -c "xmlstarlet"

    __ppl_enter_local_clone_dir
    __exist -f "pom.xml"

    local action versionToSet TAG pomVersionToSet
    local currentBranch="${EE_REF##*/}"
    
    _get_arg action 1

    #~ 
    #~ ANALYSIS of the current repo/branch
    #~ READY-ONLY
    #~
    case "$action" in
      prepare-tag-release)
        #~ determine the next module version from the current git repo tags
        local highestModuleVersion maj min ptc
        _git_determine_highest_version highestModuleVersion
        _semver_parse maj min ptc "" "$highestModuleVersion"
        ((ptc++))
        versionToSet="${maj:-0}.${min:-0}.${ptc:-0}"
        TAG="v$versionToSet"
        ;;
      prepare-preview-release)
        __git checkout "$EE_BASE_REF"
        local snapshotVersion
        #~ derived from the PR information
        _NONNULL EE_PR_NUM EE_PR_TITLE_PREFIX
        _pom_get_project_version snapshotVersion "./pom.xml"
        EE_PR_TITLE_PREFIX="${EE_PR_TITLE_PREFIX/\//-}"
        EE_PR_TITLE_PREFIX="${EE_PR_TITLE_PREFIX/\[/_}"
        EE_PR_TITLE_PREFIX="${EE_PR_TITLE_PREFIX/\]/_}"
        _semver_set_tag versionToSet "$snapshotVersion" "$EE_PR_TITLE_PREFIX-PR-$EE_PR_NUM-SNAPSHOT"
        _NONNULL versionToSet
        TAG="p$versionToSet"
        __git checkout "$EE_HEAD_REF"
        ;;
      auto-finalize-release)
        case "$currentBranch" in
          v*)
            _log_i "Finalizing tag-release \"${currentBranch:1}\""
            pomVersionToSet=""
            ;;
          p*)
            pomVersionToSet="${currentBranch:1}"
            _log_i "Finalizing preview release \"$pomVersionToSet\""
            ;;
          *)
        esac
        ;;
      *)
        _FATAL "Illegal action \"$action\" provided"
        ;;
    esac
    
    #~ 
    #~ UPDATE OF THE RELEASE BRANCH
    #~ READY-WRITE
    #~ 
    case "$action" in
      prepare-tag-release)
        _ppl_determine_release_branch releaseBranch "$versionToSet"
        # shellcheck disable=SC2154
        __git_auto_checkout "$releaseBranch"
        _NONNULL currentBranch
        __git_force_merge_branch "$currentBranch"
        #~ UPDATES the version on the POM and REBUILDS the module
        _pom_set_project_version "$versionToSet" "./pom.xml"
        __git_ACTP "Release of version $versionToSet"  "$TAG" "$releaseBranch"
        ;;
      prepare-preview-release)
        git push --delete origin "$TAG" 2>/dev/null
        __git_add_tag -f "$TAG" "$EE_RUN_ID"
        __git push --tags
        ;;
      auto-finalize-release)
        # Build
        _pom_set_project_version "$pomVersionToSet" "./pom.xml"
        #__mvn_exec package -Dmaven.test.skip=true
        ;;
      *)
        _FATAL "Illegal action \"$action\""
        ;;
    esac
  )
}
