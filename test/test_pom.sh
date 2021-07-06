#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/base.sh"
  . "$PROJECT_DIR/lib/pom.sh"
  . "$PROJECT_DIR/lib/pkg.sh"
}

#TEST:lib
test_pom() {
  print_current_function_name "RUNNING TEST> " ".."

  _pkg_get "xmlstarlet" -c xmlstarlet


  # shellcheck disable=SC2034
  local RES

  local F="$TEST__WORK_DIR/resources/test-pom-do-not-scan.xml"
  _pom_get_project_artifact_id RES "$F"
  ASSERT RES = "entando-plugin-jpredis"
  _pom_get_project_version RES "$F"
  ASSERT RES = "6.3.0-SNAPSHOT"
  _pom_get_depman_artifact_version RES "$F" "entando-core-bom"
  ASSERT RES = "6.2.255"

  local F2="$TEST__WORK_DIR/resources/test-pom-of-bom-do-not-scan.xml"
  _pom_get_project_property RES "$F2" "entando-engine.version"
  ASSERT RES = "6.4.0"

  _pom_set_project_property "6.5.0" "$F2" "entando-engine.version"
  _pom_get_project_property RES "$F2" "entando-engine.version"
  ASSERT RES = "6.5.0"

  FC="$TEST__WORK_DIR/test-pom-do-not-scan.xml"
  cp "$F" "$FC"
  _pom_set_project_version "6.3.1" "$FC" || FAILED
  _pom_get_project_version RES "$FC"
  ASSERT RES = "6.3.1"

  true
}

true
