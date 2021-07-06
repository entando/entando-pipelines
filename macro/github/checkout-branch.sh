#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# EXECUTES THE CHECKOUT OF A GIVEN REPO AND BRANCH
# 
# Params:
# $1: the id of execution
# $2: the type checkout (pr, base)
# $3: the destination folder
# $4: optional git token to use instead of the one provided by the environment
#
ppl--checkout-branch() {
  (
    START_MACRO "$1" "$PPL_CONTEXT"

    local destFolder="$3"
    local forceToken="$4"
    local branchToCheckout

    # CLONE
    case "$2" in
      pr) branchToCheckout="$EE_HEAD_REF";;
      base) branchToCheckout="${EE_REF##*/}";;
      *) _FATAL "Illegal checkout type provided";;
    esac

    _NONNULL destFolder EE_CLONE_URL branchToCheckout
    _git_full_clone "$EE_CLONE_URL" "$destFolder" "" "${forceToken:-$EE_TOKEN}"
    
    # CHECKOUT    
    __cd "$destFolder"
    _git_auto_setup_commit_config
    
    (
      _log_on_level TRACE || exec 1>/dev/null
      git config pull.rebase false
      git checkout "$branchToCheckout"
    ) || _FATAL "Git checkout failed"
    
    _log_i "Checkout of repo \"$EE_CLONE_URL\" and branch \"$branchToCheckout\" completed"
  )
}
