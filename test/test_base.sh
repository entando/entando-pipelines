#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/base.sh"
}

#TEST:lib
test_base() {
  test_set_var
  test_url_utils
  test_tpl_utils
  test_pr_utils
  test_semver_utils
  test_itmlst_utils
  
  true
}

test_set_var() {
  print_current_function_name "RUNNING TEST> "  ".."
  _set_var RES "hey"
  [ "$RES" = "hey" ] || FAILED
}

test_url_utils() {
  print_current_function_name "RUNNING TEST> "  ".."
  _url_add_token RES "http://my.domain/test" ""
  ASSERT RES = "http://my.domain/test"
  _url_add_token RES "http://my.domain/test" "XXX"
  [ "$RES" = "http://XXX@my.domain/test" ] || FAILED
  _url_add_token RES "http://YY@my.domain/test" "XXX"
  [ "$RES" = "http://XXX@my.domain/test" ] || FAILED
}

test_tpl_utils() {
  print_current_function_name "RUNNING TEST> "  ".."
  local S="https://api.github.com/repos/myorg/myrepo/git/trees{/sha}{/sha2}/sha{/sha}"
  _tpl_set_var S "$S" \
    "sha" "XXXX" \
    "sha2" "YYYY"
    
  [ "$S" = "https://api.github.com/repos/myorg/myrepo/git/trees/XXXX/YYYY/sha/XXXX" ] \
    || FAILED
}

test_pr_utils() {
  local RES
  _extract_pr_title_prefix RES "ENG-101 A title"
  ASSERT RES = "ENG-101"
  _extract_pr_title_prefix RES "ENG-101/ENG-102: A title"
  ASSERT RES = "ENG-101/ENG-102"
}

test_semver_utils() {
  # ~ PARSE
  local maj min ptc upd
  print_current_function_name "RUNNING TEST> "  ".."
  _semver_parse maj min ptc upd "1.2.3"
  ASSERT -v RES "$maj.$min.$ptc.$upd" = "1.2.3."
  _semver_parse maj min ptc upd "1.2.3.4" 
  ASSERT -v RES "$maj.$min.$ptc.$upd" = "1.2.3.4"
  _semver_parse maj min ptc upd "1"
  ASSERT -v RES "$maj.$min.$ptc.$upd" = "1..."
  _semver_parse maj min ptc upd "" 
  ASSERT -v RES "$maj.$min.$ptc.$upd" = "..."
  _semver_parse maj "" ptc "" "1.2.3.4" 
  ASSERT -v RES "$maj.$min.$ptc.$upd" = "1..3."
  _semver_parse maj min ptc upd "v1.2.3" 
  ASSERT -v RES "$maj.$min.$ptc.$upd" = "1.2.3."
  _semver_parse maj min ptc upd "v.2.3" 
  ASSERT -v RES "$maj.$min.$ptc.$upd" = ".2.3."
  _semver_parse maj min ptc upd "1.2.3-SNAPSHOT"
  ASSERT -v RES "$maj.$min.$ptc.$upd" = "1.2.3."

  # ~ SET TAG
  _semver_set_tag RES "1.2.3" "SNAPSHOT"
  ASSERT RES = "1.2.3-SNAPSHOT"
  _semver_set_tag RES "1.2.3-SNAPSHOT" "PREVIEW-01"
  ASSERT RES = "1.2.3-PREVIEW-01"
  _semver_set_tag RES "1.2.3-PREVIEW-01" "PREVIEW-02"
  ASSERT RES = "1.2.3-PREVIEW-02"
}

test_itmlst_utils() {
  local itmlst
  _itmlst_fill itmlst "red" "green" "blue"
  _itmlst_contains "$itmlst" "red"  || FAILED
  _itmlst_contains "$itmlst" "green" || FAILED
  _itmlst_contains "$itmlst" "blue"  || FAILED
  _itmlst_contains "$itmlst" "blu" && FAILED
}

true
