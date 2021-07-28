#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# EXECUTES THE CHECKOUT OF A GIVEN REPO AND BRANCH
# 
# Params:
# $1: the type checkout (pr, base)
#
ppl--checkout-branch() {
  (
    START_MACRO "CHECKOUT-BRANCH" "$@"

    local branchToCheckout
    _get_arg action 1
    
    # CLONE
    if [ -n "$EE_HEAD_REF" ]; then
      branchToCheckout="$EE_HEAD_REF"
    else
      branchToCheckout="${EE_REF##*/}"
    fi

    _NONNULL EE_LOCAL_CLONE_DIR EE_CLONE_URL branchToCheckout
    _git_full_clone "$EE_CLONE_URL" "$EE_LOCAL_CLONE_DIR" "" "${EE_TOKEN_OVERRIDE:-$EE_TOKEN}"
    
    # CHECKOUT    
    __cd "$EE_LOCAL_CLONE_DIR"
    _git_auto_setup_commit_config
    
    (
      _log_on_level TRACE || exec 1>/dev/null
      git config pull.rebase false
      git -c advice.detachedHead=false checkout "$branchToCheckout"
    ) || _FATAL "Git checkout failed"
    
    _log_i "Checkout of repo \"$EE_CLONE_URL\" and branch \"$branchToCheckout\" completed"
  )
}
