#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# MACRO OPERATIONS RELATED TO CODE AND DEPENDECIES SCANS
#
# Params:
# $1: action to apply
#
ppl--scan() {
  (
    START_MACRO "SCAN" "$@"

    __ppl_enter_local_clone_dir
    __exist -f "pom.xml"

    local action
    _get_arg action 1

    case "$action" in
      snyk)
        ppl--scan.PREREQUIREMENTS
        ppl--scan.SCAN
        ;;
      *)
        _FATAL "Illegal scan macro action \"$action\""
        ;;
    esac
  )
}

ppl--scan.PREREQUIREMENTS() {
  _pkg_get nodejs -c node
  _pkg_get npm -c npm
  _pkg_is_command_available || {
    ${ENTANDO_OPT_SUDO:+"$ENTANDO_OPT_SUDO"} npm install -g snyk 1>/dev/null
  }
  _pkg_is_command_available -m snyk
}

ppl--scan.SCAN() {
  local org prj
  _get_arg -m org "--org"
  _get_arg prj "--prj"
  
  local RV=0

  _log_i "Running snyk scan.."
  
  local RESFILE="$(mktemp)"
  
  snyk test \
    --org="$org" \
    ${prj:+--project-name="$prj"} \
    --remote-repo-url="$EE_REPO_GIT_URL" \
  > "$RESFILE"
  
  RV="$?"

  if [ "$RV" != "0" ]; then
    _ppl_is_feature_enabled "ADD-REVIEW-ON-SECURITY-ERROR" && {
      _ppl-pr-request-change "Please fix the snyk issues"
    }
    
    echo "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"
    echo "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"
    _log_i "Issues detected by the scan:"
    cat "$RESFILE"
    echo "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"
    echo "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"
  fi
  
  snyk monitor \
  --org="$org" \
  ${prj:+--project-name="$prj"} \
  --remote-repo-url="$EE_REPO_GIT_URL" || true

  if [ "$RV" != "0" ]; then
    _FATAL "Snyk reported error code \"$RV\""
  fi
}
