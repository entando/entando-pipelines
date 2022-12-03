#/bin/bash 

_require "lib/support/github.sh"


#TEST:unit,lib,support,github
_github.test._github.parse_context() {
  local CTX
  _LOAD_TEST_FILE CTX "github/pull-sync-context.json"
  _github.parse_context "$CTX" "PPL"
  
  ( _IT "should properly extract the essential data"
    
    _ASSERT PPL_COMMIT_ID = "21aa52f7f1adcadea778314255b528ec8c0c7a41"
    _ASSERT PPL_PR_TITLE = "ENG-2471 GitHub actions pipeline exp2"
    _ASSERT PPL_CLONE_URL = "https://github.com/entando/entando-engine.git"
    _ASSERT PPL_BRANCH = "github-actions-pipeline-exp2"
  )
}
