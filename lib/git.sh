#!/bin/bash

# Runs an arbitrary git command and FATALS if it fails
#
__git() {
  git "$@" || _FATAL -S 1 "git $1 failed"
}

# Clones a repository and the tags
#
# Params:
# $1: repository url
# $2: optional dest dir or ""
# $3: optional branch to checkout or ""
# $4: optional token
#
_git_full_clone() {
  local WORK_AREA=false; [ "$1" = "--as-work-area" ] && { WORK_AREA=true; shift; }
  local SHALLOW_OPT=""; [ "$1" = "--shallow" ] && { SHALLOW_OPT="--depth 1"; shift; }
  local REPO_URL="$1"
  local DST_DIR="$2"
  local BRANCH="$3"
  local TOKEN="$4"

  _NONNULL REPO_URL
  [ "${REPO_URL:${#REPO_URL}-1:1}" = "/" ] && REPO_URL="${REPO_URL:0:${#REPO_URL}-1}"
  [ -z "$DST_DIR" ] && DST_DIR="${REPO_URL##*/}"
  
  (
    _log_t "Cloning \"$REPO_URL\""

    _url_add_token REPO_URL "$REPO_URL" "$TOKEN"
    
    local FULL_DST_DIR="$DST_DIR"

    if $WORK_AREA; then
      mkdir -p "$HOME/work-area-1b00ddf8"
      FULL_DST_DIR="$HOME/work-area-1b00ddf8/$DST_DIR"
      rm -rf "$FULL_DST_DIR"
    else
      FULL_DST_DIR="$DST_DIR"
    fi
    
    # shellcheck disable=2086
    __git clone -q $SHALLOW_OPT "$REPO_URL" "$FULL_DST_DIR"

    if [ "$?" = 0 ]; then
      __cd "$FULL_DST_DIR"
      [ -n "$BRANCH" ] && __git -c advice.detachedHead=false checkout "$BRANCH"
      __git fetch -q --tag 1>/dev/null
      _log_t "Repo \"$REPO_URL\" cloned"
    else
      local TC=" (with no token)"
      [ -n "$TOKEN" ] && TC=" (with token)"
      _FATAL "Unable to clone repo \"$REPO_URL\"${TC}"
    fi
  ) || exit "$?"
  
  $WORK_AREA && {
    __cd "$HOME/work-area-1b00ddf8/$DST_DIR"
  }
}

# Sets the git commit config
#
# Options:
# --global: sets the info globally
#
# Params:
# $1: user name
# $2: user email
#
_git_set_commit_config() {
  local OPT=""
  [ "$1" = "--global" ] && { OPT="--global"; shift; }
  [ -d ".git" ] || _FATAL "Unable to find the \".git\" dir"
  git config $OPT user.name "$1"
  git config $OPT user.email "$2"
}

# Sets the git commit config of the local repo
# according with the information on the environment
#
# Expected Vars:
# GIT_USER_NAME: user name
# GIT_USER_EMAIL: user email
#
_git_auto_setup_commit_config() {
  _NONNULL GIT_USER_NAME GIT_USER_EMAIL
  _git_set_commit_config "$GIT_USER_NAME" "$GIT_USER_EMAIL"
}

# Extract the tag(s) on the given gitref string
#
# Params:
# $1: dest var
# $2: git-ref
#
_git_ref_to_version() {
  local _tmp_="$2"
  _tmp_="${_tmp_##*/}"
  [ "${_tmp_:0:1}" = "v" ] && _tmp_="${_tmp_:1}"
  _set_var "$1" "$_tmp_"
}

# Returns the commit id of the current local repo
#
_git_get_current_commit_id() {
  local _tmp_
  _tmp_="$(git rev-parse HEAD)"
  _set_var "$1" "$_tmp_"
}

# Returns the last version tag added
# Note that the command by default filters out the preview versions
#
# Options:
# --for: specifies the base version for the search (eg: 6.3 only looks for 6.3.* tags)
#
# Params:
# $1: the output var
#
#
_git_determine_highest_version() {
  local __tmp__
  
  local for_base_version
  [ "$1" == "--for" ] && {
    for_base_version="$2"
    [ "${for_base_version:0}" != "v" ] && for_base_version="v$for_base_version"
    [ "${for_base_version::-1}" != "." ] && for_base_version+="."
    shift 2
  }
  
  __tmp__="$(
    local maj min ptc upd
    
    while read -r v; do
      [[ -n "$for_base_version" && "$v" != "${for_base_version}"* ]] && continue

      if [ "${v:0:1}" = "v" ]; then
        _semver_ex_parse maj min ptc upd "" "$v"
        printf "X%04dX%04dX%04dX%04d\n" "$maj" "$min" "$ptc" "$upd"
      fi
    done < <(git tag -l) | sort | tail -1 | sed -E "s/X0+/./g" | sed "s/\.$//"
  )"
  
  _set_var "$1" "${__tmp__:1}"
}

_git_determine_latest_version() {
  local _tmp_
  if [ "$1" = "--include-previews" ]; then
    shift
    _tmp_="$(git tag -l --sort=creatordate | tail -1)"
  else
    _tmp_="$(git tag -l --sort=creatordate | grep -v "^p" | tail -1)"
  fi
  [ "${_tmp_:0:1}" = "v" ] && _tmp_="${_tmp_:1}"
  _set_var "$1" "$_tmp_"
}

_git_fetch_all_tags() {
  git fetch --tag &> /dev/null
}

# Add-Commit-Tag-Push
#
# Params:
# $1 the commit message
# $2 the tag id  (if not provided tagging is not executed)
# $3 the remote branch (if not provided push is not executed, if "-" a push with no params is executed)
#
__git_ACTP() {
  __git add .
  __git commit -m "$1"
  [ -n "$2" ] && __git_add_tag "$2"
  if [ "$3" = "-" ]; then
    __git push
    [ -n "$2" ] && __git push --tags
  elif [ -n "$3" ]; then
    __git push --set-upstream origin "$3"
    [ -n "$2" ] && __git push --tags
  fi
  true
}

# Checkouts a branch
# If the release branch doesn't exists it creet
#
# Params:
# $1: the branch to checkout
#
#
__git_auto_checkout() {
  git switch "$1" 2>/dev/null \
   || git switch -c "$1" \
   || _FATAL "Unable to checkout the branch \"$1\""
}

# Sets the receiver var with the the current git branch
#
_git_get_current_branch() {
  _set_var "$1" "$(git branch --show-current)"
}

# Merges current branch into the target one, by overriding the target.
# At the end of the operation the current branch and the target branch will be identical
#
# Params:
# $1: the target branch
#
__git_force_merge_branch() {
  local sourceBranch="$1"
  local targetBranch="$(__git branch --show-current)"
  
  _log_d "Force-Merging the branch \"$sourceBranch\" into the branch \"$targetBranch\""
  
  git log --graph --pretty=oneline --abbrev-commit --all | head -n 15
  
  _NONNULL sourceBranch targetBranch
  (
    git fetch origin "$sourceBranch" 2> /dev/null 

    #_log_on_level TRACE || exec 1>/dev/null

    DIFF="$(git diff --name-only "$sourceBranch")"
    if [ -n "$DIFF" ]; then
      git diff --name-status "$sourceBranch" | head -n 10
      git merge --no-commit --no-ff "$sourceBranch"
      echo "$DIFF" | xargs -L 1 rm -f
      __git checkout "$sourceBranch" ./ 2>&1
      __git clean -fdx
      __git add -A
      GIT_EDITOR=/bin/true __git merge --continue
    else
      git merge --no-ff "$sourceBranch"
    fi
    true
  )
  local rv="$?"
  git merge --abort &>/dev/null
  [ "$rv" -ne 0 ] && _FATAL "Error while merging the branch \"$sourceBranch\" into the branch \"$targetBranch\""
  true
}

# tag generation
# always generate an heavy tag
#
# Params:
# $1: the tag name
# $2: the optional message (autogenerated if not provided)
# $3: the optional commit id (HEAD if not provided)
#
__git_add_tag() {
  local O;[ "$1" == "-f" ] && { O="$1 "; shift; }
  # shellcheck disable=2086
  if [ -n "$3" ]; then
    __git tag ${O}-a "$1" "$3" -m "${2:-PPL-TAG-$(date +'%Y-%m-%d-%H-%M-%S')}"
  else
    __git tag ${O}"$1" -m "${2:-PPL-TAG-$(date +'%Y-%m-%d-%H-%M-%S')}"
  fi
}

# Extract the given commit tag
# 
# Options:
# --pr-tag filters for snapshot tags
#
# Params:
# $1  the output var
# $2  the commit reference
#
__git_get_commit_tag() {
  local _tmp_
  if [ "$1" = "--snapshot-tag" ]; then
    _tmp_="$(git describe --tags --abbrev=0 --exact-match --match "v*-PR-*" "$3" 2>/dev/null)"
    _set_var "$2" "$_tmp_"
  else
    _tmp_="$(__git describe --tags --abbrev=0 --exact-match "$2" 2>/dev/null)"
    _set_var "$1" "$_tmp_"
  fi
}

# Extract the parent PR of the given commit
#
# Params:
# $1  the output var
# $2  the commit reference
#
__git_get_parent_pr() {
  local _tmp_base_ _tmp_pr_
  # shellcheck disable=SC2034
  IFS=' ' read -r _tmp_base_ _tmp_pr_ < <(__git log --pretty="%P" -n 1 "$2")
  _NONNULL _tmp_base_ _tmp_pr_
  _set_var "$1" "$_tmp_pr_"
}
