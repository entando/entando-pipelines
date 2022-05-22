#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# MACRO OPERATIONS RELATED TO ENTANDO PROJECT FILES
#
# Params:
# $1: action to apply
#
# Actions:
# - FULL-BUILD        executes a full and clean npm build+test
# - PUBLISH           executes a publication
#
ppl--enp() {
  (
    START_MACRO "ENP" "$@"

    local action
    _get_arg action 1

    __ppl_enter_local_clone_dir

    if [[ "$ENTANDO_OPT_OKD_LOGIN" == "true" && -n "$ENTANDO_OPT_OKD_LOGIN_URL" ]]; then
      kube.oc-login
    fi
    
    _enp_load
    
    case "$action" in
      "FULL-BUILD") ppl--enp.FULL-BUILD;;
      "PUBLISH") ppl---enp.PUBLISH;;
      *)
        _FATAL "Invalid macro action \"$action\""
        ;;
    esac
  )
}

ppl--enp.FULL-BUILD() {
  local notagging=false; [ "$1" == "--no-tagging" ] && { notagging=true; shift; }
  
  _log_i "Building and testing"
  
  if [ -n "$ENTANDO_PRJ_BUILD_COMMAND" ]; then
    "$ENTANDO_PRJ_BUILD_COMMAND" | _summarize_stream --ppl-pg 50 "enp"
    _SOE --pipe 0

  fi
  if [ -n "$ENTANDO_PRJ_TEST_COMMAND" ]; then
    "$ENTANDO_PRJ_TEST_COMMAND" | _summarize_stream --ppl-pg 50 "enp"
    _SOE --pipe 0

  fi
  
  $notagging && return 0

  if _ppl_is_feature_enabled "TAG-SNAPSHOT-AFTER-BUILD" true; then
    # Adds snapshot-tag to provide context data and trigger publication workflow
    ppl--publication tag-git-version
    true
  else
    # Adds pseudo-snapshot-tag to provide the required context data, but it doesn't trigger the workflow
    ppl--publication tag-git-pseudo-version
    true
  fi
}

ppl---enp.PUBLISH() {
  case "$PPL_REF_NAME" in
    v*)
      # NOTE that enp pipelines doesn't actually publish an artifact,
      # they only prepare the repository for the docker publication
      
      _log_i "Preparing for publication"

      local projectVersion
      _ppl_extract_version_part projectVersion "$PPL_REF_NAME" "effective-number"
      _ppl_set_current_project_version "$projectVersion"
      ppl--enp.FULL-BUILD --no-tagging
      ;;
    *)
      _log_d "publication skipped"
      return 1
      ;;
  esac
}

