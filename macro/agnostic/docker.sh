#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# MACRO OPERATIONS RELATED TO DOCKER
#
# Params:
# $1: action to apply
#
# Actions
# - publish:  Builds one or more artifacts, image and pushes it to the image regitry.
#             Mandatory Vars:
#              - ENTANDO_OPT_DOCKER_ORG
#              - ENTANDO_OPT_DOCKER_USERNAME
#              - ENTANDO_OPT_DOCKER_PASSWORD
#
ppl--docker() {
  (
    START_MACRO "DOCKER" "$@"

    __ppl_enter_local_clone_dir
    
    case "$(__ppl_determine_current_project_type --print)" in
      "MVN") _pkg_get "xmlstarlet";;
      "NPM") _pkg_get "jq";;
      "ENP") _enp_load;;
      *) _FATAL  "Unable to detect the project type"
    esac
    
    local action
    _get_arg action 1
    
    local builds="$ENTANDO_OPT_DOCKER_BUILDS"
    [ -z "${builds}" ] && _EXIT "Docker image processing is not enabled (empty ENTANDO_OPT_DOCKER_BUILDS)"
    
    local projectName projectVersion
    ppl--docker.publish.INIT projectName projectVersion
    
    if [[ -n "$PPL_REF_NAME" ]]; then
      _ppl_extract_version_part projectVersion "$PPL_REF_NAME" "effective-number"
      _ppl_set_current_project_version "$projectVersion"
    fi
    
    case "$action" in
      publish)
        ppl--docker.publish.LOGIN
        ppl--docker.publish.FOR_ALL_BUILDS "$ENTANDO_OPT_DOCKER_BUILDS" \
            ppl--docker.publish.BUILD_AND_PUSH "Build" "$projectName" "$projectVersion"
        ;;
      scan)
        ppl--docker.publish.FOR_ALL_BUILDS "$ENTANDO_OPT_DOCKER_BUILDS" \
            ppl--docker.publish.SCAN "Scan" "$projectName" "$projectVersion"
        ;;
      *)
        _FATAL "Invalid docker macro action \"$action\""
        ;;
    esac
  )
}

ppl--docker.publish.FOR_ALL_BUILDS() {
  local builds="$1" projectName="$4" projectVersion="$5"
  local dockerFile imageAddress
  while IFS= read -r build; do
    ppl--docker.publish.DETERMINE_BUILD_INFO dockerFile imageAddress "$build" "$projectName" "$projectVersion"
    _log_i "$3 \"$build\" (\"$dockerFile\", \"$imageAddress\")"
    _pp dockerFile imageAddress projectName projectVersion build
    __exist -f "$dockerFile"
    "$2" "$dockerFile" "$imageAddress"
  done <<< "${builds//,/$'\n'}"
}

ppl--docker.publish.INIT() {
  _ppl_get_current_project_name "$1"
  _ppl_get_current_project_version "$2"
  
  _NONNULL "${1}" "${2}"
  
  _ppl_is_feature_enabled "MVN-QUARKUS-NATIVE" && {
    __mvn_exec package -B -Pjvm
  }
}
ppl--docker.publish.LOGIN() {
  if [ -n "$ENTANDO_OPT_DOCKER_ALT_LOGIN_URL" ]; then
    _NONNULL ENTANDO_OPT_DOCKER_ALT_USERNAME ENTANDO_OPT_DOCKER_ALT_PASSWORD
    __docker login "$ENTANDO_OPT_DOCKER_ALT_LOGIN_URL" \
        --username "$ENTANDO_OPT_DOCKER_ALT_USERNAME" \
        --password-stdin <<< "$ENTANDO_OPT_DOCKER_ALT_PASSWORD"
  fi
  
  _NONNULL ENTANDO_OPT_DOCKER_USERNAME ENTANDO_OPT_DOCKER_PASSWORD
  __docker login -u "$ENTANDO_OPT_DOCKER_USERNAME" --password-stdin <<<"$ENTANDO_OPT_DOCKER_PASSWORD"
}

ppl--docker.publish.DETERMINE_BUILD_INFO() {
  local dockerBuild="$3"
  local projectName="$4"
  local projectVersion="$5"
  local _dockerFile dockerImageAddress dockerOrg dockerImageName dockerImageTag
  local dockerFileExt buildQualifier
  
  IFS=',' read -r _dockerFile dockerImageAddress <<<"${dockerBuild//=>/,}"
  _NONNULL _dockerFile
  
  if [ "${dockerImageAddress:0:1}" = "[" ]; then
    ENTANDO_OPT_DOCKER_BUILD_QUALIFIER_POSITION=${dockerImageAddress:1:-1}
    dockerImageAddress=""
  elif [ "${dockerImageAddress:0:1}" != "" ]; then
    ENTANDO_OPT_DOCKER_BUILD_QUALIFIER_POSITION="simple"
  fi
  
  dockerFileExt="${_dockerFile##*.}"
  
  if [[ -n "$dockerFileExt" && "${dockerFileExt,,}" != "dockerfile" ]]; then
    buildQualifier="-$dockerFileExt"
  fi

  _docker_parse_image_address dockerOrg dockerImageName dockerImageTag "$dockerImageAddress"
  
  [ -z "$dockerOrg" ] && dockerOrg="$ENTANDO_OPT_DOCKER_ORG"
  _NONNULL dockerOrg
  
  [ -n "$dockerImageTag" ] && _FATAL \
      "Please do not provide the image tag in the docker build directive" \
      "as it will be automatically derived from the project information"
  
  [ "${dockerImageName:-*}" == "*" ] && dockerImageName="$projectName"
  dockerImageTag="$projectVersion"
  
  local finalAddr
  case "$ENTANDO_OPT_DOCKER_BUILD_QUALIFIER_POSITION" in
    simple) finalAddr="$dockerOrg/${dockerImageName,,}:${dockerImageTag}";;
    after-name|"") finalAddr="$dockerOrg/${dockerImageName,,}${buildQualifier,,}:${dockerImageTag}";;
    after-tag) finalAddr="$dockerOrg/${dockerImageName,,}:${dockerImageTag}${buildQualifier,,}";;
    *) _FATAL "Invalid image qualifier position \"$ENTANDO_OPT_DOCKER_BUILD_QUALIFIER_POSITION\""
  esac

  _set_var "$1" "$_dockerFile"
  _set_var "$2" "$finalAddr"
}

ppl--docker.publish.BUILD_AND_PUSH() {
  ppl--docker.is_release_version_number "$2" && {
    _docker_is_image_on_registry "$2" && {
      _FATAL "Overwriting a release image is not allowed"
    }
  }

  __docker_exec --ppl-pg 5000 build . -t "$2" -f "$1"
  __docker_exec --ppl-pg 5000 image inspect "$2"
  __docker_exec --ppl-pg 5000 push "$2"
}

ppl--docker.publish.SCAN() {
  ppl--scan snyk-container "$2" "$1"
}


# Tells if a docker image tag is a release tag
#
ppl--docker.is_release_version_number() {
  local ignore tag
  # shellcheck disable=SC2034
  IFS=':' read -r ignore tag <<<"$1"
  _NONNULL tag
  _ppl_is_release_version_number "$tag"
}
