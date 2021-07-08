#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# MACRO OPERATIONS RELATED TO DOCKER
#
# Params:
# $1: action to apply
#
ppl--docker() {
  (
    START_MACRO "DOCKER" "$@"

    _pkg_get "xmlstarlet" -c "xmlstarlet"

    __ppl_enter_local_clone_dir

    local action
    _get_arg action 1


    case "$action" in
      publish)
        local dockerUsename dockerPassword projectArtifactId projectVersion

        _get_arg dockerfiles 1 "${ENTANDO_OPT_DOCKERFILES:-"Dockerfile"}"
        _NONNULL dockerfiles

        dockerUsename="${DOCKER_USERNAME}"
        dockerPassword="${DOCKER_PASSWORD}"
        _NONNULL dockerUsename dockerPassword

        ppl--docker.publish.DO_LOGIN "$dockerUsename" "$dockerPassword"
        _extract_project_information_from_pom "$EE_LOCAL_CLONE_DIR" projectArtifactId projectVersion
        ppl--docker.publish.PUBLISH_DOCKER_IMAGES "$dockerUsename" "$projectArtifactId" "$projectVersion" "$dockerfiles"
        ;;
      *)
        _FATAL "Illegal bom action \"$action\""
        ;;
    esac
  )
}


ppl--docker.publish.DO_LOGIN() {
  if [ "$TEST__EXECUTION" != "true" ]; then
    docker login -u "$1" -p "$2" || _FATAL "Docker login failed"
  else
    echo "[DOK] docker login -u $1 -p $2" >> "$TEST__TECHNICAL_LOG_FILE"
    true
  fi
}

ppl--docker.publish.BUILD_TAG() {

  local suffix=$5

  suffix=$(echo "$5" | tr "." -)
  _set_var "$1" "$2/$3$suffix:$4"
}

ppl--docker.publish.PUBLISH_DOCKER_IMAGES() {

  regex='(Dockerfile)(.*)'

  local imageTag dockerOrg="$1" imageName="$2" imageVersion="$3" dockerfiles="$4" dockerfilesArray
  _NONNULL dockerOrg imageName imageVersion dockerfiles

  # TODO: CHECK IF IT IS A v TAG?

  IFS=',' read -ra dockerfilesArray <<< "$dockerfiles"
  for dockerfile in "${dockerfilesArray[@]}"; do
    [[ $dockerfile =~ $regex ]]
    ppl--docker.publish.BUILD_TAG imageTag "$org" "$artifact" "$version" "${BASH_REMATCH[2]}"

    if [ "$TEST__EXECUTION" != "true" ]; then
      docker build . -t "$imageTag" -f "$dockerfile" && docker push "$imageTag"
    else
      echo "[DOK]  docker build . -t $imageTag -f $dockerfile && docker push $imageTag"
      true
    fi
  done
}
