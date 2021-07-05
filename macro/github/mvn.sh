#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

ppl--mvn() {
  (
    START_MACRO "$1" "$PPL_CONTEXT"
    shift
    
    case "${EE_CURRENT_MACRO_PREFIX}${EE_CURRENT_MACRO}" in
      "SONAR")
        _NONNULL SONAR_TOKEN
        __mvn_exec -B verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar
        ;;
      "BUILD-AND-TEST")
        __mvn_exec -B test -Dgroups="$2"
        ;;
      "BUILD")
        __mvn_exec package -Dmaven.test.skip=true -Dgroups="$2"
        ;;
      "OWASP")
        __mvn_exec verify -Powasp-dependency-check
        ;;
      "INTERNAL-PUBLICATON")
        _NONNULL ENTANDO_OPT_MAVEN_REPO_DEVL
        __mvn_deploy "internal-nexus" "$ENTANDO_OPT_MAVEN_REPO_PROD"
        ;;
      "GENERAL-PUBLICATON")
        _NONNULL ENTANDO_OPT_MAVEN_REPO_PROD
        __mvn_deploy "maven-central" "$ENTANDO_OPT_MAVEN_REPO_PROD"
        ;;
      *)
        __mvn_exec "$@"
        ;;
    esac
  )
}
