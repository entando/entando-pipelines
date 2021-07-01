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
  . "$PROJECT_DIR/macro/agnostic/generate-version.sh"
  . "$PROJECT_DIR/test/_test-base.sh"
}

# shellcheck disable=SC2034
test_github_full_pipeline() {
  print_current_function_name "RUNNING TEST> "  ".."
  
  # shellcheck disable=SC2034
  
  #~
  #~ CHECKOUT
  #~
  (
    ppl--checkout-pr-branch "local-checkout"
    
    __cd "local-checkout"
    __exist -f "pom.xml"
    _pom_get_project_artifact_id RES "pom.xml" "artifactId"
    ASSERT RES == "entando-portal-ui"
  )

  #~
  #~ SIMULATES A PR OPEN+MERGE CHECKOUT
  #~
  (
    _ppl-load-context "$PPL_CONTEXT"
    
    __cd "local-checkout"
    __git checkout develop
    __git merge --no-edit "$EE_HEAD_REF"
    __git push -f
  )

  #~
  #~ GENERATE PREVIEW VERSION
  #~
  (
    ppl--generate-version "PREVIEW-VERSION-GENERATION" preview-version "local-checkout"

    _ppl-load-context "$PPL_CONTEXT"
    __cd "$EE_CLONE_URL"
    __git checkout "release/6.3.0"
    _pom_get_project_version RES "pom.xml"
    ASSERT RES = "6.3.0-ENG-2471-PR154"
    __git checkout "_tmp_"
  )

  export XX=1
  #~
  #~ GENERATE NEW VERSION
  #~
  (
    ppl--generate-version "NEW-VERSION-GENERATION" new-version "local-checkout"
    
    _ppl-load-context "$PPL_CONTEXT"
    __cd "$EE_CLONE_URL"
    __git co "release/6.3.0"
    _pom_get_project_version RES "pom.xml"
    ASSERT RES = "6.3.11"
   
    __cd "$EE_CLONE_URL" && DBGSHELL "AFTER MERGE"
    __git co "_tmp_"
  ) 
exit
  
  #~
  #~ LABELS MANIPULATION
  #~
  (
    local TMP
    ppl--pr-labels "TEST" remove "test"
    
    ASSERT -v RES $? -eq 0
    LATEST_TEST_TLOG_COMMAND TMP
    ASSERT TMP =~ "\[HTS\] \"DELETE\" to \"https:.*\""
  ) || FAILED
  
  #~
  #~ GATE
  #~
  (
    TMP="$(ppl--gate-check TEST | tail -1)"
    ASSERT TMP = "::set-output name=ENABLED::true"
  ) || FAILED

  (
    TEST_APPLY_OVERRIDES() {
      EE_PR_LABELS+="skip-test,"
    }

    TMP="$(ppl--gate-check TEST |  tail -1)"
    ASSERT TMP = "::set-output name=ENABLED::false"
  ) || FAILED
  
  #~
  #~ CHECK PR BOM STATE
  #~
  (
    ppl--check-pr-bom-state "local-checkout" 
    ASSERT -v BOM_CHECK_RESULT "$?" = 0
    __cd "$ENTANDO_OPT_REPO_BOM_URL"
    echo "something-new" > something-new
    __git_ACTP "something-new" "v9.9.9"
    __cd -
    ppl--check-pr-bom-state "local-checkout"
    ASSERT -v BOM_CHECK_RESULT "$?" = 77
  ) || FAILED
  
  #~
  #~ CHECK PR FORMAT RULES
  #~
  (
    ppl--check-pr-format "local-checkout"
  ) || FAILED

  (
    TEST_APPLY_OVERRIDES() { EE_PR_TITLE="ENG-999-Hey There!"; }
    ppl--check-pr-format "local-checkout"
  ) && FAILED "I was expecting an error, but I've got success"

  (
    TEST_APPLY_OVERRIDES() { EE_PR_TITLE="ENG-999 Hey There!"; }
    ppl--check-pr-format "local-checkout"
  ) || FAILED

  (
    TEST_APPLY_OVERRIDES() { EE_PR_TITLE="ENG-100/ENG-999 Hey There!"; }
    ppl--check-pr-format "local-checkout"
  ) || FAILED

}
