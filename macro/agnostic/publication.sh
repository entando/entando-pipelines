#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# HELPER for triggering publications
#
# Params:
# $1: the release action to apply
#
# Actions:
# - tag-git-version:         applies the snapshot tag to the current commit
# - tag-git-pseudo-version:  applies a tag similar to the snapshot tag but that doesn't triggers workflows
#
ppl--publication() {
  (
    START_MACRO "PUBLICATION" "$@"

    _pkg_get "xmlstarlet"

    __ppl_enter_local_clone_dir
    
    local action
    _get_arg action 1

    case "$action" in
      "tag-git-version") ppl--publication.tag-git-version "v";;
      "tag-git-pseudo-version") ppl--publication.tag-git-version "p";;
      *)
        _FATAL "Invalid action \"$action\" provided"
        ;;
    esac
  )
}


ppl--publication.tag-git-version() {
  _NONNULL PPL_RUN_ID
  
  local snapshotVersionTypePrefix="$1"
  
  ppl-release._handle_direct_commits || {
    return 0
  }
  
  local snapshotVersionTag pr_num
  ppl--publication._determine_snapshot_version_tag snapshotVersionTag
  _NONNULL snapshotVersionTypePrefix snapshotVersionTag
  
  local snapshotVersionTag="$snapshotVersionTypePrefix$snapshotVersionTag"
  if [ -n "$PPL_HEAD_REF" ]; then
    __git checkout "$PPL_HEAD_REF"
    pr_num="$PPL_PR_NUM"
  else
    _ppl_extract_version_part pr_num "$snapshotVersionTag" "pr-num"
  fi

  _NONNULL pr_num
  
  _git_commit_exists "$PPL_COMMIT_ID" || {
    _FATAL "Unable to find the reference commit on this repo, " \
           "may be you re-executed an old run?"
  }
  
  __git_add_tag -f "$snapshotVersionTag" "$PPL_RUN_ID" "$PPL_COMMIT_ID"
  __git push origin "$snapshotVersionTag" -f
  
  if [ "${snapshotVersionTag:0:1}" = "v" ]; then
    local versionNumber
    _ppl_extract_version_part versionNumber "${snapshotVersionTag}" "effective-number"
    _ppl-pr-submit-comment "$pr_num" "Requested publication of version \`${versionNumber}\`"
  fi
}

# Determine the current snapshot version numbers
#
# Supported Conditions:
# - On a PR creation/update commit
# - On a PR merge commit
#
ppl--publication._determine_snapshot_version_tag() {
  if [ -n "$PPL_BASE_REF" ]; then
    ppl--publication._determine_snapshot_version_tag.in_pr_event "$1"
  else
    ppl--publication._determine_snapshot_version_tag.in_non_pr_event "$1"
  fi
}

ppl--publication._determine_snapshot_version_tag.in_pr_event() {
    local _tmp_ver_ _tmp_qual_ _tmp_fix_tag_=""
    
    _NONNULL PPL_PR_TITLE
    _ppl_get_current_project_version _tmp_ver_
    
    if [ "$PPL_BRANCHING_TYPE" = "release" ]; then
      _semver_ex_parse maj min ptc "" _tmp_fix_tag_ "$_tmp_ver_"
      if [ "${_tmp_fix_tag_:0:3}" = "fix" ]; then
        _tmp_fix_tag_="${_tmp_fix_tag_}-"
      fi
    fi
    
    _ppl_extract_artifact_qualifier_from_pr_title --epic-name "$PPL_EPIC_NAME" _tmp_qual_ "$PPL_PR_TITLE"
    
    if [ -n "$PPL_EPIC_NAME" ]; then
      _semver_set_tag _tmp_ver_ "$_tmp_ver_" "$_tmp_fix_tag_$_tmp_qual_-PR-$PPL_PR_NUM-EP-$PPL_EPIC_NAME"
    else
      _semver_set_tag _tmp_ver_ "$_tmp_ver_" "$_tmp_fix_tag_$_tmp_qual_-PR-$PPL_PR_NUM"
    fi
    
    _set_var "$1" "$_tmp_ver_+$(_ppl_encode-branch-for-tagging "BB" "$PPL_BASE_REF")"
}

ppl--publication._determine_snapshot_version_number() {
  local _tmp_dssvn_
  ppl--publication._determine_snapshot_version_tag _tmp_dssvn_
  _ppl_extract_version_part "$1" "${_tmp_dssvn_}" "effective-number"
}

ppl--publication._determine_snapshot_version_tag.in_non_pr_event() {
  local _tmp_ver_tag_
  _NONNULL PPL_NEAREST_MAIN_BRANCH
  
  # ON THE BASE BRANCH
  __git_get_commit_tag --snapshot-tag _tmp_ver_tag_ "$PPL_COMMIT_ID"

  if [[ -n "$_tmp_ver_tag_" ]]; then
    # development branch was already published
    if _ppl_is_release_version_number "$_tmp_ver_tag_"; then
      _FATAL "Overwriting a release publication version tag is not allowed"
    else
      _log_i "This merge commit was already tagged => Reusing tag \"$_tmp_ver_tag_\""
    fi
  else
    # development branch is yet to be published
    local pr_parent
    __git_get_parent_pr pr_parent "$PPL_COMMIT_ID"
    __git_get_commit_tag --snapshot-tag _tmp_ver_tag_ "$pr_parent"
    
    _git_log_topo_summary
    
    [ -z "$_tmp_ver_tag_" ] && __git_get_commit_tag --pseudo-snapshot-tag _tmp_ver_tag_ "$pr_parent"
  fi
  
  _ppl_extract_version_part _tmp_ver_tag_ "${_tmp_ver_tag_}" "effective-number"
  
  _set_var "$1" "${_tmp_ver_tag_}+$(_ppl_encode-branch-for-tagging "KB" "$PPL_NEAREST_MAIN_BRANCH")"
}

# Reaction to direct commits on a non-PR branch:
#
# Case 1: it's merge commit => OK
# Case 2: it's not a merge commit and TOLERATE-DIRECT-COMMITS is enabled => OK
# Case 3: it's not a merge commit and TOLERATE-DIRECT-COMMITS is not enabled => ERROR
#
ppl-release._handle_direct_commits() {
  if ! $PPL_IN_PR_BRANCH; then
    local pr_parent
    __git_get_parent_pr --tolerant pr_parent "$PPL_COMMIT_ID"
    if [ -z "$pr_parent" ]; then
      if _itmlst_contains "$PPL_FEATURES" "TOLERATE-DIRECT-COMMITS"; then
        _log_t "Direct commit to base branch tolerated due to \"TOLERATE-DIRECT-COMMITS\" feature flag"
        return 1
      else
        _FATAL "Only PR merges can be snapshot-tagged on the base branch"
      fi
    fi
  fi  
  true
}
