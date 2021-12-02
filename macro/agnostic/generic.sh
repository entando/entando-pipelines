#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# PROXY FUNCTION FOR MULTI-BUILD-SYSTEM MACRO OPERATIONS
# 
# Params:
# $1: action to apply
#
# Actions:
#  - FULL-BUILD   see equivalent on ppl--mvn|ppl--npm
#  - PUBLISH      see equivalent on ppl--mvn|ppl--npm
#  - SCAN-NPM-*   see equivalent on ppl--npm
#
ppl--generic() {
  local action project_type
  IFS=, read -r action project_type < <(
    local action project_type
    {
      START_MACRO "BUILD" "$@"
      _get_arg action 1; shift
      __ppl_enter_local_clone_dir
      __ppl_determine_current_project_type project_type
    } 1>/dev/null    
    echo -e "$action,$project_type"
  )

  case "$action" in
    "FULL-BUILD")
      case "$project_type" in
        "MVN") ppl--mvn FULL-BUILD "$@";;
        "NPM") ppl--npm FULL-BUILD "$@";;
      esac;;
    "PUBLISH")
      case "$project_type" in
        "MVN") ppl--mvn PUBLISH "$@";;
        "NPM") ppl--npm PUBLISH "$@";;
      esac;;
    SCAN-NPM-*)
      ppl--npm "$action" "$@";;
    SCAN-MVN-SONAR|SCAN-MVN-OWASP|SCAN-MVN-OWASP)
      ppl--mvn "$action" "$@";;
    SCAN-MVN-SNYK)
      ppl--scan "snyk" "$@";;
    *)
      _FATAL "Illegal scan macro action \"$action\""
      ;;
  esac
}
