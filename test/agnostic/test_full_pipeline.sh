#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  # shellcheck disable=SC1090
  if [ -n "$GITHUB_ACTIONS" ]; then
    # shellcheck disable=SC1090
    while read -r fn; do
      source "$fn"
    done < <(find "$PROJECT_DIR/macro" -mindepth 2 -type f -iname "*.sh")
    [ "$1" = "--activate" ] && return 0
  else
    echo "Unsupported Pipeline implementation" 1>&2
    [ "$1" = "--activate" ] && return 77
    exit 77
  fi
}

# shellcheck disable=SC2034
#TEST:macro
test_flow_pr_check() {
  print_current_function_name "RUNNING TEST> "  ".."
  # shellcheck disable=SC2034
  
  #~
  #~ CHECKOUT
  #~
  (
    ppl--checkout-branch pr --id "PR-CHECKOUT" --lcd "local-checkout" || _SOE

    __cd "local-checkout"
    __exist -f "pom.xml"
    _pom_get_project_artifact_id RES "pom.xml" "artifactId"
    ASSERT RES == "entando-portal-ui"
  ) || FAILED

  #~
  #~ LABELS MANIPULATION
  #~
  (
    local TMP
    ppl--pr-labels --id "TEST" remove "test" || _SOE

    ASSERT -v RES $? -eq 0
    LATEST__TEST__TLOG_COMMAND TMP
    ASSERT TMP =~ "\[HTS\] \"DELETE\" to \"https:.*\""
  ) || FAILED

  #~
  #~ GATE
  #~
  (
    TMP="$(ppl--gate-check --id TEST | grep "set-output")"
    ASSERT TMP = "::set-output name=ENABLED::true"
  ) || FAILED

  (
    TEST__APPLY_OVERRIDES() {
      EE_PR_LABELS+="skip-test,"
    }

    TMP="$(ppl--gate-check --id TEST | grep "set-output")"
    ASSERT TMP = "::set-output name=ENABLED::false"
  ) || FAILED

  #~
  #~ CHECK PR BOM STATE
  #~
  (
    ppl--check-pr-bom-state --lcd "local-checkout"
    ASSERT -v "BOM_CHECK_RESULfile:///home/wrt/work/prj/entando/main/tools/entando-pipelines/test/github/test_github_full_pipeline.shT" "$?" = 0
    __cd "$ENTANDO_OPT_REPO_BOM_URL"
    echo "something-new" > something-new
    __git_ACTP "something-new" "v9.9.9"
    __cd -
    ppl--check-pr-bom-state --lcd "local-checkout"
    ASSERT -v "BOM_CHECK_RESULT" "$?" = 77
    __cd -
    __git tag -d "v9.9.9"
  ) || FAILED

  #~
  #~ CHECK PR FORMAT RULES
  #~
  (
    ENTANDO_OPT_MAINLINE=""
    ppl--check-pr-format --lcd "local-checkout"
  ) || FAILED
  
  (
    ENTANDO_OPT_MAINLINE="6.3"
    ppl--check-pr-format --lcd "local-checkout"
  ) || FAILED
  
  (
    ENTANDO_OPT_MAINLINE="99.99"
    ppl--check-pr-format --lcd "local-checkout"
  ) && FAILED

  (
    TEST__APPLY_OVERRIDES() { EE_PR_TITLE="ENG-999-Hey There!"; }
    ppl--check-pr-format --lcd "local-checkout"
  ) && FAILED "I was expecting an error, but I've got success"

  (
    TEST__APPLY_OVERRIDES() { EE_PR_TITLE="ENG-999 Hey There!"; }
    ppl--check-pr-format --lcd "local-checkout"
  ) || FAILED

  (
    TEST__APPLY_OVERRIDES() { EE_PR_TITLE="ENG-100/ENG-999 Hey There!"; }
    ppl--check-pr-format --lcd "local-checkout"
  ) || FAILED

  #~
  #~ GENERATE PREVIEW VERSION
  #~
  (
    export PS4='$LINENO: '
    set -x
    ppl--release prepare-preview-release --id "PREVIEW-RELEASE" --lcd "local-checkout"
    set +x

    _ppl-load-context "$PPL_CONTEXT"
    __cd "$EE_CLONE_URL"
    __git checkout "$EE_HEAD_REF"
    _pom_get_project_version RES "pom.xml"
    ASSERT RES = "6.3.0-SNAPSHOT"
    _git_determine_latest_version --include-previews RES
    ASSERT RES = "p6.3.0-ENG-2471-PR-154-SNAPSHOT"
    __git checkout "_tmp_"
  ) || FAILED

  #~
  #~ SIMULATES A PR OPEN+MERGE CHECKOUT
  #~
  SIMULATE_PR_MERGE
  rm -rf "local-checkout"

  #~
  #~ POST-MERGE CHECKOUT
  #~
  (
    ppl--checkout-branch base --id "AFTER-MERGE-CHECKOUT" --lcd "local-checkout"

    _ppl-load-context "$PPL_CONTEXT"
    __cd "local-checkout"
    ASSERT -v LOCAL_BRANCH "$(git branch --show-current)" = "develop"
    rm -rf "local-checkout"  
  ) || FAILED
  
  #~
  #~ GENERATE TAG-RELEASE
  #~
  (
    ppl--release prepare-tag-release --id "TAG-RELEASE" --lcd "local-checkout" || _SOE

    _ppl-load-context "$PPL_CONTEXT"
    __cd "$EE_CLONE_URL"
    __git checkout "release/6.3.0"
    _pom_get_project_version RES "pom.xml"
    ASSERT RES = "6.3.11"

    __git checkout "_tmp_"
  ) || FAILED
  
  # ~
  # ~ SIMULATES THE TAG EVENT
  # ~
  ASSUME_CONTEXT_OF_EVENT_ADD_RELEASE_TAG
  
  #~
  #~ BOM UPDATE
  #~
  (
    ppl--bom update-bom --id "TEST-BOM-UPDATE" --lcd "local-checkout"

    _ppl-load-context "$PPL_CONTEXT"
    __cd "$ENTANDO_OPT_REPO_BOM_URL"
    __git checkout "$ENTANDO_OPT_REPO_BOM_MAIN_BRANCH"
    _pom_get_project_property RES "pom.xml" "entando-portal-ui.version"
    ASSERT RES = "6.3.11"

    __git checkout "_tmp_"
  ) || FAILED
}

SIMULATE_PR_MERGE() {
  (
    _ppl-load-context "$PPL_CONTEXT"
    local prBranch="$EE_HEAD_REF"
    PPL_CONTEXT="$(cat "$PROJECT_DIR/test/resources/github-context-sample-03.json")"
    _ppl-load-context "$PPL_CONTEXT"

    __cd "local-checkout"
    __git checkout "develop"
    __git merge --no-edit "$prBranch"
    __git push -f
  )
  PPL_CONTEXT="$(cat "$PROJECT_DIR/test/resources/github-context-sample-03.json")"
}

ASSUME_CONTEXT_OF_EVENT_ADD_RELEASE_TAG() {
  PPL_CONTEXT="$(cat "$PROJECT_DIR/test/resources/github-context-sample-05.json")"
}
