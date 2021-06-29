#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/lib/base.sh"
  . "$PROJECT_DIR/lib/github/github_tools.sh"
}

test_github_tools() {
  print_current_function_name "RUNNING TEST> "  ".."
  (
    local E
    E="$(cat "$PROJECT_DIR/test/resources/github-context-sample-01.json")"

    # shellcheck disable=2034
    {    
      EE_PARSED_CONTEXT=""
      ENTANDO_OPT_CLONE_URL_OVERRIDE=""
    }
    _ppl-load-context "$E"

    ASSERT --censor EE_PARSED_CONTEXT = "$E"
    ASSERT --censor PPL_TOKEN = "999999999"
    ASSERT EE_BASE_REF = "develop"
    ASSERT EE_HEAD_REF = "github-actions-pipeline-exp2"
    ASSERT EE_COMMIT_ID = "239d3c0153e609a84747e129c7bfd2f415743551"
    ASSERT EE_CLONE_URL = "https://github.com/entando/entando-engine.git"
    ASSERT EE_STATUSES_URL = "https://api.github.com/repos/entando/entando-engine/statuses/{sha}"
    ASSERT EE_ISSUES_URL = "https://api.github.com/repos/entando/entando-engine/issues{/number}"
    ASSERT EE_PR_NUM = "154"
    ASSERT EE_PR_TITLE = "ENG-2471 GitHub actions pipeline exp2"
    ASSERT EE_PR_LABELS = ",do-not-merge/work-in-progress,size/XXL,"

    _ppl-pr-has-label "do-not-merge/work-in-progress" || FAILED
    _ppl-pr-has-label "size/XXL" || FAILED
    _ppl-pr-has-label "do-not-merge" && FAILED
    
    true
  )
}

true
