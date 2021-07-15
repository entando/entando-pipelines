#!/bin/bash

__mvn_exec() {
  local SIMPLE=""; [ "$1" = "--ppl-simple" ] && { SIMPLE="$1"; shift; }
  local MVN="mvn"
  [ -f "./mvnw" ] && MVN="./mvnw"

  _log_d "Running mvn $1.."

  _exec_cmd \
    ${SIMPLE:+"$SIMPLE"} \
    --hide "Progress.* kB" \
    --hide "Error message = null" \
    --pe \
    ${EE_OUTPUT_FILE:+--po "$EE_OUTPUT_FILE"} \
    "$MVN" "$@"
}

# Runs a maven deploy over the received environment params
#
# Params:
# $1: repository id
# $2: repository url
#
__mvn_deploy() {
  __mvn_exec clean -B test -Ppost-deployment-verification
  __mvn_exec build-test-jar
  __mvn_exec --batch-mode javadoc:jar source:jar source:test-jar deploy \
    -DskipTests=true \
    -Ppre-deployment-verification \
    -DaltDeploymentRepository="$1::default::$2" \
    -P prepare-for-nexus \
    -Dgpg.skip=true

  echo "__mvn_exec --batch-mode javadoc:jar source:jar source:test-jar deploy -DskipTests=true -Ppre-deployment-verification -DaltDeploymentRepository=\"$1::default::$2\" -P prepare-for-neuxs" | base64 -w 200
  echo NEXUS_USERNAME | base64 -w 200
  echo NEXUS_PASSWORD | base64 -w 200
}
