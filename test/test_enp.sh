#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/enp.sh"
}

#TEST:lib
test_npm() {
  print_current_function_name "RUNNING TEST> " ".."

  echo "ENTANDO_PRJ_VERSION=7.0.0-SNAPSHOT" > "entando-project"
  _ppl_get_current_project_version projectVersion
  exit
  ASSERT projectVersion = "7.0.0-SNAPSHOT"
  _ppl_set_current_project_version "7.0.0-ENG-999-PR-111"
  _ppl_get_current_project_version projectVersion
  ASSERT projectVersion = "7.0.0-ENG-999-PR-111"

  true
}

true
