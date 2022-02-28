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
    ${PPL_OUTPUT_FILE:+--po "$PPL_OUTPUT_FILE"} \
    "$MVN" "$@"
}
  
# Runs a maven deploy over the received environment params
#
# Params:
# $1: repository id
# $2: repository url
#
__mvn_deploy() {
  local GPG="true"; [ "$1" = "--ppl-with-gpg" ] && { GPG="false"; shift; }
  
  {
    echo "#####################################################################################################"
    echo "#####################################################################################################"
    echo "#####################################################################################################"
    cat "src/main/java/com/agiletec/aps/system/services/pagemodel/PageModel.java"
    echo "#####################################################################################################"
    echo "#####################################################################################################"
    echo "#####################################################################################################"
  } 1>&2
  #javap -v ./com/agiletec/aps/system/services/pagemodel/PageModel.class  | grep locked
  rm -rf target
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  rm -rf ~/.m2/repository/org/entando/
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  git branch
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  git log -1
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  git status
  echo "#####################################################################################################"  
  sha256sum "pom.xml"
  sha1sum "pom.xml"
  echo "#####################################################################################################"
  echo "#####################################################################################################"
  __mvn_exec --batch-mode clean package
  
  __mvn_exec --batch-mode javadoc:jar source:jar source:test-jar deploy \
    -DskipTests=true \
    -DaltDeploymentRepository="$1::default::$2" \
    -P prepare-for-nexus \
    -DskipPreDeploymentTests=true \
    -DskipPostDeploymentTests=true \
    -Ddependency-check.skip=true \
    -Dgpg.skip="$GPG"
}
