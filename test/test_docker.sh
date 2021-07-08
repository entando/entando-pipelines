#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/base.sh"
  . "$PROJECT_DIR/macro/agnostic/docker.sh"
}

#TEST:macro
test_publish.BUILD_TAG() {
  print_current_function_name "RUNNING TEST> " ".."

  ppl--docker.publish.BUILD_TAG RES "myorg" "myartifact" "6.4.0"
  ASSERT RES = "myorg/myartifact:6.4.0"
  ppl--docker.publish.BUILD_TAG RES "myorg" "myartifact" "6.3.0-SNAPSHOT" ""
  ASSERT RES = "myorg/myartifact:6.3.0-SNAPSHOT"
  ppl--docker.publish.BUILD_TAG RES "myorg" "myartifact" "6.4.0" ".wildfly"
  ASSERT RES = "myorg/myartifact-wildfly:6.4.0"
  ppl--docker.publish.BUILD_TAG RES "myorg" "myartifact" "6.3.0-SNAPSHOT" ".wildfly"
  ASSERT RES = "myorg/myartifact-wildfly:6.3.0-SNAPSHOT"

  true
}

true
