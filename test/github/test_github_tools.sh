#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/base.sh"
  . "$PROJECT_DIR/lib/pkg.sh"
  . "$PROJECT_DIR/lib/github/github_tools.sh"
}

#TEST:lib
test_github_tools() {
  print_current_function_name "RUNNING TEST> "  ".."
  (
    local E
    E="$(cat "$PROJECT_DIR/test/resources/github-context-sample-01.json")"

    # shellcheck disable=2034
    EE_PARSED_CONTEXT=""
    _ppl-load-context --disable-overrides "$E"
    
    echo "$EE_PARSED_CONTEXT" > /tmp/t1
    echo "$E" > /tmp/t2

    ASSERT --censor EE_PARSED_CONTEXT = "$E"
    ASSERT --censor EE_TOKEN = "999999999"
    ASSERT EE_RUN_ID = "974609133"
    ASSERT EE_BASE_REF = "develop"
    ASSERT EE_HEAD_REF = "github-actions-pipeline-exp2"
    ASSERT EE_REF = "refs/pull/154/merge"
    ASSERT EE_REF_NAME = "merge"
    ASSERT EE_COMMIT_ID = "21aa52f7f1adcadea778314255b528ec8c0c7a41"
    ASSERT EE_REPO_NAME = "entando-engine"
    ASSERT EE_CLONE_URL = "https://github.com/entando/entando-engine.git"
    ASSERT EE_STATUSES_URL = "https://api.github.com/repos/entando/entando-engine/statuses/{sha}"
    ASSERT EE_ISSUES_URL = "https://api.github.com/repos/entando/entando-engine/issues{/number}"
    ASSERT EE_PR_NUM = "154"
    ASSERT EE_PR_TITLE = "ENG-2471 GitHub actions pipeline exp2"
    ASSERT EE_PR_LABELS = "do-not-merge/work-in-progress,size/XXL"

    _ppl-pr-has-label "do-not-merge/work-in-progress" || FAILED
    _ppl-pr-has-label "size/XXL" || FAILED
    _ppl-pr-has-label "do-not-merge" && FAILED
    
    true
  )
}

true
