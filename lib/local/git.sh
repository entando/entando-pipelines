#/bin/bash 

_require "lib/shared/sys.sh"
_require "lib/shared/filesystem.sh"
_require "lib/shared/log.sh"
_require "lib/shared/vars.sh"



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
git.full_clone() {
  local SHALLOW_OPT=""; [ "$1" = "--shallow" ] && { SHALLOW_OPT="--depth 1"; shift; }
  local REPO_URL="$1"
  local DST_DIR="$2"
  local BRANCH="$3"
  local TOKEN="$4"

  _NONNULL REPO_URL
  [ "${REPO_URL:${#REPO_URL}-1:1}" = "/" ] && REPO_URL="${REPO_URL:0:${#REPO_URL}-1}"
  [ -z "$DST_DIR" ] && DST_DIR="${REPO_URL##*/}"
  
  (
    _log.t "Cloning \"$REPO_URL\""

    git._url_add_token REPO_URL "$REPO_URL" "$TOKEN"
    
    local FULL_DST_DIR="$DST_DIR"

    # shellcheck disable=2086
    __git clone -q $SHALLOW_OPT "$REPO_URL" "$FULL_DST_DIR"

    if [ "$?" = 0 ]; then
      __cd "$FULL_DST_DIR"
      [ -n "$BRANCH" ] && __git -c advice.detachedHead=false checkout "$BRANCH"
      __git fetch -q --tag 1>/dev/null
      _log.t "Repo \"$REPO_URL\" cloned"
    else
      local TC=" (with no token)"
      [ -n "$TOKEN" ] && TC=" (with token)"
      _FATAL "Unable to clone repo \"$REPO_URL\"${TC}"
    fi
  ) || _SOE
}


git._url_add_token() {
  local _tmp_="$2"
  local token="$3"
  if [ -n "$token" ]; then
    _tmp_="${_tmp_/:\/\/*@/:\/\/}"
    _tmp_="${_tmp_/:\/\//:\/\/$token@}"
  fi
  _set_var "$1" "$_tmp_"
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
git.set_commit_config() {
  local OPT=""
  [ "$1" = "--global" ] && { OPT="--global"; shift; }
  [ -d ".git" ] || _FATAL "Unable to find the \".git\" dir"
  git config $OPT user.name "$1"
  git config $OPT user.email "$2"
}
