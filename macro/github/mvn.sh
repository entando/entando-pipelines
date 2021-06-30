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
      "NEXUS-DEPLOY")
        _mvn_exec --batch-mode deploy -DskipTests=true -DaltDeploymentRepository=internal-nexus::default::https://nexus-jx.apps.serv.run/repository/ngpl-maven-releases/
        ;;
      "MAVEN-CENTRAL-DEPLOY")
        _mvn_exec --batch-mode deploy -DskipTests=true -DaltDeploymentRepository=maven-central::default::https://oss.sonatype.org/service/local/staging/deploy/maven2/
        ;;
      *)
        _mvn_exec "$@"
        ;;
    esac
  )
}
