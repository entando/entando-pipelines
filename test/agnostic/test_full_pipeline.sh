#!/bin/bash

# shellcheck disable=SC1091,SC1090
. "$PROJECT_DIR/test/_test-base.sh"

# shellcheck disable=SC2034
#TEST:macro
test_flow_pr_check() {
  print_current_function_name "RUNNING TEST> "  ".."
  # shellcheck disable=SC2034
  
  #~
  #~ CHECKOUT
  #~
  TEST.mock.initial_checkout "local-clone"

  #~
  #~ LABELS MANIPULATION
  #~
  (
    local TMP
    ppl--pr-labels --id "TEST" remove "test" || _SOE

    ASSERT -v RES $? -eq 0
    TEST.GET_TLOG_COMMAND TMP -1
    ASSERT TMP =~ "\[HTS\] \"DELETE\" to \"https:.*\""
  ) || FAILED

  #~
  #~ CHECK PR BOM STATE
  #~
  (
    ppl--check-pr-bom-state --lcd "local-clone"
    ASSERT -v "BOM_CHECK_RESULT" "$?" = 0
    __cd "$ENTANDO_OPT_REPO_BOM_URL"
    echo "something-new" > something-new
    __git_ACTP "something-new" "v9.9.9"
    __cd -
    TEST__EXPECTED_ERROR="The BOM version requested"
    ppl--check-pr-bom-state --lcd "local-clone"
    ASSERT -v "BOM_CHECK_RESULT" "$?" = 77
    __cd -
    __git tag -d "v9.9.9"
  ) || FAILED

  #~
  #~ CHECK PR FORMAT RULES
  #~
  (
    ENTANDO_OPT_MAINLINE=""
    ppl--pr-preflight-checks --lcd "local-clone"
  ) || FAILED
  
  (
    ENTANDO_OPT_MAINLINE="10.9.8"
    ppl--pr-preflight-checks --lcd "local-clone"
  ) || FAILED
  
  (
    TEST__EXPECTED_ERROR="In non-release branches the project version"
    ENTANDO_OPT_MAINLINE="99.99"
    ppl--pr-preflight-checks --lcd "local-clone"
  ) && FAILED

  (
    TEST__APPLY_OVERRIDES() { PPL_PR_TITLE="ENG-999-Hey There!"; }
    TEST__EXPECTED_ERROR="The Pull Request title"
    ppl--pr-preflight-checks --lcd "local-clone"
  ) && FAILED "I was expecting an error, but I've got success"

  (
    TEST__APPLY_OVERRIDES() { PPL_PR_TITLE="ENG-999 Hey There!"; }
    ppl--pr-preflight-checks --lcd "local-clone"
  ) || FAILED

  (
    TEST__APPLY_OVERRIDES() { PPL_PR_TITLE="ENG-100/ENG-999 Hey There!"; }
    ppl--pr-preflight-checks --lcd "local-clone"
  ) || FAILED

  (
    TEST__APPLY_OVERRIDES() { PPL_PR_TITLE="Revert \"ENG-100/ENG-999 Hey There!\""; }
    ppl--pr-preflight-checks --lcd "local-clone"
  ) || FAILED

  #~
  #~ GENERATE SNAPSHOT VERSION
  #~
  (
    TEST__APPLY_OVERRIDES() {
      PPL_PR_SHA="5a98877358d1322130cbde49628bdb796a100e89"
    }

    ppl--publication tag-git-version --lcd "local-clone" || _SOE
    
    cd local-clone
    ASSERT -v SNAPSHOT-TAG "$(git tag | grep "ENG-")" = "v10.9.8.0-ENG-2471-PR-154+BB-develop"
  ) || _SOE
  
  #~
  #~ SIMULATES A PR OPEN+MERGE CHECKOUT
  #~
  SIMULATE_PR_MERGE
  rm -rf "local-clone"

  #~
  #~ POST-MERGE CHECKOUT
  #~
  (
    ppl--checkout-branch --id "AFTER-MERGE-CHECKOUT" --lcd "local-clone"

    _ppl-load-context "$PPL_CONTEXT"
    __cd "local-clone"
    ASSERT -v LOCAL_BRANCH "$(git branch --show-current)" = "develop"
    rm -rf "local-clone"  
  ) || FAILED
  
  #~
  #~ GENERATE SNAPSHOT VERSION ON MERGE COMMIT
  #   (
  #     TEST__APPLY_OVERRIDES() {
  #       PPL_PR_SHA="5a98877358d1322130cbde49628bdb796a100e89"
  #     }
  #     ppl--publication tag-git-version --lcd "local-clone" || _SOE
  #   ) || _SOE
  
  # ~
  # ~ SIMULATES THE TAG EVENT
  # ~
  ASSUME_CONTEXT_OF_EVENT_ADD_RELEASE_TAG
  
  #~
  #~ BOM UPDATE
  #~
  (
    TEST__APPLY_OVERRIDES() {
      PPL_REF="refs/tags/v6.4.0-ENG-2704-PR-126+KB-epic+++ENG-999"
    }
    
    (
      __cd "$ENTANDO_OPT_REPO_BOM_URL"
      __git checkout _tmp_
    ) || _SOE
    
    ppl--bom update-bom --id "TEST-BOM-UPDATE" --lcd "local-clone" || _SOE

    _ppl-load-context "$PPL_CONTEXT"
    __cd "$ENTANDO_OPT_REPO_BOM_URL"
    __git checkout "$ENTANDO_OPT_REPO_BOM_MAIN_BRANCH"
    _pom_get_project_property RES "pom.xml" "entando-test-repo-base.version"
    ASSERT RES = "10.9.8.0-SNAPSHOT"
    
    RES="$(__git tag | grep ENG | tail -n 1)"
    ASSERT RES = "v6.4.0-ENG-2704"

    __git checkout "_tmp_"
  ) || FAILED
}

SIMULATE_PR_MERGE() {
  (
    _ppl-load-context "$PPL_CONTEXT"
    local prBranch="$PPL_HEAD_REF"
    PPL_CONTEXT="$(cat "$PROJECT_DIR/test/resources/github-context-sample-03.json")"
    _ppl-load-context "$PPL_CONTEXT"

    __cd "local-clone"
    __git checkout "develop"
    __git merge --no-edit "$prBranch"
    __git push -f
  )
  PPL_CONTEXT="$(cat "$PROJECT_DIR/test/resources/github-context-sample-03.json")"
}

ASSUME_CONTEXT_OF_EVENT_ADD_RELEASE_TAG() {
  PPL_CONTEXT="$(cat "$PROJECT_DIR/test/resources/github-context-sample-05.json")"
}

#TEST:lib
test_generate_build_cache_key() {
  print_current_function_name "RUNNING TEST> "  ".."
  
  (
    TEST.mock.initial_checkout "local-clone" > /dev/null
    export ENTANDO_OPT_LOG_LEVEL=TRACE
    # shellcheck disable=SC2034
    RES="$(ppl--generic GENERATE-BUILD-CACHE-KEY "BUILD_CACHE_KEY" --lcd "local-clone")"
    ASSERT RES =~ "^BUILD_CACHE_KEY=[a-z0-9]{64}"
  ) || _SOE
}
