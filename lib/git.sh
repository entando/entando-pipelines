#!/bin/bash

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
      _FATAL -t "Unable to clone repo \"$REPO_URL\"${TC}"
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
#
_git_determine_latest_version() {
  local _tmp_
  _tmp_="$(git describe --tags "$(git rev-list --tags --max-count=1)")"
  [ "${_tmp_:0:1}" = "v" ] && _tmp_="${_tmp_:1}"
  _set_var "$1" "$_tmp_"
}

_git_fetch_all_tags() {
  git fetch --tag &> /dev/null
}

__git() {
  git "$@" || _FATAL -t "git $1 failed"
}
