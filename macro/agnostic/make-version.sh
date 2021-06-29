#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# CREATES A VERSION
#
# Params:
# $1: the versioning strategy
#
ppl--make-version() {
  (
    START_MACRO "$1" "$PPL_CONTEXT"
    shift
    
    local TMP TAG

    # CHECKOUT
    ppl--checkout-pr-branch "tmp" || exit "$?"
    __cd tmp
    # UPDATE VERSION
    case "$1" in
      latest)
        local maj min ptc
        _git_determine_latest_version TMP
        _semver_parse maj min ptc "" "$TMP"
        ((ptc++))
        TMP="$maj.$min.$ptc"
        _pom_set_project_version "$TMP" "./pom.txt"
        TAG="v$maj.$min.$ptc"
        ;;
      preview)
        _NONNULL EE_PR_NUM EE_PR_TITLE_PREFIX
        _pom_get_project_version TMP "./pom.xml"
        _semver_set_tag TMP "$TMP" "$EE_PR_TITLE_PREFIX/PR$EE_PR_NUM"
        _pom_set_project_version "$TMP" "./pom.xml"
        TAG="p$TMP"
        ;;
      *)
        _FATAL "Illegal versioning strategy provided"
        ;;
    esac

    # TAG
    local newBranch="rel-PR$EE_PR_NUM"
    git switch "$newBranch" 2>/dev/null || git switch -c "$newBranch" || _FATAL "git switch failed"
    __git add .
    __git commit -m "Make version $TMP"
    __git tag "$TAG"
    __git remote -v
    __git push --set-upstream origin "$newBranch"

    # BUILD
    ppl--mvn BUILD-AND-TEST || exit "$?"
    
# 
# SET PREVIEW VERSION IN POM
# 
# BUILD
# 
# PUBLISH
# PREVIEW ARTIFACT
# 
# TAG AS
# PREVIEW VERSION
# 
# PUSH
    

  )
}
