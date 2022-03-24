#!/bin/bash

# Successfully runs a maven command or fatals.
# Unless otherise specified it summarize the output.
#
# Special Options:
# --ppl-simple:     doesn't summarize the output
# --ppl-timestamp:  adds a timestamp to every output line
#
__mvn_exec() {
  local SIMPLE=""; [ "$1" = "--ppl-simple" ] && { SIMPLE="$1"; shift; }
  local TS=""; [ "$1" = "--ppl-timestamp" ] && { TS="$1"; shift; }
  local MVN="mvn"
  [ -f "./mvnw" ] && MVN="./mvnw"
  
  _log_d "Running mvn $1${2:+ $2}${3:+ $3}[..]"
  
  _exec_cmd \
    ${SIMPLE:+"$SIMPLE"} \
    ${TS:+"$TS"} \
    --hide "Progress.* kB" \
    --hide "Error message = null" \
    --pe \
    ${PPL_OUTPUT_FILE:+--po "$PPL_OUTPUT_FILE"} \
    "$MVN" "$@" || {
      _FATAL "mvn command failed with status \"$?\""
    }
}
  
# Runs a maven deploy over the received environment params
#
# Params:
# $1: repository id
# $2: repository url
#
__mvn_deploy() {
  local GPG="true"; [ "$1" = "--ppl-with-gpg" ] && { GPG="false"; shift; }
  
  __mvn_exec --batch-mode javadoc:jar source:jar source:test-jar deploy \
    -DskipTests=true \
    -DaltDeploymentRepository="$1::default::$2" \
    -P prepare-for-nexus \
    -DskipPreDeploymentTests=true \
    -DskipPostDeploymentTests=true \
    -Ddependency-check.skip=true \
    -Dgpg.skip="$GPG"
}


__mvn_cleanup_old() {
  rm -rf "$HOME/.m2/repository/org/entando"
}
