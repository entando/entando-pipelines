#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../base.sh"

_require "lib/shared/cli.sh"
_require "lib/shared/vars.sh"
_require "lib/local/macro.sh"
_require "lib/local/project.sh"
_require "lib/local/git.sh"
_require "lib/support/github.sh"

# INITIALIZES THE ENTANDO PIPELINE EXECTUION
#
macro.init.run() {
  PPL_MACRO="macro.init.run"
  
  _cli.parse_args "--checkout" "$@"
  _cli.get_arg -m PPL_LOCAL_CLONE_DIR --lcd
  _cli.get_arg -m PPL_TYPE --type
  _cli.get_arg PPL_CHECKOUT --checkout
  _cli.get_arg PPL_CHECKOUT_TOKEN --checkout-with-token && PPL_CHECKOUT=true
  
  _github.parse_context "$PPL_CONTEXT" "PPL"
  local rv="$?"
  
  type ppl.apply_context_overrides &>/dev/null && {
    ppl.apply_context_overrides
  }
  
  _pp PPL_MACRO PPL_TYPE PPL_CLONE_URL PPL_CHECKOUT PPL_CHECKOUT_TOKEN PPL_LOCAL_CLONE_DIR PPL_BRANCH
  [ "$rv" != "0" ] && exit "$rv"
  
  $PPL_CHECKOUT && macro.init.checkout-repo "$PPL_CLONE_URL" "$PPL_LOCAL_CLONE_DIR" "$PPL_BRANCH"
  
  __cd "$PPL_LOCAL_CLONE_DIR"
  PPL_DETECTED_PROJECT_TYPE="$(prj.current.determine_type)"
  __cd -
}

# ----------------------------------------------------------------------------------------------------------------------
# SUBORDINATE FUNCTIONS
#

macro.init.checkout-repo() {
  local url="$1" lcd="$2" branch="$3" token="$4"

  # CLONE
  (git.full_clone "$url" "$lcd" "" "$token") || _FATAL "Git clone of repo \"$url\" failed"
  
  # CHECKOUT
  (
    __cd "$lcd"
    _log.on_level TRACE || exec 1>/dev/null
    git.auto_setup_local_clone
    git -c "advice.detachedHead=false" checkout "$PPL_COMMIT_ID"
  ) || _FATAL "Git checkout of commit \"$PPL_COMMIT_ID\" failed (branch \"$PPL_BRANCH\")"
  
  _log.i "Checkout of repo \"$PPL_CLONE_URL\"${branchToCheckout:+ and branch \"$branchToCheckout\"} completed"
}
