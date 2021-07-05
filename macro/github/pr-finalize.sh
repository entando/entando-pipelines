#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# EXECUTES THE RELEASE OF AN APP-ENGINE MODULE
# Params:
# $1: the current reference
# $2: the url of the BOM
# -
# Expected ENV:
# - GIT_USER_NAME, GIT_USER_EMAIL, GIT_TOKEN, PPL_CONTEXT
#
ppl--finalize-pr() {
  set +e
  
  _log_i "FINALIZE-PR"
  _pkg_get "jq" -c "jq" "xmlstarlet" -c "xmlstarlet"
  _ppl-load-context "$PPL_CONTEXT"

  # ~
  # ~ GATERING INFO - LATEST VERSION OF THE PROJECT
  # ~
  local latestVersion newVersion maj min ptc

  _git_auto_setup_commit_config
  _git_fetch_all_tags
  _git_determine_latest_version latestVersion
  [ -z "$latestVersion" ] && latestVersion="0.0.0"

  _semver_parse maj min ptc "" "$latestVersion"
  ptc=$((ptc+1))
  
  _log_t "Latest version of the project is: $latestVersion"

  newVersion="$maj.$min.$ptc"
  _log_i "Setting new version to: $newVersion"

  # ~
  # ~ SETTING THE NEW VERSION
  # ~
  __mvn_exec versions:set -DnewVersion="$newVersion"
  
  # ~
  # ~ COMPILING
  # ~
  __mvn_exec compile
  
  # ~
  # ~ TAGGING
  # ~
  local releaseBranchName="rel_v$newVersion"

  git checkout -b "$releaseBranchName"
  git add .
  git commit -m "v$newVersion"
  __git_add_tag "v$newVersion"
  git push --set-upstream origin "$releaseBranchName" --force
  git push --tags
  git push -d origin "$releaseBranchName"
  #git checkout "$EE_BASE_REF"
  #git branch -D "$releaseBranchName"
}
