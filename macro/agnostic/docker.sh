#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# MACRO OPERATIONS RELATED TO DOCKER
#
# Params:
# $1: action to apply
# $2: The comma delimitest list of docker builds in the form `{Dockerfile}=>{ImageAddress},...`
#
ppl--docker() {
  (
    START_MACRO "DOCKER" "$@"

    local action
    _get_arg action 1

    case "$action" in
      publish)
        local builds
        _get_arg builds 2 || _EXIT -d "Docker image publication is not enabled"
        
        [[ "${builds:0:3}" = "###" ]] && builds="${builds:3}"

        local projectArtifactId projectVersion
        ppl--docker.publish.INIT projectArtifactId projectVersion
        
        ppl--docker.publish.LOGIN
        ppl--docker.publish.BUILD_AND_PUSH_ALL "$builds" "$projectArtifactId" "$projectVersion"
        ;;
      *)
        _FATAL "Illegal docker macro action \"$action\""
        ;;
    esac
  )
}

ppl--docker.publish.INIT() {
  __ppl_enter_local_clone_dir
  __exist -f "pom.xml"
  _pkg_get "xmlstarlet" -c "xmlstarlet"
  _pom_get_project_artifact_id "$1" "pom.xml"
  _pom_get_project_version "$2" "pom.xml"
  _NONNULL "${1}" "${2}"
}

ppl--docker.publish.LOGIN() {
  _NONNULL ENTANDO_OPT_DOCKER_USERNAME ENTANDO_OPT_DOCKER_PASSWORD
  __docker login -u "$ENTANDO_OPT_DOCKER_USERNAME" --password-stdin <<<"$ENTANDO_OPT_DOCKER_PASSWORD"
}

ppl--docker.publish.BUILD_AND_PUSH_ALL() {
  local dockerBuilds="$1"
  local projectArtifactId="$2"
  local projectVersion="$3"
  local dockerFile dockerImageAddress dockerOrg dockerImageName dockerImageTag
  local dockerFileExt buildQualifier
  
  while IFS= read -r build; do
    IFS= read -r dockerFile dockerImageAddress <<<"${build//=>/$'\n'}"
    _NONNULL dockerFile
    
    dockerFileExt="${dockerFile##*.}"
    
    if [[ -n "$dockerFileExt" && "${dockerFileExt,,}" != "dockerfile" ]]; then
      buildQualifier="-$dockerFileExt"
    fi

    _docker_parse_image_address dockerOrg dockerImageName dockerImageTag "$dockerImageAddress"

    [ -z "$dockerOrg" ] && dockerOrg="$ENTANDO_OPT_DOCKER_ORG"
    _NONNULL dockerOrg
    
    [ -n "$dockerImageTag" ] && _FATAL "Please do not provide the image tag in the docker build directive as it will be automatically derived from the project information"
    
    [ "${dockerImageName:-*}" == "*" ] && dockerImageName="$projectArtifactId"
    dockerImageTag="$projectVersion"

    local finalAddr
    case "$ENTANDO_OPT_DOCKER_BUILD_QUALIFIER_POSITION" in
      after-name|"") finalAddr="$dockerOrg/${dockerImageName,,}${buildQualifier,,}:${dockerImageTag}";;
      after-tag) finalAddr="$dockerOrg/${dockerImageName,,}:${dockerImageTag}${buildQualifier,,}";;
      *) _FATAL "Invalid image qualifier \"$ENTANDO_OPT_DOCKER_BUILD_QUALIFIER_POSITION\""
    esac
    
    #_pp dockerOrg dockerImageName dockerImageTag finalAddr

    __docker build . -t "$finalAddr" -f "$dockerFile"
    __docker image inspect "$finalAddr"
    __docker push "$finalAddr"

  done <<<  "${dockerBuilds//,/$'\n'}"
}
