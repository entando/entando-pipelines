#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# STARTS THE CREATION OF A VERSION
#
# Params:
# $1: the release action to apply
#
# Actions:
# - tag-snapshot-version:   applies the snapshot tag to the current commit
# - tag-release-version     applies the final release tag to the current commit
#
ppl--release() {
  (
    START_MACRO "RELEASE" "$@"

    _pkg_get "xmlstarlet" -c "xmlstarlet"

    __ppl_enter_local_clone_dir
    
    local action
    _get_arg action 1

    case "$action" in
      "tag-snapshot-version") ppl--release.tag-snapshot-version "v";;
      "tag-release-version") ppl--release.prepare-final-release;;
      *)
        _FATAL "Illegal action \"$action\" provided"
        ;;
    esac
  )
}


ppl--release.tag-snapshot-version() {
  _NONNULL PPL_RUN_ID
  
  local snapshotVersionTypePrefix="$1"
  
  ppl-release._handle_direct_commits || {
    return 0
  }
  
  local snapshotVersionName pr_num
  ppl--release._determine_snapshot_version_name snapshotVersionName
  _NONNULL snapshotVersionTypePrefix snapshotVersionName
  
  local snapshotVersionTag="$snapshotVersionTypePrefix$snapshotVersionName"
  if [ -n "$PPL_HEAD_REF" ]; then
    __git checkout "$PPL_HEAD_REF"
    pr_num="$PPL_PR_NUM"
  else
    _ppl_extract_snapshot_version_name_part pr_num "$snapshotVersionName" "pr-num"
  fi

  _NONNULL pr_num
  
  _git_commit_exists "$PPL_COMMIT_ID" || {
    _FATAL "Unable to find the reference commit on this repo, " \
           "may be you re-execute an old run?"
  }
  
  __git_add_tag -f "$snapshotVersionTag" "$PPL_RUN_ID" "$PPL_COMMIT_ID"
  __git push origin "$snapshotVersionTag" -f
  
  _ppl-pr-submit-comment "$pr_num" "Requested publication of snapshot version \`${snapshotVersionName}\`"
}

ppl--release._determine_snapshot_version_name() {
  local _tmp_ver_ _tmp_qual_

  
  if [ -n "$PPL_BASE_REF" ]; then
    # ON THE PR BRANCH
    _NONNULL PPL_PR_TITLE_PREFIX
    _ppl_get_current_project_version _tmp_ver_
    _ppl_extract_artifact_qualifier_from_pr_title _tmp_qual_ "$PPL_PR_TITLE_PREFIX"
    _semver_set_tag _tmp_ver_ "$_tmp_ver_" "$_tmp_qual_-PR-$PPL_PR_NUM"
  else
    # ON THE DEVELOPMENT BRANCH
    __git_get_commit_tag --snapshot-tag _tmp_ver_ "$PPL_COMMIT_ID"
    
    if [[ -n "$_tmp_ver_" ]]; then
      # development branch was already published
      _log_i "This merge was already tagged => Reusing tag \"$_tmp_ver_\""
    else
      # development branch is yet to be published
      local pr_parent
      __git_get_parent_pr pr_parent "$PPL_COMMIT_ID"
      __git_get_commit_tag --snapshot-tag _tmp_ver_ "$pr_parent"
    fi

    _tmp_ver_="${_tmp_ver_:1}"    # strips the tag version prefix
  fi
  
  _set_var "$1" "$_tmp_ver_"
}

ppl--release._determine_final_version_name() {
  _NONNULL PPL_BASE_REF PPL_PR_TITLE_PREFIX
  local _tmp_ver_ _tmp_qual_

  _FATAL "NOT IMPLEMENTED"
  
  # READ THE BASE PROJECT VERSION
  __git checkout "$PPL_BASE_REF"
  _ppl_get_current_project_version _tmp_ver_
  _ppl_extract_artifact_qualifier_from_pr_title _tmp_qual_ "$PPL_PR_TITLE_PREFIX"
  __git checkout "-"

  _semver_set_tag _tmp_ver_ "$_tmp_ver_" "$_tmp_qual_-PR-$PPL_PR_NUM-SNAPSHOT"

  _set_var "$1" "$_tmp_ver_"
}

ppl-release._handle_direct_commits() {
   if [ -z "$PPL_BASE_REF" ]; then
    local pr_parent
    __git_get_parent_pr --tolerant pr_parent "$PPL_COMMIT_ID"
    if [ -z "$pr_parent" ]; then
      if _itmlst_contains "$PPL_FEATURES" "IGNORE-DIRECT-COMMITS"; then
        _log_i "Direct commit to base branch ignored due to \"IGNORE-DIRECT-COMMITS\" feature flag"
        return 1
      else
        _FATAL "Only PR merges can be snapshot-tagged the base branch"
      fi
    fi
  fi  
  true
}
