#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# MACRO OPERATIONS RELATED TO NPM
#
# Params:
# $1: action to apply
#
# Actions:
# - FULL-BUILD           Executes a full and clean npm build in full respect of the lock file (which in fact is required)
#                        Options for FULL-BUILD:
#                          -public-url                    the path on which app-builder is exposed (default: /app-builder)
#                          --domain                        the path of the main application (default: /entando-de-app)
#                          --admin-console-integration     flag for the admin console integration enabling (default: false)
# - PUBLISH              Prepares the repo for publication by setting on it the proper version name
# - MTX-NPM-SCAN-{type}  Runs a type of npm scan (LINT, SASS-LINT, COVERAGE)
#
ppl--npm() {
  (
    START_MACRO "NPM" "$@"
    
    [ -n "$ENTANDO_OPT_REQUIRED_NODE_VERSION" ] && {
      _ppl_validate_command_version "node" "node -v" "$ENTANDO_OPT_REQUIRED_NODE_VERSION"
    }
    
    local action
    _get_arg action 1; shift
    
    __ppl_enter_local_clone_dir
    __exist -f "package.json"
    __exist -f "package-lock.json"
    
    case "$action" in
      "FULL-BUILD") ppl--npm.FULL-BUILD;;
      "PUBLISH") ppl---npm.PUBLISH;;
      "MTX-NPM-SCAN-LINT") ppl--npm.RUN-SCAN lint;;
      "MTX-NPM-SCAN-SASS") ppl--npm.RUN-SCAN sass-lint;;
      "MTX-NPM-SCAN-COVERAGE") ppl--npm.RUN-SCAN coverage;;
      *) __npm_exec "$@" ;;
    esac
  )
}

ppl--npm.FULL-BUILD() {
  (
    _log_i "Running the packages CI installation"
    
    __npm_exec ci
    
    export PUBLIC_URL DOMAIN
    export USE_MOCKS=false;
    export CI=false;
    export COMPONENT_REPOSITORY_UI_ENABLED=true;
    export KEYCLOAK_ENABLED=true;
    _get_arg PUBLIC_URL "--public-url" "/app-builder"; shift
    _get_arg DOMAIN "--domain" "/entando-de-app"; shift
    _get_arg LEGACY_ADMINCONSOLE_INTEGRATION_ENABLED "--admin-console-integration" "false"
    
    _log_i "Running the production build"
    __npm_exec run build --production
    
    _SOE
    
    if _ppl_is_feature_enabled "TAG-SNAPSHOT-AFTER-BUILD" true; then
      # Adds snapshot-tag to provide context data and trigger publication workflow
      ppl--release tag-snapshot-version
    else
      # Adds pseudo-snapshot-tag to provide the required context data, but it doesn't trigger the workflow
      ppl--release tag-pseudo-snapshot-version
    fi
    
    _SOE
    
    true
  ) || _SOE
}

ppl---npm.PUBLISH() {
  case "$PPL_REF_NAME" in
    v*)
      _log_i "Preparing for publication"
      
      local projectVersion="${PPL_REF_NAME:1}"
      _ppl_set_current_project_version "$projectVersion"
      ppl--npm.FULL-BUILD
      ;;
    *)
      _log_d "publication skipped"
      return 1
      ;;
  esac
}

ppl--npm.RUN-SCAN() {
  _log_i "Running the packages installation"
  __npm_exec install
  _log_i "Running $1"
  __npm_exec run "$@"
  if [[ "$?" != 0 ]]; then
    _ppl-pr-request-change "Please fix the \"$1\" issues"
  else
    true
  fi
}
