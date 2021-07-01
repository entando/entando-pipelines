#!/bin/bash


# Runs an arbitrary git command and FATALS if it fails
#
__git() {
  git "$@" || _FATAL "git $1 failed"
}

# Clones a repository and the tags
#
# Params:
# $1: repository url
# $2: optional dest dir or ""
# $3: optional token
#
_git_full_clone() {
  (
    local SHALLOW_OPT=""; [ "$1" = "--shallow" ] && { SHALLOW_OPT="--depth 1"; shift; }
    local REPO_URL="$1"
    local DST_DIR="$2"
    local TOKEN="$3"
    
    _log_t "Cloning \"$REPO_URL\"" 

    _NONNULL REPO_URL

    if [ -z "$DST_DIR" ]; then
      DST_DIR="${REPO_URL##*/}"
    fi
    _url_add_token REPO_URL "$REPO_URL" "$TOKEN"
    # shellcheck disable=2086
    git clone -q $SHALLOW_OPT "$REPO_URL" "$DST_DIR"

    if [ "$?" = 0 ]; then
      (
        set -e
        cd "$DST_DIR"
        git fetch -q --tag 1>/dev/null
      )
      _log_t "Repo \"$REPO_URL\" cloned"
    else
      local TC=" (with no token)"
      [ -n "$TOKEN" ] && TC=" (with token)"
      _FATAL "Unable to clone repo \"$REPO_URL\"${TC}"
    fi
  )
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

# Returns the version tagged on the latest commit
# Notes that the command actively filters out the preview versions
#
_git_determine_latest_version() {
  local _tmp_
  _tmp_="$(git tag --sort=committerdate | grep -v "^p" | tail -1)"
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
# $3 the remote branch (if not provided pushis not executed)
#
__git_ACTP() {
  __git add .
  __git commit -m "$1"
  [ -n "$2" ] && __git tag "$2"
  [ -n "$3" ] && { 
    __git push --set-upstream origin "$3"
    [ -n "$2" ] && __git push --tags
  }
}

# Checkouts a branch
# If the release branch doesn't exists it creet
#
# Params:
# $1: the receiver var of the designated release branch
# $2: the reference version
#
# The business rule is simple:
# - Versions X.Y.Z are released under the branch "release/X.Y.0"
#
__git_auto_checkout() {
  git switch "$1" 2>/dev/null \
   || git switch -c "$1" \
   || _FATAL "Unable to checkout the release branch \"$1\""

  __git fetch --tag &> /dev/null
}

# Sets the receiver var with the the current git branch 
#
_git_get_current_branch() {
  _set_var "$1" "$(git branch --show-current)"
}

# No-conflict-merge where the contents from the A branch are always preferred
#
# Params:
# $1: the A branch
# $2: the B branch
#
__git_force_merge_of_A_into_B() {
  {
    git checkout "$2" && git merge "$1"    
    if $? != 0; then
      # Fall-forward to a forced merge
      git checkout "$1" \
      && git merge -s ours "$2" \
      && git checkout "$2" \
      && git merge "$1"
    fi
  } 1>/dev/null || _FATAL "Error while merging the branch \"$1\" into the branch \"$2\""
}
