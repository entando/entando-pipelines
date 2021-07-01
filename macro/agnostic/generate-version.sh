#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# CREATES A VERSION
#
# Params:
# $1: the ID of the macro
# $3: the type of version to generate
# $2: the folder where the PR has been checked out
#
ppl--generate-version() {
  (
    START_MACRO "$1" "$PPL_CONTEXT"
    shift

    __cd "$2" 
    __exist -f "pom.xml"

    local versionToSet TAG

    #~ 
    #~ ANALYSIS of the current repo/branch
    #~ READY-ONLY
    #~
    __git checkout "develop"
    
    case "$1" in
      new-version)
        #~ determine the next module version from the current git repo tags
        local latestModuleVersion maj min ptc
        _git_determine_latest_version latestModuleVersion
        _semver_parse maj min ptc "" "$latestModuleVersion"
        ((ptc++))
        versionToSet="${maj:-0}.${min:-0}.${ptc:-0}"
        TAG="v$versionToSet"
        ;;
      preview-version)
        [ "$XX" = 1 ] && _FATAL XXXXXXXXXXXXXXXXXXXXXXXX
        local snapshotVersion
        #~ derived from the PR information
        _NONNULL EE_PR_NUM EE_PR_TITLE_PREFIX
        _pom_get_project_version snapshotVersion "./pom.xml"
        EE_PR_TITLE_PREFIX="${EE_PR_TITLE_PREFIX/\//-}"
        _semver_set_tag versionToSet "$snapshotVersion" "$EE_PR_TITLE_PREFIX-PR$EE_PR_NUM"
        TAG="p$versionToSet"
        ;;
      *)
        _FATAL "Illegal versioning strategy provided"
        ;;
    esac
    
    #~ 
    #~ UPDATE OF THE RELEASE BRANCH
    #~ READY-WRITE
    #~ 
    
    [ "$XX" = 1 ] && DBGSHELL
    
    # PREPARATION OF THE RELEASE BRANCH
    _ppl_determine_release_branch releaseBranch "$versionToSet"
    # shellcheck disable=SC2154
    __git_auto_checkout "$releaseBranch"
    
    # merges PR ==> RELEASE
    __git_force_merge_of_A_into_B \
      "$EE_HEAD_REF" \
      "$releaseBranch" \
    ;
    
    [ "$XX" = 1 ] && DBGSHELL
    
    #~ UPDATES the version on the POM and REBUILDS the module
    _pom_set_project_version "$versionToSet" "./pom.xml"
    #ppl--mvn BUILD || _SOE

    [ "$XX" = 1 ] && DBGSHELL    
    #~
    #~ FINALLY commits and PUSHES the updated release branch to the origin
    #~
    __git_ACTP "Generated version $versionToSet"  "$TAG" "$releaseBranch"
  )
}
