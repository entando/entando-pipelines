#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# MACRO OPERATIONS RELATED TO MAVEN
#
# Params:
# $1: action to apply
#
# Actions:
# - FULL-BUILD        executes a full and clean npm build+test
# - PUBLISH           publishes the maven artifact for development
#                     in the process, sets on it the proper version name and rebuilds the artifact
# - GA-PUBLICATION    publishes the maven artifact for general availability
#                     doesn't alter the sources like PUBLISH
# - SCAN-MVN-SONAR          Executes a full sonar scan, including the coverage report
# - SCAN-MVN-OWASP          Executes a full owasp scan
#
ppl--mvn() {
  (
    START_MACRO "MVN" "$@"

    local action
    _get_arg action 1

    __ppl_enter_local_clone_dir
    __exist -f "pom.xml"

    case "$action" in
      "FULL-BUILD")
        _log_i "Building and testing"
        
        if [ "$ENTANDO_OPT_OKD_LOGIN" == "true" ]; then
          _ppl_okd_login
        fi

        _ppl_is_feature_action "INTEGRATION-TESTS" "D" && {
          _log_i "INTEGRATION TESTS SKIPPED"
          export ENTANDO_OPT_SKIP_INTEGRATION_TESTS=true
        }
        
        if _ppl_is_feature_enabled "MVN-VERIFY"; then
          _log_i "Build mode: MVN-VERIFY"

          __mvn_exec -B verify
        elif _ppl_is_feature_enabled "MVN-INSTALL"; then
          _log_i "Build mode: MVN-INSTALL"
          
          __mvn_exec -B install
        else
          _log_i "Build mode: STANDARD"
          
          __mvn_exec clean -B test \
            ${ENTANDO_OPT_SONAR_PROJECT_KEY:+-Dsonar.projectKey="$ENTANDO_OPT_SONAR_PROJECT_KEY"} \
            org.jacoco:jacoco-maven-plugin:prepare-agent \
            org.jacoco:jacoco-maven-plugin:report \
            org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
            -Ppre-deployment-verification -Ppost-deployment-verification \
          ;
        fi
        
        _SOE
        
        _ppl_is_feature_enabled "MVN-QUARKUS-NATIVE" && {
          _log_i "Executing the quarkus native packaging"
          mvn package -Pjvm
        }
        
        true
        
        ;;
      "SCAN-MVN-SONAR")
        _log_i "Starting the sonar analysis"
        _NONNULL SONAR_TOKEN
        (
          _ppl_is_feature_action "INTEGRATION-TESTS" "D" && {
            _log_i "INTEGRATION TESTS SKIPPED"
            export ENTANDO_OPT_SKIP_INTEGRATION_TESTS=true
          }
          
          __mvn_exec -B verify ${ENTANDO_OPT_SONAR_PROJECT_KEY:+-Dsonar.projectKey="$ENTANDO_OPT_SONAR_PROJECT_KEY"} \
            org.jacoco:jacoco-maven-plugin:prepare-agent \
            org.jacoco:jacoco-maven-plugin:report \
            org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
            -Ppre-deployment-verification -Ppost-deployment-verification \
          ;
        )
        
        _ppl-set-return-var "$?"
        ;;
      "SCAN-MVN-OWASP")
        _log_i "Starting the owasp analysis"
        __mvn_exec verify -Powasp-dependency-check
        ;;
      "PUBLISH")
        case "$PPL_REF_NAME" in
          v*)
            _log_i "Publishing to the internal snapshots repo"
            
            _NONNULL ENTANDO_OPT_MAVEN_REPO_PROD
            _pkg_get "xmlstarlet" -c "xmlstarlet"
            
            #~ UPDATES the version on the MVN and REBUILDS the module
            local projectVersion="${PPL_REF_NAME:1}"
            _pom_set_project_version "$projectVersion" "./pom.xml"
            __mvn_deploy "internal-nexus" "$ENTANDO_OPT_MAVEN_REPO_PROD"
            ;;
          *)
            _log_d "publication skipped"
            return 1
            ;;
        esac
        ;;
      "GA-PUBLICATION")
        _NONNULL ENTANDO_OPT_MAVEN_REPO_GA
        __mvn_deploy --ppl-with-gpg "maven-central" "$ENTANDO_OPT_MAVEN_REPO_GA"
        ;;
      *)
        shift 3
        __mvn_exec "$@"
        ;;
    esac
  )
}

ppl--mvn.target() {
  case "$1" in
    SAVE) cp -R target "target.old.2f9b531a-a57c-45b0-a55f-01a162b5d470";;
    RESTORE) rm target; mv "target.old.2f9b531a-a57c-45b0-a55f-01a162b5d470" target;;
  esac
}
