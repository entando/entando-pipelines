#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/misc.sh"
  . "$PROJECT_DIR/lib/semver.sh"
}

#TEST:lib
test_misc() {
  test_url_utils
  test_tpl_utils
  test_pr_utils
  test_itmlst_utils
  test_semver_cmp
  test_args
  
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

test_args() {
  print_current_function_name "RUNNING TEST> "  ".."
  # shellcheck disable=SC2034
  ARGS_FLAGS=(--temp --splat)
  PARSE_ARGS --temp 1 55 --set 2 --with calm 101 -a "103" -- -b 999 --raise --splat
  ASSERT -v NUM_ARGS_POS "${#ARGS_POS[@]}" = 8
  ASSERT -v NUM_ARGS_OPT "${#ARGS_OPT[@]}" = 5
  ASSERT "ARGS_POS[0]" = ""
  ASSERT "ARGS_POS[1]" = 1
  ASSERT "ARGS_POS[2]" = 55
  ASSERT "ARGS_POS[3]" = 101
  ASSERT "ARGS_POS[4]" = "-b"
  ASSERT "ARGS_POS[5]" = 999
  ASSERT "ARGS_POS[6]" = "--raise"
  ASSERT "ARGS_POS[7]" = "--splat"
  ASSERT "ARGS_OPT[--set]" = "2"
  ASSERT "ARGS_OPT[--with]" = "calm"
  ASSERT "ARGS_OPT[-a]" = "103"
  ASSERT "ARGS_OPT[--temp]" = true
  ASSERT "ARGS_OPT[--splat]" = false
  
  local RES
  _get_arg RES --with
  ASSERT RES = "calm"
  _get_arg RES 3
  ASSERT RES = 101
  _get_arg RES unexistent a-fallback
  ASSERT RES = a-fallback
}

true
