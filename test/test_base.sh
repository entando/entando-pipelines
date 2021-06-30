#!/bin/bash

# shellcheck disable=SC1091,SC1090
. "$PROJECT_DIR/lib/base.sh"

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
  [ "$RES" = "http://my.domain/test" ] || FAILED
  _url_add_token RES "http://my.domain/test" "XXX"
  [ "$RES" = "http://XXX@my.domain/test" ] || FAILED
  _url_add_token RES "http://YY@my.domain/test" "XXX"
  [ "$RES" = "http://XXX@my.domain/test" ] || FAILED
}

test_tpl_utils() {
  print_current_function_name "RUNNING TEST> "  ".."
  local S="https://api.github.com/repos/myorg/myrepo/git/trees{/sha}{/sha2}/sha{/sha}"
  _tpl_set_var S "$S" \
    "/sha" "/XXXX" \
    "/sha2" "/YYYY"
    
  [ "$S" = "https://api.github.com/repos/myorg/myrepo/git/trees/XXXX/YYYY/sha/XXXX" ] \
    || FAILED
}

test_pr_utils() {
  local RES
  _extract_pr_title_prefix RES "ENG-101 A title"
  ASSERT RES="ENT-101"
  _extract_pr_title_prefix RES "ENG-1002: A title"
  ASSERT RES="ENT-102"
}

test_semver_utils() {
  # ~ PARSE
  local maj min ptc upd
  print_current_function_name "RUNNING TEST> "  ".."
  _semver_parse "1.2.3" maj min ptc upd
  [ "$maj.$min.$ptc.$upd" = "1.2.3." ] || FAILED
  _semver_parse "1.2.3.4" maj min ptc upd
  [ "$maj.$min.$ptc.$upd" = "1.2.3.4" ] || FAILED
  _semver_parse "1" maj min ptc upd
  [ "$maj.$min.$ptc.$upd" = "1..." ] || FAILED
  _semver_parse "" maj min ptc upd
  [ "$maj.$min.$ptc.$upd" = "..." ] || FAILED
  _semver_parse "1.2.3.4" maj "" ptc ""
  [ "$maj.$min.$ptc.$upd" = "1..3." ] || FAILED
  _semver_parse "v1.2.3" maj min ptc upd
  [ "$maj.$min.$ptc.$upd" = "1.2.3." ] || FAILED
  _semver_parse "v.2.3" maj min ptc upd
  [ "$maj.$min.$ptc.$upd" = ".2.3." ] || FAILED
  
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
