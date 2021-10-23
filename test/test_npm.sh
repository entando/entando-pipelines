#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/base.sh"
  . "$PROJECT_DIR/lib/npm.sh"
  . "$PROJECT_DIR/lib/pkg.sh"
}

#TEST:lib
test_npm() {
  print_current_function_name "RUNNING TEST> " ".."

  _pkg_get "jq" -c jq

  _git_full_clone --as-work-area "file://$TEST__WORK_DIR/repo-mocks/app-builder"
  
  _ppl_get_current_project_artifact_id artifactId
  _ppl_get_current_project_version projectVersion
  ASSERT artifactId = "app-builder"
  ASSERT projectVersion = "6.4.0"
  _ppl_set_current_project_version "6.4.0-ENG-999-PR-111"
  _ppl_get_current_project_version projectVersion
  ASSERT projectVersion = "6.4.0-ENG-999-PR-111"

  true
}

true
