#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# STARTS THE CREATION OF A VERSION
#
# Params:
# $1: the release action to apply
#
# Actions:
# - tag-snapshot-version:         applies the snapshot tag to the current commit
# - tag-pseudo-snapshot-version:  applies a tag similar to the snapshot tag but that doesn't triggers workflows
# - tag-release-version           applies the final release tag to the current commit
#
ppl--release() {
  (
    START_MACRO "RELEASE" "$@"

    _pkg_get "xmlstarlet"

    __ppl_enter_local_clone_dir
    
    local action
    _get_arg action 1

    case "$action" in
      "tag-snapshot-version") ppl--release.tag-snapshot-version "v";;
      "tag-pseudo-snapshot-version") ppl--release.tag-snapshot-version "p";;
      "tag-release-version") ppl--release.prepare-final-release;;
      *)
        _FATAL "Invalid action \"$action\" provided"
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
           "may be you re-executed an old run?"
  }
  
  __git_add_tag -f "$snapshotVersionTag" "$PPL_RUN_ID" "$PPL_COMMIT_ID"
  __git push origin "$snapshotVersionTag" -f
  
  _ppl-pr-submit-comment "$pr_num" "Requested publication of snapshot version \`${snapshotVersionName}\`"
}

# Determine the current snapshot version names
#
# Supported Conditions:
# - On a PR creation/update commit
# - On a PR merge commit
#
ppl--release._determine_snapshot_version_name() {
  if [ -n "$PPL_PR_TITLE" ]; then
    ppl--release._determine_snapshot_version_name.on_pr_sync_event "$1"
  else
    ppl--release._determine_snapshot_version_name.on_tag_event "$1"
  fi
}

ppl--release._determine_snapshot_version_name.on_pr_sync_event() {
    local _tmp_ver_ _tmp_qual_ _tmp_fix_tag_=""
    
    _NONNULL PPL_PR_TITLE
    _ppl_get_current_project_version _tmp_ver_

    if $PPL_ON_RELEASE_PR_BRANCH; then
      _semver_ex_parse maj min ptc "" _tmp_fix_tag_ "v10.9.8-fix.1"
      if [ "${_tmp_fix_tag_:0:3}" = "fix" ]; then
        _tmp_fix_tag_="${_tmp_fix_tag_}-"
      elif [ "$_tmp_fix_tag_" != "" ]; then
        _FATAL "A null version tag or a fix version tag is required in release braanching"
      fi
    fi
    
    _ppl_extract_artifact_qualifier_from_pr_title --epic-name "$PPL_EPIC_NAME" _tmp_qual_ "$PPL_PR_TITLE"
    
    if [ -n "$PPL_EPIC_NAME" ]; then
      _semver_set_tag _tmp_ver_ "$_tmp_ver_" "$_tmp_fix_tag_$_tmp_qual_-PR-$PPL_PR_NUM-EP-$PPL_EPIC_NAME"
    else
      _semver_set_tag _tmp_ver_ "$_tmp_ver_" "$_tmp_fix_tag_$_tmp_qual_-PR-$PPL_PR_NUM"
    fi
    
    _set_var "$1" "$_tmp_ver_"
}

ppl--release._determine_snapshot_version_name.on_tag_event() {
  local _tmp_ver_tag_
  
  # ON THE BASE BRANCH
  __git_get_commit_tag --snapshot-tag _tmp_ver_tag_ "$PPL_COMMIT_ID"
  
  if [[ -n "$_tmp_ver_tag_" ]]; then
    # development branch was already published
    _log_i "This merge commit was already tagged => Reusing tag \"$_tmp_ver_tag_\""
  else
    # development branch is yet to be published
    local pr_parent
    __git_get_parent_pr pr_parent "$PPL_COMMIT_ID"
    __git_get_commit_tag --snapshot-tag _tmp_ver_tag_ "$pr_parent"
    [ -z "$_tmp_ver_tag_" ] && __git_get_commit_tag --pseudo-snapshot-tag _tmp_ver_tag_ "$pr_parent"
  fi
  
  _set_var "$1" "${_tmp_ver_tag_:1}"    # strips the tag version prefix
}

ppl--release._determine_final_version_name() {
  _NONNULL PPL_BASE_REF PPL_PR_TITLE_PREFIX
  local _tmp_ver_ _tmp_qual_

  _FATAL "NOT IMPLEMENTED"
  
  # READ THE BASE PROJECT VERSION
  __git checkout "$PPL_BASE_REF"
  _ppl_get_current_project_version _tmp_ver_
  _ppl_extract_artifact_qualifier_from_pr_title --epic-name "$PPL_EPIC_NAME" _tmp_qual_ "$PPL_PR_TITLE_PREFIX"
  __git checkout "-"

  _semver_set_tag _tmp_ver_ "$_tmp_ver_" "$_tmp_qual_-PR-$PPL_PR_NUM-SNAPSHOT"

  _set_var "$1" "$_tmp_ver_"
}

ppl-release._handle_direct_commits() {
   if ! $PPL_IN_PR_BRANCH; then
    local pr_parent
    __git_get_parent_pr --tolerant pr_parent "$PPL_COMMIT_ID"
    if [ -z "$pr_parent" ]; then
      if _itmlst_contains "$PPL_FEATURES" "TOLERATE-DIRECT-COMMITS"; then
        _log_i "Direct commit to base branch tolerated due to \"TOLERATE-DIRECT-COMMITS\" feature flag"
        return 1
      else
        _FATAL "Only PR merges can be snapshot-tagged on the base branch"
      fi
    fi
  fi  
  true
}
