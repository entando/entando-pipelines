#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/misc.sh"
}

#TEST:lib
test_misc() {
  test_url_utils
  test_tpl_utils
  test_pr_utils
  test_semver_utils
  test_itmlst_utils
  test_semver_cmp

  true
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
  local maj min ptc tag
  print_current_function_name "RUNNING TEST> "  ".."
  _semver_parse maj min ptc tag "1.2.3"
  ASSERT -v RES "$maj.$min.$ptc-$tag" = "1.2.3-"
  _semver_parse maj min ptc tag "1.2.3-SNAPSHOT"
  ASSERT -v RES "$maj.$min.$ptc-$tag" = "1.2.3-SNAPSHOT"
  _semver_parse maj min ptc tag "1"
  ASSERT -v RES "$maj.$min.$ptc-$tag" = "1..-"
  _semver_parse maj min ptc tag ""
  ASSERT -v RES "$maj.$min.$ptc-$tag" = "..-"
  _semver_parse maj "" ptc "" "1.2.3-4"
  ASSERT -v RES "$maj.$min.$ptc-$tag" = "1..3-"
  _semver_parse maj min ptc tag "v1.2.3"
  ASSERT -v RES "$maj.$min.$ptc-$tag" = "1.2.3-"
  _semver_parse maj min ptc tag "v.2.3"
  ASSERT -v RES "$maj.$min.$ptc-$tag" = ".2.3-"
  _semver_parse maj min ptc tag "1.2.3-SNAPSHOT"
  ASSERT -v RES "$maj.$min.$ptc-$tag" = "1.2.3-SNAPSHOT"

  # ~ SET TAG
  _semver_set_tag RES "1.2.3" "SNAPSHOT"
  ASSERT RES = "1.2.3-SNAPSHOT"
  _semver_set_tag RES "1.2.3-SNAPSHOT" "PREVIEW-01"
  ASSERT RES = "1.2.3-PREVIEW-01"
  _semver_set_tag RES "1.2.3-PREVIEW-01" "PREVIEW-02"
  ASSERT RES = "1.2.3-PREVIEW-02"
  
  # ~ ADD
  _semver_add RES "1.2.3" 0 0 1
  ASSERT RES = "1.2.4"
  _semver_add RES "1.2.3" 1 2 3
  ASSERT RES = "2.4.6"
  _semver_add RES "1.2.3-SNAPSHOT" 1 2 3
  ASSERT RES = "2.4.6-SNAPSHOT"
}

test_itmlst_utils() {
  local itmlst
  _itmlst_fill itmlst "red" "green" "blue"
  _itmlst_contains "$itmlst" "red"  || FAILED
  _itmlst_contains "$itmlst" "green" || FAILED
  _itmlst_contains "$itmlst" "blue"  || FAILED
  _itmlst_contains "$itmlst" "blu" && FAILED
}

test_semver_cmp() {
  local RES
  _semver_cmp RES "6.3.0" "6.3.0"
  ASSERT RES = 0
  _semver_cmp RES "6.3.0" "6.3.1"
  ASSERT RES = -1
  _semver_cmp RES "6.3.1" "6.3.0"
  ASSERT RES = 1
  _semver_cmp RES "6.3.01" "6.3.0"
  ASSERT RES = 1
  _semver_cmp RES "6.3.001" "6.3.1"
  ASSERT RES = 0
  _semver_cmp RES "6.3" "6.3.1"
  ASSERT RES = -1
  _semver_cmp RES "6" "6.0"
  ASSERT RES = 0
  _semver_cmp RES "6" "6.00"
  ASSERT RES = 0
  _semver_cmp RES "6" "6.0.0"
  ASSERT RES = 0
}

true
