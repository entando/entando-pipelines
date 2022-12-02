#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../base.sh"

_require "lib/shared/cli.sh"
_require "lib/shared/vars.sh"
_require "lib/local/macro.sh"
_require "lib/local/project.sh"
_require "lib/local/git.sh"
_require "lib/local/macro.sh"

# MACRO OPERATIONS RELATED TO MAVEN
#
macro.mvn.full-build() {
  (
    _log_i "Running the full-build with plan: \"$ENTANDO_OPT_FULL_BUILD_PLAN\""
    _NONNULL ENTANDO_OPT_FULL_BUILD_PLAN
    
    local MACRO_MVN_FULLBUILD_AUTH=( 
      "macro.mvn.build" "macro.mvn.publish-artifact" "macro.mvn.publish-image"
      "macro.global.docker-compose-up" "macro.global.docker-compose-down"
    )

    ppl.plan.run MACRO_MVN_FULLBUILD_AUTH "$ENTANDO_OPT_FULL_BUILD_PLAN"
  )
}
