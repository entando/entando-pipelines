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
        _mvn_exec -B verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar
        ;;
      "BUILD-AND-TEST")
        _mvn_exec -B test -Dgroups="$2"
        ;;
      "OWASP")
        #_mvn_exec mvn org.owasp:dependency-check-maven:6.2.2:check -D
        _mvn_exec verify -Powasp-dependency-check
        ;;
      *)
        _mvn_exec "$@"
        ;;
    esac
  )
}
