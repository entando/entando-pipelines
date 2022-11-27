#/bin/bash

_require "lib/local/git.sh"

#TEST:unit,lib,local,x
git.test.full_clone() {
  
  git.test.prepare.local-repo "test-repo" || _SOE
  local TEST_REPO_URL="file://$PWD/test-repo"
  
  ( _IT "should simply clone a repo"
  
    git.full_clone "$TEST_REPO_URL" "local-clone"
    __cd "local-clone"
    local T="test-file"
    __exist -f "$T"
    
    _ASSERT -v test_file_content "$(cat "$T")" = "test-file-C2"

    __git reset --hard HEAD~1
    _ASSERT -v test_file_content "$(cat "$T")" = "test-file-C1"
  )
  
  rm -rf "local-clone"
  
  ( _IT "should clone a specific branch of a repo"
  
    git.full_clone "$TEST_REPO_URL" "local-clone" "feature-01"
    __cd "local-clone"
    local T="test-file"
    __exist -f "$T"
    
    _ASSERT -v test_file_content "$(cat "$T")" = "test-file-FF"
  )
  
  rm -rf "local-clone"
  
  ( _IT "should shallow clone a repo"
  
    git.full_clone "$TEST_REPO_URL" "local-clone"
    local T="local-clone/test-file"
    __exist -f "$T"
    _ASSERT -v test_file_content "$(cat "$T")" = "test-file-C2"
    
    (__git reset --hard HEAD~1 &> /dev/null)
    _ASSERT -v test_file_content "$(cat "$T")" = "test-file-C2"
  )
  
  rm -rf "local-clone"
  
  ( _IT "should clone a repo with a token"
  
    git.full_clone "$TEST_REPO_URL" "local-clone" "feature-01" "TEST-TOKEN-b0be6f3f"
    __cd "local-clone"
    local T="test-file"
    __exist -f "$T"
    
    _ASSERT -v test_file_content "$(cat "$T")" = "test-file-FF"
    git config --get remote.origin.url
    _ASSERT -v TOKEN "$(git config --get remote.origin.url)" =~ "TEST-TOKEN-b0be6f3f"
  )
  
  rm -rf "local-clone"
}


#-----------------------------------------------------------------------------------------------------------------------
# SUBORDINATE FUNCTIONS

git.test.prepare.local-repo() {
  (
    mkdir "$1"
    __cd "$1"
    echo -n "test-file-C1" > "test-file"
    git init
    git checkout -b develop
    git.set_commit_config "$TEST_GIT_USER_NAME" "$TEST_GIT_USER_EMAIL"
    git add -A
    git commit -m "first commit"
    echo -n "test-file-C2" > "test-file"
    git add -A
    git commit -m "second commit"
    git checkout -b "feature-01"
    echo -n "test-file-FF" > "test-file"
    git add -A
    git commit -m "feature commit"
    git checkout develop
  ) 1>/dev/null
}
