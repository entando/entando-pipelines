#!/bin/bash

__mvn_exec() {
  local MVN="mvn"
  [ -f "./mvnw" ] && MVN="./mvnw"
  
  _log_d "Running mvn $1.."
  
  _exec_cmd \
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
  __mvn_exec --batch-mode deploy -DskipTests=true -DaltDeploymentRepository="$1::default::$2"
}
