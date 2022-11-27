#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../base.sh"

_require "lib/shared/cli.sh"
_require "lib/shared/vars.sh"
_require "lib/local/macro.sh"
_require "lib/local/project.sh"

# INITIALIZES THE ENTANDO PIPELINE EXECTUION
#
macro.init.run() {
  _cli.parse_args "--checkout" "$@"
  _cli.get_arg action 1; shift
  _cli.get_arg -m PPL_LOCAL_CLONE_DIR --lcd
  _cli.get_arg -m PPL_TYPE --type=mvn \
  _cli.get_arg PPL_MATRIX_VAR --matrix-var
  _cli.get_arg PPL_FEATURES_VAR --features-var \
  _cli.get_arg PPL_CHECKOUT --checkout \
  _cli.get_arg PPL_CHECKOUT_TOKEN CHECKOUT_TOKEN --checkout-with-token && PPL_CHECKOUT=true

  ppl.enter_local_clone_dir "$PPL_LOCAL_CLONE_DIR"

  local project_type="$(prj.current.determine_type)"
  _NONNULL project_type
  
  
  $PPL_CHECKOUT && macro.init.checkout
  
  _pp project_type

}

# ----------------------------------------------------------------------------------------------------------------------
# SUBORDINATE FUNCTIONS
#

macro.init.checkout() {
  local url="$1" lcd="$2" branch="$3" token="$4"

  # CLONE
  git.full.clone "$url" "$lcd" "" "$token"
  
  # CHECKOUT
  (
    __cd "$lcd"
    _log_on_level TRACE || exec 1>/dev/null
    git config pull.rebase false
    git -c advice.detachedHead=false checkout "$branch"
  ) || _FATAL "Git checkout failed"

  ppl--checkout-branch.checkout "$PPL_CLONE_URL" "$PPL_LOCAL_CLONE_DIR" "$branchToCheckout" "${PPL_TOKEN_OVERRIDE:-$PPL_TOKEN}"
  ppl--checkout-branch.finalize
}
