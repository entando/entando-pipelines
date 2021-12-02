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

# Logins to an OKD instance given the related OKD variables
#
# Required environment variables:
#  ENTANDO_OPT_OKD_LOGIN_URL        the url of the OKD instance
#  ENTANDO_OPT_OKD_LOGIN_TOKEN      the tocken to use for the login operation
#  ENTANDO_OPT_OKD_LOGIN_NAMESPACE  the namespace to use
#
# Optional environment variables:
#   ENTANDO_OPT_OKD_LOGIN_INSECURE  forces an TLS-insecure login (default: false)
#   ENTANDO_OPT_OKD_CLI_URL         the URL from which the download tool should be downloaded
#                                   Note that this is a semicolon-delimited list, where the first element
#                                   is the url and the others are the optional curl options
#
_ppl_okd_login() {
  _NONNULL ENTANDO_OPT_OKD_LOGIN_URL ENTANDO_OPT_OKD_LOGIN_TOKEN ENTANDO_OPT_OKD_LOGIN_NAMESPACE
  
  _pkg_get --tar-install "$ENTANDO_OPT_OKD_CLI_URL" "oc" -c "oc"
  
  if [ "${ENTANDO_OPT_OKD_LOGIN_INSECURE:-}" == "true" ]; then
    local INSECURE=true
  else
    local INSECURE=false
  fi
  
  oc login --insecure-skip-tls-verify="$INSECURE" --token="$ENTANDO_OPT_OKD_LOGIN_TOKEN" --server="$ENTANDO_OPT_OKD_LOGIN_URL" || {
    _FATAL "Unable to login to \"$ENTANDO_OPT_OKD_LOGIN_URL\""
  }
  oc project "$ENTANDO_OPT_OKD_LOGIN_NAMESPACE" || {
    _FATAL "Unable to switch to namespace \"$ENTANDO_OPT_OKD_LOGIN_NAMESPACE\""
  }
}
