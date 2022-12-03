#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../base.sh"

_require "lib/shared/cli.sh"
_require "lib/shared/vars.sh"
_require "lib/shared/flagslist.sh"
_require "lib/local/macro.sh"
_require "lib/local/project.sh"
_require "lib/local/git.sh"
_require "lib/local/macro.sh"

# MACRO OPERATIONS RELATED TO MAVEN
#
macro.mvn.build() {
  (
    _log_i "Running the full-build with plan: \"$ENTANDO_OPT_FULL_BUILD_PLAN\""
    _NONNULL ENTANDO_OPT_FULL_BUILD_PLAN
    
    local MACRO_MVN_FULLBUILD_AUTH=( 
      "macro.mvn.step.full-build" "macro.mvn.step.publish-artifact" "macro.mvn.step.publish-image"
      "macro.global.docker-compose-up" "macro.global.docker-compose-down"
    )
    
    ppl.plan.run MACRO_MVN_FULLBUILD_AUTH "mvn" "$ENTANDO_OPT_FULL_BUILD_PLAN"
  )
}

# 
macro.mvn.step.full-build() {
  local TESTS=false COVERAGE=false
  _flagslist.is_flag_enabled "" "BUILD-TESTS" true && TESTS=true
  _flagslist.is_flag_enabled "" "BUILD-TESTS-COVERAGE" true && COVERAGE=true

  mvn -B clean test \
    ${ENTANDO_OPT_SONAR_PROJECT_KEY:+-Dsonar.projectKey="$ENTANDO_OPT_SONAR_PROJECT_KEY"} \
    ${COVERAGE:+org.jacoco:jacoco-maven-plugin:prepare-agent \
    org.jacoco:jacoco-maven-plugin:report \
    org.sonarsource.scanner.maven:sonar-maven-plugin:sonar} \
    ${TESTS:+-P "pre-deployment-verification"} \
  ;
}
