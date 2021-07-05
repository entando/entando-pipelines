#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/base.sh"
  . "$PROJECT_DIR/lib/git.sh"
}

#TEST:lib
test_git() {
  print_current_function_name "RUNNING TEST> "  ".."
  
  # TOOLS
  _git_ref_to_version RES 'refs/heads/6.3.2'
  [ "$RES" = "6.3.2" ] || FAILED "$LINENO $RES"
  _git_ref_to_version RES 'refs/heads/v6.3.2'
  [ "$RES" = "6.3.2" ] || FAILED "$LINENO $RES"
  
  # CONFIG AND CLONING
  (
    __cd "$TEST_WORK_DIR"
    
    _create-test-git-repo "git-repo-0bba91d9" "the-feature-branch" "v999.88.77"
    __cd "git-repo-0bba91d9"
    sleep 1.1   # <= this is intentional: Test needs a different timestamp
    __git_add_tag "66.66.66"
    __cd -
    
    _git_full_clone "./git-repo-0bba91d9" "clone-of-git-repo-0bba91d9"
    __cd "clone-of-git-repo-0bba91d9"
    ASSERT -v NUMTAGS "$(git tag | wc -l)" = "2"
    _git_determine_latest_version TMP
    ASSERT TMP = "66.66.66"
    _git_determine_highest_version TMP
    ASSERT TMP = "999.88.77"
  )
  
  rm -rf "$TEST_WORK_DIR/git-repo-0bba91d9"
  rm -rf "$TEST_WORK_DIR/clone-of-git-repo-0bba91d9"
  
  true
}

true
