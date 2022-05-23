#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# PROXY FUNCTION FOR MULTI-BUILD-SYSTEM MACRO OPERATIONS
# 
# Params:
# $1: action to apply
#
# Actions:
#  - FULL-BUILD   see equivalent on ppl--mvn|ppl--npm
#  - PUBLISH      see equivalent on ppl--mvn|ppl--npm
#  - MTX-MVN-SCAN-*   see equivalent on ppl--npm
#  - MTX-NPM-SCAN-*   see equivalent on ppl--npm
#  - MTX-SCAN-SNYK    runs a snyk scan (see ppl--scan)
#  - GENERATE-BUILD-CACHE-KEY generate the key to store the build cache
#  - GENERATE-BUILD-TARGET-DIR generates statement to set the target dir
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
        "ENP") ppl--enp FULL-BUILD "$@";;
      esac;;
    "PUBLISH")
      case "$project_type" in
        "MVN") ppl--mvn PUBLISH "$@";;
        "NPM") ppl--npm PUBLISH "$@";;
        "ENP") ppl--enp PUBLISH "$@";;
      esac;;
    "POST-DEP-TESTS")
      case "$project_type" in
        "MVN") ppl--mvn POST-DEP-TESTS "$@";;
        "NPM") ppl--npm POST-DEP-TESTS "$@";;
        "ENP") ppl--enp POST-DEP-TESTS "$@";;
      esac;;
    MTX-NPM-SCAN-*)
      ppl--npm "$action" "$@";;
    MTX-MVN-SCAN-SONAR|MTX-MVN-SCAN-OWASP|MTX-MVN-POST-DEPLOYMENT-TESTS)
      ppl--mvn "$action" "$@";;
    "MTX-SCAN-SNYK")
      ppl--scan "snyk" "$@";;
    "GENERATE-BUILD-CACHE-KEY")
      START_SIMPLE_MACRO "$action" "$@"
      _get_arg -m VARIABLE_NAME 2
      
      __ppl_enter_local_clone_dir > /dev/null
      case "$project_type" in
        "MVN") ppl--mvn.generate-build-cache-key "$VARIABLE_NAME";;
        "NPM") _FATAL "Not implemented";;
      esac;;
    "GENERATE-BUILD-TARGET-DIR")
      START_SIMPLE_MACRO "$action" "$@"
      _get_arg -m VARIABLE_NAME 2
      
      __ppl_enter_local_clone_dir > /dev/null
      case "$project_type" in
        "MVN") echo "$VARIABLE_NAME=target";;
        "NPM") _FATAL "Not implemented";;
        "ENP") echo "$VARIABLE_NAME=build";;
      esac;;
    *)
      _FATAL "Invalid macro action \"$action\""
      ;;
  esac
}
