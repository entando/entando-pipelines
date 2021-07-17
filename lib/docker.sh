#!/bin/bash

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
