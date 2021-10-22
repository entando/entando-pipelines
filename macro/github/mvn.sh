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
      "SONAR-SCAN")
        _log_i "Starting the sonar analysis"
        _NONNULL SONAR_TOKEN
        
        __mvn_exec clean -B test \
          org.jacoco:jacoco-maven-plugin:prepare-agent \
          org.jacoco:jacoco-maven-plugin:report \
          org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
          -Ppre-deployment-verification -Ppost-deployment-verification \
        ;

        echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
        git log --graph --pretty=oneline --abbrev-commit --all | head -n 15
        echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
        ls
        echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
        ls target/**
          
        local RV="$?"          
        [ "$RV" -ne 0 ] && {
          #~ ON ERROR
          _ppl-set-persistent-var "ERROR_${PPL_CURRENT_MACRO}" true
        }
        return "$RV"
        ;;
      "BUILD-AND-TEST")
        _log_i "Building and testing with group \"$arg2\""
        __mvn_exec -B test -Dgroups="$arg2"

        #mvn clean package -DskipPostDeploymentTests=false -DskipPreDeploymentTests=false
        #__mvn_exec clean test -Ppre-deployment-verification
        ;;
      "FULL-BUILD")
        _log_i "Building and testing"

        __mvn_exec clean package
        
        ;;
      "BUILD")
        _log_i "Building with group \"$arg2\""
        __mvn_exec package -Dmaven.test.skip=true -Dgroups="$arg2"
        #__mvn_exec clean package -DskipPostDeploymentTests=true -DskipPreDeploymentTests=true -Dmaven.test.skip=true
        ;;
      "OWASP-SCAN")
        _log_i "Starting the owasp analysis"
        __mvn_exec verify -Powasp-dependency-check
        ;;
      "PUBLISH")
        case "$PPL_REF_NAME" in
          x*)
            _log_i "Publishing to the internal releases repo"
            _NONNULL ENTANDO_OPT_MAVEN_REPO_PROD            
            __mvn_deploy "internal-nexus" "$ENTANDO_OPT_MAVEN_REPO_PROD"
            ;;
          v*)
            _log_i "Publishing to the internal snapshots repo"
            
            _NONNULL ENTANDO_OPT_MAVEN_REPO_DEVL
            _pkg_get "xmlstarlet" -c "xmlstarlet"
            
            #~ UPDATES the version on the POM and REBUILDS the module
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
