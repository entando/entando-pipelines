#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# EXECUTES THE CHECKOUT OF A GIVEN REPO AND BRANCH
# 
# Params:
# $1: the destination folder
# $2: optional git tocket to use instead of GIT_TOKEN
# 
# Expected ENV:
# - GIT_USER_NAME, GIT_USER_EMAIL
# - EE_HEAD_REF    (github.head_ref)
# - EE_CLONE_URL   (github.event.pull_request.base.repo.clone_url)
#
ppl--checkout-pr-branch() {
  (
    START_MACRO "CHECKOUT-PR-BRANCH" "$PPL_CONTEXT"

    local destFolder="$1"
    local forceToken="$2"

    _NONNULL destFolder EE_HEAD_REF EE_CLONE_URL PPL_TOKEN

    _git_full_clone "$EE_CLONE_URL" "$destFolder" "${forceToken:-$PPL_TOKEN}"
    __cd "$destFolder"
    _git_auto_setup_commit_config
    (
      _log_on_level TRACE || exec 1>/dev/null
      git config pull.rebase false
      git checkout "$EE_HEAD_REF"
    ) || _FATAL "Git checkout failed"
    
    _log_i "Checkout of repo \"$EE_CLONE_URL\" and branch \"$EE_HEAD_REF\" completed"
  )
}
