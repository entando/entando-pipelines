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
          ppl--publication tag-git-version
          true
        else
          # Adds pseudo-snapshot-tag to provide the required context data, but it doesn't trigger the workflow
          ppl--publication tag-git-pseudo-version
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

        ppl--mvn.post-deloyment.configure projectName projectVersion ENTANDO_OPT_TEST_NAMESPACE || _SOE
        ppl--mvn.post-deloyment.prepare-environment "$projectName" "$projectVersion" || _SOE
        ppl--mvn.post-deloyment.install-operator || _SOE
        ppl--mvn.post-deloyment.deploy-image "$projectName" "$projectVersion" || _SOE
        ppl--mvn.post-deloyment.run-test "$projectName" "$projectVersion" || _SOE
        ;;
      "PUBLISH")
        case "$PPL_REF_NAME" in
          v*)
            _log_i "Publishing to the internal snapshots repo"
            
            _NONNULL ENTANDO_OPT_MAVEN_REPO_PROD
            _pkg_get "xmlstarlet"

            #~ UPDATES the version on the MVN and REBUILDS the module
            # shellcheck disable=SC2034
            local projectVersion
            _ppl_extract_version_name_part projectVersion "$PPL_REF_NAME" "effective-name"
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

ppl--mvn.post-deloyment.configure() {
  local projectName projectVersion
  _ppl_get_current_project_artifact_id projectName
  _ppl_get_current_project_version projectVersion
  _NONNULL projectName projectVersion
  
  _set_var "$1" "$projectName"
  _set_var "$2" "$projectVersion"
  
  local ns="${2:-"$ENTANDO_OPT_TEST_NAMESPACE"}"
  [[ "$ns" == "[auto]" || -z "$ns" ]] && ns="test-${projectName}";
  [[ "${ns:0:5}" != "test-" ]] && _FATAL "The test namespace name must start with the prefix \"test-\""
  _set_var "$3" "$ns"
}

ppl--mvn.post-deloyment.deploy-image() {
  local projectName="$1" projectVersion="$2"

  _log_d "Buiding and deploying the image"
  
  _ppl_is_feature_enabled "MVN-QUARKUS-NATIVE" && {
    __mvn_exec package -B -Pjvm
  }

  ppl--docker.publish.INIT projectName projectVersion
  ppl--docker.publish.LOGIN
  ppl--docker.publish.BUILD_AND_PUSH_ALL "$ENTANDO_OPT_DOCKER_BUILDS" "$projectName" "$projectVersion"
}

ppl--mvn.post-deloyment.prepare-environment() {
  local projectName="$1" projectVersion="$2"
  
  _log_d "Setting up the post-deployment execution environment"

  local ORIGDIR="$PWD"
  
  ENTANDO_OPT_TEST_NAMESPACE="$ENTANDO_OPT_TEST_NAMESPACE"
  _ppl_provision_helm_preview_environment \
    "$projectName" "$projectVersion" \
    "$ENTANDO_OPT_TEST_NAMESPACE" "$ENTANDO_OPT_TEST_HOSTNAME_SUFFIX"

  local RV="$?"
  
  [[ "$RV" == 99 ]] && {
    _EXIT "No post-deployment setup method found, skipped"
  }
  [[ "$RV" != 0 ]] && exit "$RV"
  
  __cd "$ORIGDIR"
}

ppl--mvn.post-deloyment.install-operator() {
  _NONNULL ENTANDO_OPT_TEST_OPERATOR_GIT_REPO_URL ENTANDO_OPT_TEST_OPERATOR_VERSION
  
  # shellcheck disable=SC2034
  local _ignored_
  local local_operator_clone_dir="$HOME/.entando/ppl/operator-clone"
  local operator_project_name="${ENTANDO_OPT_TEST_OPERATOR_PROJECT_NAME:-entando-k8s-controller-coordinator}"
  rm -rf "$local_operator_clone_dir"
  
  ppl--checkout-branch.checkout \
    "$ENTANDO_OPT_TEST_OPERATOR_GIT_REPO_URL" \
    "$local_operator_clone_dir" \
    "$ENTANDO_OPT_TEST_OPERATOR_VERSION"
    
  export ENTANDO_OPT_LOG_LEVEL=TRACE
    
  _ppl_provision_helm_preview_environment \
    "$operator_project_name" "$ENTANDO_OPT_TEST_OPERATOR_VERSION" \
    "$ENTANDO_OPT_TEST_NAMESPACE" "$ENTANDO_OPT_TEST_HOSTNAME_SUFFIX"
}

ppl--mvn.post-deloyment.run-test() {
  local projectName="$1" projectVersion="$2"

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
}

ppl--mvn.target() {
  case "$1" in
    SAVE) cp -R target "target.old.2f9b531a-a57c-45b0-a55f-01a162b5d470";;
    RESTORE) rm target; mv "target.old.2f9b531a-a57c-45b0-a55f-01a162b5d470" target;;
  esac
}

# Generates the key to store the build cache
#
ppl--mvn.generate-build-cache-key() {
  local VARIABLE_NAME="$1"
  _NONNULL VARIABLE_NAME
  echo "$VARIABLE_NAME=$( sha256sum "pom.xml" --zero | cut -d' ' -f1 )"
}
