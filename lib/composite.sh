#!/bin/bash

# Extracts the latest bom version given the bom repository URL
#
# Params:
# $1: dest var
# $2: bom repo URL
#
_ppl_query_latest_bom_version() {
  local TMPDIR
  TMPDIR="$(mktemp -d)"
  local TMP
  _git_full_clone --shallow "$2" "$TMPDIR" ""
  __cd "$TMPDIR"
  _git_determine_latest_version TMP
  __cd -
  rm -rf "$TMPDIR"
  [ -n "$TMP" ] && _set_var "$1" "$TMP"
}

# Setup a custom evironment given a semicolon-delimited list of assignments
#
# WARNING: the parser interprets the backslash
# WARNING: the parser doesn't support quotes, however you can still escape the colon with the backslash ("\;")
#
# eg:
# - LEGAL:   _ppp_setup_custom_environment 'A=1;B=hey there;C=true'
# - ILLEGAL: _ppp_setup_custom_environment 'A=1;B="hey;there";C=true'
# - LEGAL:   _ppp_setup_custom_environment 'A=1;B=hey\;there;C=true'
#
_ppl_setup_custom_environment() {
  local arr
  # shellcheck disable=SC2162
  IFS=';' read -a arr <<< "$1"
  for assign in "${arr[@]}"; do
    if [ -n "$assign" ]; then
      IFS='=' read -r name value <<< "$assign"
      _set_var "$name" "$value"
      # shellcheck disable=SC2163
      export "$name"
    fi
  done
}
