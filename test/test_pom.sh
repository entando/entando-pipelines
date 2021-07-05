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

  local RES

  local F="$PROJECT_DIR/test/resources/test-pom-do-not-scan.xml"  
  _pom_get_project_artifact_id RES "$F"
  [ "$RES" = "entando-plugin-jpredis" ] || FAILED
  _pom_get_project_version RES "$F"
  [ "$RES" = "6.3.0-SNAPSHOT" ] || FAILED
  _pom_get_depman_artifact_version RES "$F" "entando-core-bom"
  [ "$RES" = "6.2.255" ] || FAILED

  local F2="$PROJECT_DIR/test/resources/test-pom-of-bom-do-not-scan.xml"
  _pom_get_project_property RES "$F2" "entando-engine.version"
  [ "$RES" = "6.4.0" ] || FAILED
  
  FC="$TEST_WORK_DIR/test-pom-do-not-scan.xml"  
  cp "$F" "$FC"
  RES=""
  _pom_set_project_version "6.3.1" "$FC" || FAILED
  _pom_get_project_version RES "$FC"
  [ "$RES" = "6.3.1" ] || FAILED "$RES"
  
  true
}

true
