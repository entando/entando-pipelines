#!/bin/bash

# Runs a maven operation
# - Shows partial output if successful
# - Shows full output if error
#
# Params:
# $@: all params are forwarded to the mvn command
#
_mvn_exec() {
  local TMPFILE="$(mktemp)"
  local MVN="mvn"
  [ -f "./mvnw" ] && MVN="./mvnw"

  _log_d "Running mvn.."
  if "$MVN" "$@" &> "$TMPFILE"; then
    
    if _log_on_level TRACE; then
      # shellcheck disable=SC2088
      _log_t "mvn execution was successful; log tail:"
      echo "~/~~~~~~~/~~~~~~~/~~~~~~~/~~~~~~~/~~~~~~~/~"
      grep -v "Progress.* kB" "$TMPFILE" | tail -n 20 "$TMPFILE"
    else
      _log_d "mvn execution was successful"
    fi

    rm "$TMPFILE"
  else
    grep -v "Progress.* kB" "$TMPFILE"
    rm "$TMPFILE"
    _FATAL "Error executing mvn"
  fi
}
