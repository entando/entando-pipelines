#!/bin/bash

__npm_exec() {
  local SIMPLE=""; [ "$1" = "--ppl-simple" ] && { SIMPLE="$1"; shift; }
  
  _log_d "Running npm $1.."
  
  _exec_cmd \
    ${SIMPLE:+"$SIMPLE"} \
    ${PPL_OUTPUT_FILE:+--po "$PPL_OUTPUT_FILE"} \
    "npm" "$@"
}

# Sets an npm package.json property
#
# Params:
# $1 the receiver var
# $2 the project file
# $3 the property name
#
_npm_get() {
  __exist -f "$2"
  case "$3" in
    "version"|"name") _set_var "$1" "$(jq ".$3" -r < "$2")";;
    *) _FATAL "Unknown property \"$3\"";;
  esac
}

# Sets an npm package.json property
#
# Params:
# $1 the project file
# $2 the property name
# $3 the property value
#
_npm_set() {
  __exist -f "$1"
  case "$2" in
    "version"|"name") 
      # shellcheck disable=SC2094
      cat <<< "$(jq ".$2=$(_str_quote "$3")" "$1")" > "$1";;
    *) _FATAL "Unknown property \"$2\"";;
  esac
}

# Logins to an npm registry
_npm_setup_login_data() {
  (
    TMP=${ENTANDO_OPT_NPM_REPO_PROD/https:\/\//}
    TMP=${TMP/http:\/\//}
    echo "//$TMP/:_authToken=$PPL_TOKEN" > "$HOME/.npmrc"
    #cp "$HOME/.npmrc" ".npmrc"
    npm config set registry="$ENTANDO_OPT_NPM_REPO_PROD"
  )
}

_npm_clear_login_data() {
  (
    rm "$HOME/.npmrc"
    npm config del registry
  )
}

_npm_unpublish() {
  _github.remove-package "$1" "$2"
}
