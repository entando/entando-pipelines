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
      "PUBLISH-IMAGE") ppl---enp.PUBLISH-IMAGE;;
      "SCAN-IMAGE") ppl---enp.SCAN-IMAGE;;
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
    source "$ENTANDO_PRJ_BUILD_COMMAND" | _summarize_stream --ppl-pg 50 "enp"
    _SOE --pipe 0
  fi

  if [ -n "$ENTANDO_PRJ_TEST_COMMAND" ]; then
    source "$ENTANDO_PRJ_TEST_COMMAND" | _summarize_stream --ppl-pg 50 "enp"
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
      # NOTE in this case the code doesn't actually publish an artifact,
      # it only prepares the repository for the docker publication
      
      local projectVersion
      _ppl_extract_version_part projectVersion "$PPL_REF_NAME" "effective-number"
      _ppl_set_current_project_version "$projectVersion"
      ENTANDO_PRJ_VERSION="$projectVersion"
      ppl--enp.FULL-BUILD --no-tagging
      
      if [ -n "$ENTANDO_PRJ_PUBLICATION_COMMAND" ]; then
        source "$ENTANDO_PRJ_PUBLICATION_COMMAND" | _summarize_stream --ppl-pg 50 "enp"
        _SOE --pipe 0
      else
        _log_d "publication skipped (undefined variabled)"
      fi
      
      ;;
    *)
      _log_d "publication skipped"
      return 1
      ;;
  esac
}

ppl---enp.PUBLISH-IMAGE() {
  case "$PPL_REF_NAME" in
    v*)
      _log_i "Publishing image"

      if [ -n "$ENTANDO_PRJ_IMAGE_PUBLICATION_COMMAND" ]; then
        source "$ENTANDO_PRJ_IMAGE_PUBLICATION_COMMAND" | _summarize_stream --ppl-pg 50 "enp"
        _SOE --pipe 0
      else
        _log_d "image publication skipped (undefined variabled)"
      fi

      ;;
    *)
      _log_d "image publication skipped"
      return 1
      ;;
  esac
}

ppl---enp.SCAN-IMAGE() {
  _log_d "image scan skipped (not implemented)"
  exit 0
}

# Generates the key to store the build cache
#
ppl--enp.generate-build-cache-key() {
  local VARIABLE_NAME="$1"
  _NONNULL VARIABLE_NAME

  _enp_load
  
  if [ -n "$PPL_BASE_REF" ]; then
    local snapshotVersionTag
    ppl--publication._determine_snapshot_version_tag snapshotVersionTag
    local projectVersion="${snapshotVersionTag:1}"
    _ppl_extract_version_part projectVersion "$PPL_REF_NAME" "effective-number"
    _ppl_set_current_project_version "$projectVersion"
    # shellcheck disable=SC2034
    ENTANDO_PRJ_VERSION="$projectVersion"
  fi

  local KEY=""
  if [ -n "$ENTANDO_PRJ_BUILD_KEY_COMMAND" ]; then
    KEY="$(
      source "$ENTANDO_PRJ_BUILD_KEY_COMMAND"
    )"
    
    [ -z "$KEY" ] && _FATAL "Error generating the build key"
    echo "$VARIABLE_NAME=$KEY"
  else
    _log_d "Build cache disabled"
  fi
}

# Generates the key to store the build cache
#
ppl--enp.generate-build-dir-path() {
  local VARIABLE_NAME="$1"
  _NONNULL VARIABLE_NAME
  _enp_load
  echo "$VARIABLE_NAME=$ENTANDO_PRJ_BUILD_DIR_PATH"
}
