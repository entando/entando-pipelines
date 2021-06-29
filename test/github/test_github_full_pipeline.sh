#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/lib/base.sh"
  . "$PROJECT_DIR/macro/github/checkout-pr-branch.sh"
  . "$PROJECT_DIR/macro/github/check-pr-bom-state.sh"
  . "$PROJECT_DIR/macro/github/check-pr-format.sh"
  . "$PROJECT_DIR/macro/github/pr-labels.sh"
  . "$PROJECT_DIR/macro/github/gate-check.sh"
  . "$PROJECT_DIR/macro/github/mvn.sh"
  . "$PROJECT_DIR/macro/agnostic/make-version.sh"
  . "$PROJECT_DIR/test/_test-base.sh"
}

test_github_full_pipeline() {
  print_current_function_name "RUNNING TEST> "  ".."
  
  # shellcheck disable=SC2034
  local TLC
  
  #~
  #~ INIT
  #~
  
  _create-test-git-repo "test-repo" "$EE_HEAD_REF" "1.2.3"
  
  #~
  #~ LABELS MANIPULATION
  #~
  ppl--pr-labels "TEST" remove "test"
  ASSERT -v RES $? -eq 0
  LATEST_TEST_TLOG_COMMAND TLC
  ASSERT TLC =~ "\[HTS\] \"DELETE\" to \"https:.*\""
  
  #~
  #~ GATE
  #~
  
  ppl--gate-check TEST
  
  #~
  #~ CHECKOUT
  #~
  
  ppl--checkout-pr-branch "clone-of-test-repo"
  __exist -f "clone-of-test-repo/pom.xml"

  #~
  #~ CHECK PR BOM STATE
  #~

  ppl--check-pr-bom-state "clone-of-test-repo" 
  
  #~
  #~ CHECK PR FORMAT RULES
  #~

  ppl--check-pr-format "clone-of-test-repo" 

  #~
  #~ MAKE PREVIEW VERSION
  #~

  ppl--make-version MAKE-PREVIEW "preview"
}
