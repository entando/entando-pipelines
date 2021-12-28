#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# EXECUTES THE CLONE AND CHECKOUT OF THE CURRENT DEFAULT REPO AND REF
# 
# Special Options:
# --token:  Overrides the default CI token. Can be useful to be able to push from the cloned repo.
#
ppl--checkout-branch() {
  (
    START_MACRO "CHECKOUT-BRANCH" "$@"

    local branchToCheckout
    
    # CLONE
    if [ -n "$PPL_HEAD_REF" ]; then
      branchToCheckout="$PPL_HEAD_REF"
    else
      branchToCheckout="$PPL_REF_NAME"
    fi
    
    _NONNULL PPL_LOCAL_CLONE_DIR PPL_CLONE_URL branchToCheckout
    _git_full_clone "$PPL_CLONE_URL" "$PPL_LOCAL_CLONE_DIR" "" "${PPL_TOKEN_OVERRIDE:-$PPL_TOKEN}"
    
    # CHECKOUT
    __cd "$PPL_LOCAL_CLONE_DIR"
    _git_auto_setup_commit_config
    
    (
      _log_on_level TRACE || exec 1>/dev/null
      git config pull.rebase false
      git -c advice.detachedHead=false checkout "$branchToCheckout"
    ) || _FATAL "Git checkout failed"
    
    _log_i "Checkout of repo \"$PPL_CLONE_URL\" and branch \"$branchToCheckout\" completed"
  )
}
