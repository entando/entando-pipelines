#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# MACRO OPERATIONS RELATED TO MAVEN
#
# Params:
# $1: the ID of the macro
# $2: action to apply
# $3: directory of the project
#

ppl--mvn() {
  (
    START_MACRO "$1" "$PPL_CONTEXT"

    [ "$3" != "-" ] && __cd "$3"

    case "$2" in
      "SONAR")
        _NONNULL SONAR_TOKEN
        __mvn_exec -B verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar
        ;;
      "BUILD-AND-TEST")
        __mvn_exec -B test -Dgroups="$4"
        ;;
      "BUILD")
        __mvn_exec package -Dmaven.test.skip=true -Dgroups="$4"
        ;;
      "OWASP")
        __mvn_exec verify -Powasp-dependency-check
        ;;
      "PUBLISH")
        case "$EE_REF_NAME" in
          v*)
            _NONNULL ENTANDO_OPT_MAVEN_REPO_PROD
            __mvn_deploy "internal-nexus" "$ENTANDO_OPT_MAVEN_REPO_PROD"
            ;;
          p*)
            _NONNULL ENTANDO_OPT_MAVEN_REPO_DEVL
            __mvn_deploy "internal-nexus" "$ENTANDO_OPT_MAVEN_REPO_DEVL"
            ;;
          *)
            _log_d "publication skipped"
            return 1
            ;;
        esac
        ;;
      *)
        shift 3
        __mvn_exec "$@"
        ;;
    esac
  )
}
