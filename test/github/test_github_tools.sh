#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/base.sh"
  . "$PROJECT_DIR/lib/pkg.sh"
  . "$PROJECT_DIR/lib/github/github_tools.sh"
}

#TEST:libx
test_github_tools() {
  print_current_function_name "RUNNING TEST> "  ".."
  (
    TEST.mock.context "github-context-sample-01.json"
    
    ASSERT --censor PPL_PARSED_CONTEXT = "$PPL_CONTEXT"
    ASSERT --censor PPL_TOKEN = "999999999"
    ASSERT PPL_RUN_ID = "974609133"
    ASSERT PPL_BASE_REF = "develop"
    ASSERT PPL_HEAD_REF = "github-actions-pipeline-exp2"
    ASSERT PPL_REF = "refs/pull/154/merge"
    ASSERT PPL_REF_NAME = "merge"
    ASSERT PPL_COMMIT_ID = "21aa52f7f1adcadea778314255b528ec8c0c7a41"
    ASSERT PPL_REPO_NAME = "entando-engine"
    ASSERT PPL_CLONE_URL = "https://github.com/entando/entando-engine.git"
    ASSERT PPL_STATUSES_URL = "https://api.github.com/repos/entando/entando-engine/statuses/{sha}"
    ASSERT PPL_ISSUES_URL = "https://api.github.com/repos/entando/entando-engine/issues{/number}"
    ASSERT PPL_PR_NUM = "154"
    ASSERT PPL_PR_TITLE = "ENG-2471 GitHub actions pipeline exp2"
    ASSERT PPL_PR_LABELS = "do-not-merge/work-in-progress,size/XXL"

    _ppl-pr-has-label "do-not-merge/work-in-progress" || FAILED
    _ppl-pr-has-label "size/XXL" || FAILED
    _ppl-pr-has-label "do-not-merge" && FAILED
    
    true
  )
}

true
