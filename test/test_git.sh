#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/base.sh"
  . "$PROJECT_DIR/lib/semver.sh"
  . "$PROJECT_DIR/lib/git.sh"
}

#TEST:lib
test_git() {
  test_git_base
  test_git_utils
  test_git_advanced
}

test_git_base() {
  print_current_function_name "RUNNING TEST> "  ".."
  
  # TOOLS
  _git_ref_to_version RES 'refs/heads/6.3.2'
  [ "$RES" = "6.3.2" ] || FAILED "$LINENO $RES"
  _git_ref_to_version RES 'refs/heads/v6.3.2'
  [ "$RES" = "6.3.2" ] || FAILED "$LINENO $RES"
  
  # CONFIG AND CLONING
  (
    __cd "$TEST__WORK_DIR"
    
    _create-test-git-repo "git-repo-0bba91d9" "the-feature-branch" "v999.88.77"
    __cd "git-repo-0bba91d9"
    
    sleep 1.1   # <= this is intentional: Test needs a different timestamp
    __git_add_tag "v66.66.66"
    __cd -
    
    _git_full_clone "./git-repo-0bba91d9" "clone-of-git-repo-0bba91d9"
    __cd "clone-of-git-repo-0bba91d9"
    _git_auto_setup_commit_config
    ASSERT -v NUMTAGS "$(git tag | wc -l)" = "2"
    _git_determine_latest_version TMP
    ASSERT TMP = "66.66.66"
    _git_determine_highest_version TMP
    ASSERT TMP = "999.88.77"
    __git_add_tag "v999.88.77.1"
    _git_determine_highest_version TMP
    ASSERT TMP = "999.88.77.1"
    _git_determine_highest_version --for "66.66" TMP
    ASSERT TMP = "66.66.66"
    __git_add_tag "v66.66.67"
    _git_determine_highest_version --for "66.66" TMP
    ASSERT TMP = "66.66.67"

    __cd -
     
    _git_full_clone --as-work-area "./git-repo-0bba91d9"
    ASSERT -v "$CURRENT_DIR" "${PWD##*/}" = "git-repo-0bba91d9"
  ) || _SOE
  
  rm -rf "$TEST__WORK_DIR/git-repo-0bba91d9"
  rm -rf "$TEST__WORK_DIR/clone-of-git-repo-0bba91d9"
  
  true
}

test_git_advanced() {
  print_current_function_name "RUNNING TEST> "  ".."
  
  _create-test-git-repo "git-repo-0bba91d9" "git-repo-0bba91d9"
  __cd "git-repo-0bba91d9"
  
  __git_auto_checkout "develop"
  
  __git_auto_checkout "release"
  echo -e "line DEV\nline REL" > fileA1.txt
  echo -e "line DEV\nline REL" > fileB1.txt
  __git add .
  echo -e "line DEV\nline REL" > fileB2.txt
  mkdir dirB1
  __git add .
  __git commit -m "a file on release"
  
  __git_auto_checkout "develop"
  echo -e "line DEV" > fileA1.txt
  echo -e "line DEV" > fileA2.txt
  __git add .
  __git commit -m "a file on develop"

  __git_auto_checkout "release"
  __git_force_merge_branch "develop"
  
  ASSERT -v CURRENT_BRANCH "$(git branch --show-current)" = "release"
  ASSERT -v FILE1_OK "$(cat fileA1.txt)" = "line DEV"
  [ -f fileA2.txt ] || FAILED "Expected \"fileA2.txt\" to be present but instead is not"
  [ -f fileB1.txt ] && FAILED "Expected \"fileB1.txt\" to not be present but instead it's still present"
  [ -f fileB2.txt ] && FAILED "Expected \"fileB2.txt\" to not be present but instead it's still present"ù
  [ -d dirB1 ] && FAILED "Expected \"dirB1\" to not be present but instead it's still present"

  cd ..
  rm -rf "$TEST__WORK_DIR/git-repo-0bba91d9"
}

#TEST:x
test_git_utils() {
  local RES
  local COMMIT_ID
  
  # TEST get commit tag / case 1
  print_current_function_name "RUNNING TEST> "  ".."
  _create-test-git-repo "git-repo-0bba91d9" "git-repo-0bba91d9"
  __cd "git-repo-0bba91d9"
  __git_get_commit_tag --snapshot-tag RES "HEAD"
  ASSERT RES = ""
  __git_add_tag "v999.88.77.1"
  __git_add_tag "vENG-9999-PR-111"
  __git_get_commit_tag RES "HEAD"
  ASSERT RES = "v999.88.77.1"
  __git_get_commit_tag --snapshot-tag RES "HEAD"
  ASSERT RES = "vENG-9999-PR-111"
  
  # TEST get commit tag / case 2
  COMMIT_ID="$(__git rev-parse --verify HEAD)"
  echo "change" > change.txt
  __git_ACTP "new-commit" "new-tag"
  __git_get_commit_tag --snapshot-tag RES "$COMMIT_ID"
  ASSERT RES = "vENG-9999-PR-111"
  
  
  # TEST get commit parent_pr
  __git checkout -b feature
  echo change2 > change2.txt
  __git_ACTP "change2"
  COMMIT_ID="$(__git rev-parse --verify HEAD)"
  __git switch -
  __git merge feature
  __git_get_parent_pr RES "HEAD"
  ASSERT RES = "$COMMIT_ID"
}

true
