#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
. "$PROJECT_DIR/lib/base.sh"
. "$PROJECT_DIR/lib/misc.sh"
. "$PROJECT_DIR/lib/debug.sh"
}

# shellcheck disable=SC1091,SC1090
{
  # shellcheck disable=SC1090
  if [ -n "$GITHUB_ACTIONS" ]; then
    # shellcheck disable=SC1090
    while read -r fn; do
      source "$fn"
    done < <(find "$PROJECT_DIR/macro" -mindepth 2 -type f -iname "*.sh")
    [ "$1" = "--activate" ] && return 0
  else
    echo "Unsupported Pipeline implementation" 1>&2
    [ "$1" = "--activate" ] && return 77
    exit 77
  fi
}


# shellcheck disable=2034
TEST__BEFORE_RUN() {
  GIT_USER_NAME="CiCd Bot"
  GIT_USER_EMAIL="cicd@example.com"
  PPL_CONTEXT="$(cat "$PROJECT_DIR/test/resources/github-context-sample-02.json")"
  ENTANDO_CORE_BOM_REPO_URL="${ENTANDO_OPT_REPO_BOM_URL:-$TEST__ENTANDO_OPT_REPO_BOM_URL}"
}


FAILED() {
  [ "$?" = "99" ] && exit 99

  _FATAL -S 1 -99 "Test failed${1:+ (COMMENT: $1)}"
}

ASSERT() {
  (
    __VERIFY_EXPRESSION "TEST" "$@"
  ) || {
    local rv="$?"
    $ENTANDO_OPT_SHELL_ON_TEST_ASSERT && DBGSHELL -S 1
    exit "$rv"
  }
}

# Creates a test git repository
#
# Params:
# $1: the destination dir
# $2: the option topic branch name to create
# $3: the tag to apply to the test commit
#
_create-test-git-repo() {
  local dst_dir="$1"
  local branch="$2"
  local tag="$3"

  (
    set -e
    rm -rf "$dst_dir" && mkdir "$dst_dir"

    __cd "$dst_dir"

    git init
    _git_set_commit_config "the-user-name" "the-user-email@example.com"
    [ "$(git config "user.name")" = "the-user-name" ] || _FATAL "Test git repo preparation failed"
    [ "$(git config "user.email")" = "the-user-email@example.com" ] || _FATAL "Test git repo preparation failed"

    git checkout -q -b master
    echo "the-file-body" > "the-file"
    git add .
    git commit -m "TheCommit"

    git checkout -q -b develop
    echo "an-addition" >> "the-file"
    git add .
    git commit -m "TheCommit#2"

    if [ -n "$branch" ]; then
      git checkout -q -b "$branch"
      echo "another-addition" >> "the-file"
      git add .
      git commit -m "TheCommit#3"
    fi

    if [ -n "$tag" ]; then
      __git_add_tag "$tag"
    fi
  ) 1>/dev/null || _FATAL "Test git repo preparation failed"
}

TEST__GET_TLOG_COMMAND() {
  local N="$2"
  _NONNULL N
  if [ "$N" -ge 0 ]; then
    _set_var "$1" "$(sed -n "${N},${N}p" "$TEST__TECHNICAL_LOG_FILE")"
  else
    _set_var "$1" "$(tail -n$((N*-1)) "$TEST__TECHNICAL_LOG_FILE" | head -n1)"
  fi
}
