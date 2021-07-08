#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# MACRO OPERATIONS RELATED TO MAVEN
#
# Params:
# $1: action to apply
#

ppl--mvn() {
  (
    START_MACRO "MVN" "$@"
    
    local action arg2
    _get_arg action 1
    _get_arg arg2 2
    
    __ppl_enter_local_clone_dir
    __exist -f "pom.xml"

    case "$action" in
      "SONAR")
        _log_i "Starting the sonar analysis"
        _NONNULL SONAR_TOKEN
        __mvn_exec -B verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar
        ;;
      "BUILD-AND-TEST")
        _log_i "Building and testing with group \"$arg2\""
        __mvn_exec -B test -Dgroups="$arg2"
        ;;
      "BUILD")
      _log_i "Building with group \"$arg2\""
        __mvn_exec package -Dmaven.test.skip=true -Dgroups="$arg2"
        ;;
      "OWASP")
      _log_i "Starting the owasp analysis"
        __mvn_exec verify -Powasp-dependency-check
        ;;
      "PUBLISH")
        case "$EE_REF_NAME" in
          v*)
            _log_i "Publishing to the internal releases repo"
            _NONNULL ENTANDO_OPT_MAVEN_REPO_PROD
            __mvn_deploy "internal-nexus" "$ENTANDO_OPT_MAVEN_REPO_PROD"
            ;;
          p*)
            _log_i "Publishing to the internal snapshots repo"
            _NONNULL ENTANDO_OPT_MAVEN_REPO_DEVL
            
            _pkg_get "xmlstarlet" -c "xmlstarlet"
            
            #~ UPDATES the version on the POM and REBUILDS the module
            local versionToSet="${EE_REF_NAME:1}"
            _pom_set_project_version "$versionToSet" "./pom.xml"
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
