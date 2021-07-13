#!/bin/bash

# Runs a maven operation
# - Shows partial output if successful
# - Shows full output if error
#
# Params:
# $@: all params are forwarded to the mvn command
#
# __mvn_exec() {
#   local TMPFILE="$(mktemp)"
#   local MVN="mvn"
#   [ -f "./mvnw" ] && MVN="./mvnw"
# 
#   _log_d "Running mvn $1.."
#   if "$MVN" "$@" &> "$TMPFILE"; then
#     
#     if _log_on_level TRACE; then
#       _log_t "mvn execution was successful; log tail:"
#       shellcheck disable=SC2088
#       echo "~/~~~~~~~/~~~~~~~/~~~~~~~/~~~~~~~/~~~~~~~/~"
#       grep -v "Progress.* kB" "$TMPFILE" | tail -n 20 "$TMPFILE"
#     else
#       _log_d "mvn execution was successful"
#     fi
# 
#     rm "$TMPFILE"
#   else
#     grep -v "Progress.* kB" "$TMPFILE"
#     rm "$TMPFILE"
#     sleep 0.3
#     _FATAL "Error executing mvn"
#   fi
# }

__mvn_exec() {
  local MVN="mvn"
  [ -f "./mvnw" ] && MVN="./mvnw"
  
  _log_d "Running mvn $1.."
  
  _exec_cmd \
    --hide "Progress.* kB" \
    --hide "Error message = null" \
    --pe \
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
