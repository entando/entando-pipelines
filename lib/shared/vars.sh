#/bin/bash

# Sets a variable given the name and the value
#
# WARNING:
# This function can be used to set a variable of the caller's scope and this tecnique
# is commonly used to return values to the caller.
# But note that if there is a variable with same name in the local scope, the local one
# is preferred leaving the caller's variable untouched.
# That's why functions that returns values uses a special naming convention for their
# internal variables (_tmp_...).
#
# Params:
# - $1: variable to set
# - $2: value
#
_vars.set_var() {
  [ -z "$1" ] && _ess.low_level_fatal "null var_name provided"
  _vars.is_valid_var_name "$1" || _ess.low_level_fatal -S 1 "invalid var_name \"$1\" provided"
  if [ -z "$2" ]; then
    read -r -d '' "$1" <<< ""
  else
    read -r -d '' "$1" <<< "$2"
  fi

  return 0
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SUBORDINATE METHODS
#

_vars.is_valid_var_name() {
  # shellcheck disable=SC2234
  ([[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]])  # NOTE: the subshell restricts the side effects, don't remove it
}
