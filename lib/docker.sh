#!/bin/bash


# Runs a docker operation and summarise the output
#
# Params:
# $@: all params are forwarded to the docker command and params of _summarize_stream
#
__docker_exec() {
  local PAGE=""; [ "$1" = "--ppl-pg" ] && { PAGE="$2"; shift 2; }
  (
    _unset_all_entano_options
    __docker "$@" | _summarize_stream ${PAGE:+--ppl-pg "$PAGE"} "DOCKER-${1^^}"
    _SOE --pipe 0
  )
}

# Runs a docker operation
#
# Params:
# $@: all params are forwarded to the docker command
#
__docker() {
  _log_d "Running docker $1.."

  if [ "$TEST__EXECUTION" != "true" ]; then
    if docker "$@"; then
      _log_d "docker execution was successful"
    else
      _FATAL "Error executing docker"
    fi
  else
    echo "[DOK] docker $*" >> "$TEST__TECHNICAL_LOG_FILE"
    true
  fi
}

# Purses a docker image address
#
# Params:
# $1: the receiver var of the organization
# $2: the receiver var of the image name
# $3: the receiver var of the image tag
# $4: the source image address
#

_docker_parse_image_address() {
  local _tmp_rx_='([^/]*)/(.*)'
  [[ "$4" =~ $_tmp_rx_ ]]
  [ -n "$1" ] && _set_var "$1" "${BASH_REMATCH[1]}"
  _tmp_rx_='([^:]*):?(.*)'
  [[ "${BASH_REMATCH[2]:-$4}" =~ $_tmp_rx_ ]]
  [ -n "$2" ] && _set_var "$2" "${BASH_REMATCH[1]}"
  [ -n "$3" ] && _set_var "$3" "${BASH_REMATCH[2]}"
}

# Tells if a image is present on the registry
# registry is taken from the given address or falls back as for docker standard policies
#
# Params:
# $1: the image address
#
_docker_is_image_on_registry() {
  (DOCKER_CLI_EXPERIMENTAL=enabled __docker manifest inspect "$1" &>/dev/null)
}
