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
#                     in the process, sets on it the proper version number and rebuilds the artifact
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
        
        if [ -n "$ENTANDO_OPT_TEST_COMPOSE_FILE" ]; then
          docker-compose -f "$ENTANDO_OPT_TEST_COMPOSE_FILE" up -d 2>&1 | _summarize_stream --ppl-pg 500 "COMPOSE-UP"
        fi
        
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
        
        if [ -n "$ENTANDO_OPT_TEST_COMPOSE_FILE" ]; then
          docker-compose -f "$ENTANDO_OPT_TEST_COMPOSE_FILE" down 2>&1 | _summarize_stream --ppl-pg 500 "COMPOSE-DOWN"
        fi
        
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
        __mvn_exec -B verify -Powasp-dependency-check
        ;;
      "MTX-MVN-POST-DEPLOYMENT-TESTS"|"MVN-POST-DEPLOYMENT-TESTS")
        _log_i "Starting the post-deployment task with plan: $ENTANDO_OPT_TEST_POSTDEP_PLAN"
        export ENTANDO_OPT_LOG_LEVEL=DEBUG
        _pkg_get "xmlstarlet"
        
        local projectName projectVersion prNumber
        
        if [ "$PPL_BRANCHING_TYPE" != "release" ]; then
          # If snapshot version sets the proper version semver according with the version tag
          ppl--publication._determine_snapshot_version_number projectVersion
          _pom_set_project_version "$projectVersion" "./pom.xml"
        fi
        
        _ppl_extract_version_part prNumber "$projectVersion" "pr-num"
        
        ppl--mvn.post-deloyment.configure projectName projectVersion ENTANDO_TEST_NAMESPACE || _SOE
        
        local TMP
        IFS=, read -ra TMP <<< "$ENTANDO_OPT_TEST_POSTDEP_PLAN"
        for step in "${TMP[@]}"; do
          _log_d "Running post-deployment-tests step: $step"
          
          case "$step" in
            "RUN-TESTS")
              ppl--mvn.post-deloyment.run-test "$projectName" "$projectVersion" || _SOE
              ;;
            "PUBLISH-PROJECT-IMAGE")
              ppl--mvn.post-deloyment.publish-image "$projectName" "$projectVersion" "$prNumber" || _SOE
              ;;
            "DEPLOY-PROJECT-HELM")
              ppl--mvn.post-deloyment.deploy-project-helm "$projectName" "$projectVersion" | _group_stream "$step"
              _SOE --pipe
              ;;
            "DEPLOY-OPERATOR-CLUSTER-REQUIREMENTS")
              ppl--mvn.post-deloyment.operator install-cluster-requirements | _group_stream "$step"
              _SOE --pipe
              ;;
            "DEPLOY-OPERATOR-NAMESPACE-REQUIREMENTS")
              ppl--mvn.post-deloyment.operator install-namespace-requirements | _group_stream "$step"
              _SOE --pipe
              ;;
            "DEPLOY-OPERATOR")
              ppl--mvn.post-deloyment.operator install | _group_stream "$step"
              _SOE --pipe
              ;;
            "SUSPEND-TEST-NAMESPACE")
              kube.oc.namespace.suspend "$ENTANDO_TEST_NAMESPACE" 30
              ;;
            "RESET-TEST-NAMESPACE")
              kube.oc.namespace.reset "$ENTANDO_TEST_NAMESPACE" 30
              ;;
            "DELETE-TEST-NAMESPACE")
              kube.oc.namespace.delete "$ENTANDO_TEST_NAMESPACE" 30
              ;;
            *)
              _FATAL "Uknown plan step \"$step\""
              ;;
            esac
            true
        done
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
            _ppl_extract_version_part projectVersion "$PPL_REF_NAME" "effective-number"
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
  local _tmp_projectName _tmp_projectVersion
  
  if [ -n "$ENTANDO_PROJECT_NAME_OVERRIDE" ]; then
    _tmp_projectName="$ENTANDO_PROJECT_NAME_OVERRIDE"
  else
    _ppl_get_current_project_artifact_id _tmp_projectName
  fi
  if [ -n "$ENTANDO_PROJECT_VERSION_OVERRIDE" ]; then
    _tmp_projectVersion="$ENTANDO_PROJECT_VERSION_OVERRIDE"
  else
    _ppl_get_current_project_version _tmp_projectVersion
  fi
  _NONNULL _tmp_projectName _tmp_projectVersion
  
  _set_var "$1" "$_tmp_projectName"
  _set_var "$2" "$_tmp_projectVersion"
  
  local _tmp_ns="$ENTANDO_OPT_TEST_NAMESPACE"
  [[ "$_tmp_ns" == "[auto]" || -z "$_tmp_ns" ]] && _tmp_ns="test-${_tmp_projectName}";
  [[ "${_tmp_ns:0:5}" != "test-" ]] && _FATAL "The test namespace name must start with the prefix \"test-\""
  _set_var "$3" "$_tmp_ns"
}

ppl--mvn.post-deloyment.publish-image() {
  local projectName="$1" projectVersion="$2" prNumber="$3"

  _log_d "Buiding and deploying the image for project \"${projectName}\" of version \"${projectVersion}\""
  
  _ppl_is_feature_enabled "MVN-QUARKUS-NATIVE" && {
    __mvn_exec -B package -Pjvm
  }

  ppl--docker.publish.LOGIN
  ppl--docker.publish.BUILD_AND_PUSH_ALL "$ENTANDO_OPT_DOCKER_BUILDS" "$projectName" "$projectVersion"
  
  if [ -n "$prNumber" ]; then
    _ppl-pr-submit-comment "$prNumber" "Requested publication of version \`${projectVersion}\`"
  fi
}

ppl--mvn.post-deloyment.deploy-project-helm() {
  local projectName="$1" projectVersion="$2"
  
  _log_d "Applying the project helm charts"

  local ORIGDIR="$PWD"
  
  _ppl_provision_helm_preview_environment \
    "$projectName" "$projectVersion" \
    "$ENTANDO_TEST_NAMESPACE" "$ENTANDO_OPT_TEST_HOSTNAME_SUFFIX"

  local RV="$?"
  
  [[ "$RV" == 99 ]] && {
    _log_i "No helm setup method found, skipped"
    __cd "$ORIGDIR"
    return 0
  }
  [[ "$RV" != 0 ]] && exit "$RV"
  
  __cd "$ORIGDIR"
}

ppl--mvn.post-deloyment.operator() {
  case "$1" in
    install-cluster-requirements)
      ppl--mvn.post-deloyment._operator_installation apply "cluster-resources.yaml" "operator cluster dependencies";;
    uninstall-cluster-requirements)
      ppl--mvn.post-deloyment._operator_installation delete "cluster-resources.yaml" "operator cluster dependencies";;
    install-namespace-requirements)
      ppl--mvn.post-deloyment._operator_installation --skip-kind "Deployment" apply "namespace-resources.yaml" \
        "operator namespace dependencies";;
    uninstall-namespace-requirements)
      ppl--mvn.post-deloyment._operator_installation --skip-kind "Deployment" delete "namespace-resources.yaml" \
        "operator namespace dependencies";;
    install)
      ppl--mvn.post-deloyment._operator_installation apply "namespace-resources.yaml" "operator";;
    uninstall)
      ppl--mvn.post-deloyment._operator_installation delete "namespace-resources.yaml" "operator";;
    *)
      _FATAL "Invalid action \"$1\"";;
  esac
}


ppl--mvn.post-deloyment._operator_installation() {
  local skip_kind=''; [ "$1" == "--skip-kind" ] && { skip_kind="$2"; shift 2; }
  case "$1" in
    apply|create) _log_d "Deloying the $3 \"$ENTANDO_OPT_TEST_OPERATOR_BUNDLE_VERSION\" to the namespace";;
    delete) _log_d "Undeploying the $3 \"$ENTANDO_OPT_TEST_OPERATOR_BUNDLE_VERSION\" to the namespace";;
  esac
  
  _NONNULL ENTANDO_OPT_TEST_OPERATOR_BUNDLE_URL ENTANDO_OPT_TEST_OPERATOR_BUNDLE_VERSION
  
  _tpl_set_var url "$ENTANDO_OPT_TEST_OPERATOR_BUNDLE_URL" version "$ENTANDO_OPT_TEST_OPERATOR_BUNDLE_VERSION"
  url="$(path-concat "$url" "$2")"
  
  kube.manifest.filter-document-by-kind "$skip_kind" < <(curl -sL "$url") \
    | _summarize_stream --ppl-pg 5000 MANIFEST
  
  if [ -z "$skip_kind" ]; then
    curl -sL "$url" | kube.oc -n "$ENTANDO_TEST_NAMESPACE" "$1" -f -
  else
    {
      kube.manifest.filter-document-by-kind "$skip_kind" < <(curl -sL "$url")
    } | kube.oc -n "$ENTANDO_TEST_NAMESPACE" "$1" -f -
  fi
}

ppl--mvn.post-deloyment.run-test() {
  local projectName="$1" projectVersion="$2"

  _log_d "Executing the post-deployment tests"
  # shellcheck disable=SC2030 disable=SC2031
  (
    export ENTANDO_OPT_PREVIEW_TESTS=true
    export ENTANDO_TEST_NAMESPACE
    export ENTANDO_OPT_TEST_HOSTNAME_SUFFIX
    export ENTANDO_DEFAULT_ROUTING_SUFFIX="$ENTANDO_OPT_TEST_HOSTNAME_SUFFIX"
    export ENTANDO_TEST_NAMESPACE_OVERRIDE="$ENTANDO_TEST_NAMESPACE"
    export ENTANDO_TEST_IMAGE_VERSION="$projectVersion"
    
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
