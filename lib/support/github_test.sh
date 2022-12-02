#/bin/bash 

_require "lib/support/github.sh"


#TEST:unit,lib,support,github
_github.test._github.parse_context() {
  local CTX
  _LOAD_TEST_FILE CTX "github/pull-sync-context.json"
  _github.parse_context "$CTX" "PPL"
  
  _ASSERT PPL_COMMIT_ID = "21aa52f7f1adcadea778314255b528ec8c0c7a41"
  _ASSERT PPL_PR_TITLE = "ENG-2471 GitHub actions pipeline exp2"
  _ASSERT PPL_CLONE_URL = "https://github.com/entando/entando-engine.git"
}

# $$$:TO-REMOVE
# #TEST:unit,lib,support,github
# _github.test.extract_branch_name_from_ref() {
# 
#   ( _IT "Should properly extract the branch name from a github ref"
#   
#     local RES
#     _github.extract_branch_name_from_ref RES "refs/pull/167/merge"
#     _ASSERT RES = ""
#     _github.extract_branch_name_from_ref RES "refs/heads/develop"
#     _ASSERT RES = "develop"
#     _github.extract_branch_name_from_ref RES "refs/tags/v7.0.0-ENG-3002-PR-166"
#     _ASSERT RES = "v7.0.0-ENG-3002-PR-166"
#     _github.extract_branch_name_from_ref RES "refs/heads/release/1.2.3"
#     _ASSERT RES = "release/1.2.3"
#     _github.extract_branch_name_from_ref RES "refs/heads/epic/an-epic-branch"
#     _ASSERT RES = "epic/an-epic-branch"
#     _github.extract_branch_name_from_ref RES "refs/tags/TEST/v7.0.0-ENG-3002-PR-166"
#     _ASSERT RES = "TEST/v7.0.0-ENG-3002-PR-166"
#   )
# }
