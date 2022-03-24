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
# - MTX-MVN-SCAN-SONAR          Executes a full sonar scan, including the coverage report
# - MTX-MVN-SCAN-OWASP          Executes a full owasp scan
# - MTX-MVN-POST-DEPLOYMENT-TESTS  Executes the tests designed to run on a preview environment
#
ppl--mvn() {
  (
    START_MACRO "MVN" "$@"

    local action
    _get_arg action 1

    __ppl_enter_local_clone_dir
    __exist -f "pom.xml"
    
    if [[ "$ENTANDO_OPT_OKD_LOGIN" == "true" && -n "$ENTANDO_OPT_OKD_LOGIN_URL" ]]; then
      kube.oc-login
    fi

    __mvn_cleanup_old
    case "$action" in
      "FULL-BUILD")
        _log_i "Building and testing"
        
        _ppl_is_feature_action "INTEGRATION-TESTS" "D" && {
          _log_i "INTEGRATION TESTS SKIPPED"
          export ENTANDO_OPT_SKIP_INTEGRATION_TESTS=true
        }
        
        if _ppl_is_feature_enabled "MVN-VERIFY"; then
          _log_i "Build mode: MVN-VERIFY"

          __mvn_exec --ppl-timestamp -B verify
        elif _ppl_is_feature_enabled "MVN-INSTALL"; then
          _log_i "Build mode: MVN-INSTALL"
          
          __mvn_exec --ppl-timestamp -B install
        else
          _log_i "Build mode: STANDARD"

          __mvn_exec --ppl-timestamp -B clean test \
            ${ENTANDO_OPT_SONAR_PROJECT_KEY:+-Dsonar.projectKey="$ENTANDO_OPT_SONAR_PROJECT_KEY"} \
            org.jacoco:jacoco-maven-plugin:prepare-agent \
            org.jacoco:jacoco-maven-plugin:report \
            org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
            -Ppre-deployment-verification \
          ;
        fi
        
        _SOE
        
        if _ppl_is_feature_enabled "MVN-QUARKUS-NATIVE"; then
          _log_i "Executing the quarkus native packaging"
          __mvn_exec -B package -Pjvm
        else
          true
        fi
        
        _SOE
        
        if _ppl_is_feature_enabled "TAG-SNAPSHOT-AFTER-BUILD" true; then
          # Adds snapshot-tag to provide context data and trigger publication workflow
          ppl--release tag-snapshot-version
          true
        else
          # Adds pseudo-snapshot-tag to provide the required context data, but it doesn't trigger the workflow
          ppl--release tag-pseudo-snapshot-version
          true
        fi
        ;;
      "MTX-MVN-SCAN-SONAR")
        _log_i "Starting the sonar analysis"
        _NONNULL SONAR_TOKEN
        # shellcheck disable=SC2030 disable=SC2031
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
      "MTX-MVN-SCAN-OWASP")
        _log_i "Starting the owasp analysis"
        __mvn_exec verify -B -Powasp-dependency-check
        ;;
      "MTX-MVN-POST-DEPLOYMENT-TESTS"|"MVN-POST-DEPLOYMENT-TESTS")
        _log_i "Starting the post-deployment task"
        
        _pkg_get "xmlstarlet"
        
        #~ postdep - deploy
        _log_d "Deploying the PR version"
        
        local projectArtifactId projectVersion
        _ppl_autoset_snapshot_version
        
        ppl--docker.publish.INIT projectArtifactId projectVersion
        ppl--docker.publish.LOGIN
        ppl--docker.publish.BUILD_AND_PUSH_ALL "$ENTANDO_OPT_DOCKER_BUILDS" "$projectArtifactId" "$projectVersion"
        
        _SOE
        
        #~ postdep - setup
        _log_d "Setting up the post-deployment execution environment"
        
        local ORIGDIR="$PWD"
        
        ENTANDO_OPT_TEST_NAMESPACE="$ENTANDO_OPT_TEST_NAMESPACE"
        _ppl_run_post-deployment-test_setup_script "$ENTANDO_OPT_TEST_NAMESPACE" "$projectArtifactId" "$projectVersion"
        [ "$?" == 99 ] && {
          _ppl_provision_helm_preview_environment ENTANDO_OPT_TEST_NAMESPACE "$ENTANDO_OPT_TEST_NAMESPACE"
        } || "$?" = 99 || _SOE
        
        __cd "$ORIGDIR"
        
        #~ postdep - exec
        _log_d "Executing the post-deployment tests"
        # shellcheck disable=SC2030 disable=SC2031
        (
          export ENTANDO_OPT_PREVIEW_TESTS=true
          export ENTANDO_OPT_TEST_NAMESPACE
          export ENTANDO_OPT_TEST_HOSTNAME_SUFFIX
          export ENTANDO_DEFAULT_ROUTING_SUFFIX="$ENTANDO_OPT_TEST_HOSTNAME_SUFFIX"
          export ENTANDO_TEST_NAMESPACE_OVERRIDE="$ENTANDO_OPT_TEST_NAMESPACE"

          __mvn_exec --ppl-timestamp -B verify -Ppost-deployment-verification
        ) || _SOE
        ;;
      "PUBLISH")
        case "$PPL_REF_NAME" in
          v*)
            _log_i "Publishing to the internal snapshots repo"
            
            _NONNULL ENTANDO_OPT_MAVEN_REPO_PROD
            _pkg_get "xmlstarlet"
            
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
        __mvn_exec -B "$@"
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
