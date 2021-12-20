#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# MACRO OPERATIONS RELATED TO TEST ENVIRONMENT
#
# Params:
# $1: action to apply
#
# Actions
# - prepare-basic-environment  run an environment with the basic test requirements
#
ppl--env() {
  (
    START_MACRO "DOCKER" "$@"

    __ppl_enter_local_clone_dir

    local action object
    _get_arg action 1
    _get_arg object 2

    case "$action::$object" in
      "prepare::basic-test-environment") 
        ppl--env.PREPARE_ENV "$object"
        ;;
      *)
        _FATAL "Invalid action \"$action\""
        ;;
    esac
  )
}

ppl--env.PREPARE_ENV() {
  local env_name="$1"
  case "$env_name" in
    "basic-test-environment") 
      _pkg_get "docker-compose"
      local file="$HOME/.entando/ppl/entando-pipelines/resources/$env_name.yml"
      docker-compose -f "$file" build
      docker-compose -f "$file" -d mysql postgresql
      mkdir -p ./docker-cicd-result
      docker cp $(docker ps -aq --filter ancestor=entando-k8s-dbjob-test:latest):/usr/src/entando-k8s-dbjob/target ./docker-cicd-result/
      docker-compose -f docker-compose-cicd.yml down      
      ppl--env.PREPARE_ENV "basic"
      
      ;;
    *)
      _FATAL "Invalid action \"$action\""
      ;;
  esac
}
