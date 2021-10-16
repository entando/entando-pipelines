#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# MACRO OPERATIONS RELATED TO ARTIFACT AND IMAGE BUILDING
#
# Params:
# $1: action to apply
#
ppl--generic() {
  (
    START_MACRO "BUILD" "$@" &>/dev/null

    local action
    _get_arg action 1; shift
    
    local project_type
    __ppl_enter_local_clone_dir
    _ppl_determine_current_project_type project_type
    __cd -

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
      *)
        _FATAL "Illegal scan macro action \"$action\""
        ;;
    esac
  )
}
