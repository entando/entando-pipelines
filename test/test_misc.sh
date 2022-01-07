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
  test_itmlst_utils
  test_semver_cmp
  test_args
  test_str
  
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

#TEST:lib
test_pr_utils() {
  local RES

  _extract_pr_title_prefix RES "ENG-101 A title"
  ASSERT RES = "ENG-101"
  _extract_pr_title_prefix RES "ENG-101/ENG-102: A title"
  ASSERT RES = "ENG-101/ENG-102"
  _extract_pr_title_prefix RES "Revert \"ENG-101/ENG-102: A title\""
  ASSERT RES = "ENG-101/ENG-102"

  _ppl_extract_artifact_qualifier_from_pr_title RES "ENG-101 A title"
  ASSERT RES = "ENG-101"
  _ppl_extract_artifact_qualifier_from_pr_title RES "ENG-101/ENG-102: A title"
  ASSERT RES = "ENG-101"
  _ppl_extract_artifact_qualifier_from_pr_title RES "Revert \"ENG-101/ENG-102: A title\""
  ASSERT RES = "ENG-101"
  
  PPL_EPIC_NAME="an-epic"
  _ppl_extract_artifact_qualifier_from_pr_title --epic-name "an-epic" RES "an-epic/ENG-101 A title"
  ASSERT RES = "ENG-101"
  _ppl_extract_artifact_qualifier_from_pr_title --epic-name "an-epic" RES "an-epic/ENG-101/ENG-102: A title"
  ASSERT RES = "ENG-101"
  _ppl_extract_artifact_qualifier_from_pr_title --epic-name "an-epic" RES "Revert \"an-epic/ENG-101/ENG-102: A title\""
  ASSERT RES = "ENG-101"
  
  # shellcheck disable=SC2034
  PPL_EPIC_NAME="an-epic"
  _ppl_extract_artifact_qualifier_from_pr_title --epic-name "an-epic" RES "not-an-epic/ENG-101 A title"
  ASSERT RES = "not-an-epic"
  _ppl_extract_artifact_qualifier_from_pr_title --epic-name "an-epic" RES "not-an-epic/ENG-101/ENG-102: A title"
  ASSERT RES = "not-an-epic"
  _ppl_extract_artifact_qualifier_from_pr_title --epic-name "an-epic" RES "Revert \"not-an-epic/ENG-101/ENG-102: A title\""
  ASSERT RES = "not-an-epic"
}

test_itmlst_utils() {
  local itmlst
  _itmlst_fill itmlst "red" "green" "blue"
  _itmlst_contains "$itmlst" "red"  || FAILED
  _itmlst_contains "$itmlst" "green" || FAILED
  _itmlst_contains "$itmlst" "blue"  || FAILED
  _itmlst_contains "$itmlst" "blu" && FAILED
  
  _itmlst_from_string itmlst ""
  _itmlst_is_item_enabled "$itmlst" "red" && FAILED
  
  _itmlst_from_string itmlst "red,green|blue"$'\n'"yellow"
  _itmlst_is_item_enabled "$itmlst" "red" || FAILED
  _itmlst_is_item_enabled "$itmlst" "green" || FAILED
  _itmlst_is_item_enabled "$itmlst" "blue" || FAILED
  _itmlst_is_item_enabled "$itmlst" "yellow" || FAILED
  
  _itmlst_from_string itmlst "*"
  _itmlst_is_item_enabled "$itmlst" "red" || FAILED
  _itmlst_is_item_enabled "$itmlst" "green" || FAILED
  _itmlst_is_item_enabled "$itmlst" "blue" || FAILED
  _itmlst_is_item_enabled "$itmlst" "yellow" || FAILED

  _itmlst_from_string itmlst "*,-blue"
  _itmlst_is_item_enabled "$itmlst" "red" || FAILED
  _itmlst_is_item_enabled "$itmlst" "green" || FAILED
  _itmlst_is_item_enabled "$itmlst" "blue" && FAILED
  _itmlst_is_item_enabled "$itmlst" "yellow" || FAILED
  
  _itmlst_from_string itmlst "red,green|blue"$'\n'"yellow|-*|blue"
  _itmlst_is_item_enabled "$itmlst" "red" && FAILED
  _itmlst_is_item_enabled "$itmlst" "green" && FAILED
  _itmlst_is_item_enabled "$itmlst" "blue" || FAILED
  _itmlst_is_item_enabled "$itmlst" "yellow" && FAILED
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

#TEST:lib
test_args() {
  print_current_function_name "RUNNING TEST> "  ".."
  # shellcheck disable=SC2034
  ARGS_FLAGS=(--temp --splat)
  PARSE_ARGS --temp 1 --mark X 55 --set 2 --with calm 101 -a "103" -- -b 999 --raise --splat --blot 1
  ASSERT -v NUM_ARGS_POS "${#ARGS_POS[@]}" = 10
  ASSERT -v NUM_ARGS_OPT "${#ARGS_OPT[@]}" = 6
  ASSERT "ARGS_POS[0]" = ""
  ASSERT "ARGS_POS[1]" = 1
  ASSERT "ARGS_POS[2]" = 55
  ASSERT "ARGS_POS[3]" = 101
  ASSERT "ARGS_POS[4]" = "-b"
  ASSERT "ARGS_POS[5]" = 999
  ASSERT "ARGS_POS[6]" = "--raise"
  ASSERT "ARGS_POS[7]" = "--splat"
  ASSERT "ARGS_POS[8]" = "--blot"
  ASSERT "ARGS_POS[9]" = "1"
  ASSERT "ARGS_OPT[--set]" = "2"
  ASSERT "ARGS_OPT[--with]" = "calm"
  ASSERT "ARGS_OPT[-a]" = "103"
  ASSERT "ARGS_OPT[--temp]" = true
  ASSERT "ARGS_OPT[--mark]" = X
  ASSERT "ARGS_OPT[--splat]" = false
  
  local RES
  _get_arg RES --with
  ASSERT RES = "calm"
  _get_arg RES 3
  ASSERT RES = 101
  _get_arg RES unexistent a-fallback
  ASSERT RES = a-fallback
  _get_arg RES unexistent a-fallback
  ASSERT RES = a-fallback
}

test_str() {
  print_current_function_name "RUNNING TEST> "  ".."
  
  local RES
  _str_last_pos RES ",10,11,12,11,13" "11"
  ASSERT RES = 4
  _str_last_pos RES ",10,11,12,*,13" "*"
  ASSERT RES = 4
  
  local RES='hey'
  _decode_entando_opt RES
  ASSERT RES = 'hey'
  local RES='###hey'
  _decode_entando_opt RES
  ASSERT RES = 'hey'
  local RES='###'$'\n''hey'
  _decode_entando_opt RES
  ASSERT RES = 'hey'

  # shellcheck disable=SC2034
  ENTANDO_OPT_A_TEST="###a-test"
  _auto_decode_entando_opts
  ASSERT ENTANDO_OPT_A_TEST = 'a-test'
  
  #~
  RES="$(_str_quote "Started publication as 101")"
  ASSERT RES = '"Started publication as 101"'
  RES="$(_str_quote -s "Started publication as 101")"
  ASSERT RES = 'Started publication as 101'
  
  RES="$(_str_escape_char "sdasda/Dsdaas" "/")"
  ASSERT RES = 'sdasda\/Dsdaas'
  
  #~
  (
    PARSE_ARGS --ENTANDO_OPT_A_TEST="another-test" --ENTANDO_TEST 1
    _read_entando_options_from_args -e
    ASSERT ENTANDO_OPT_A_TEST = 'another-test'
    ASSERT ENTANDO_TEST = ''
    ASSERT -v EXPORTED_ENTANDO_OPT_A_TEST "$(bash -c 'echo $ENTANDO_OPT_A_TEST')" = 'another-test'
  )
}

#TEST:lib
test_stream_utils() {
  print_current_function_name "RUNNING TEST> "  ".."

  local LOREM_IPSUM="Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod"
  LOREM_IPSUM+=" tempor incididunt ut labore et dolore magna aliqua."
    
  local RES="$(
    _summarize_stream --ppl-pg 3 TEST < <(
      for i in {1..9}; do
          echo "LINE$i: $LOREM_IPSUM"
          [ "$i" = "5" ] && echo -e "LINE${i}.b: ERROR: RANDOM ERROR\nat this #1\nat this #2\nat this #3"
      done
    ) | sed 's/SEC:\s*[0-9]*/SEC: ../';
    echo "X"
  )"
  
  RES="${RES:0:-1}"

  EXP+="::group::~ TEST > | START:      1 || SEC: .. | ERR:     0 (+0)   | WRN:     0 (+0)   | DNL:      0 |"$'\n'
  EXP+="LINE1: $LOREM_IPSUM"$'\n'
  EXP+="LINE2: $LOREM_IPSUM"$'\n'
  EXP+="LINE3: $LOREM_IPSUM"$'\n'
  EXP+="::endgroup::"$'\n'
  EXP+="::group::~ TEST > | START:      4 || SEC: .. | ERR:     1 (+1)   | WRN:     0 (+0)   | DNL:      0 |"$'\n'
  EXP+="LINE4: $LOREM_IPSUM"$'\n'
  EXP+="LINE5: $LOREM_IPSUM"$'\n'
  EXP+="LINE5.b: ERROR: RANDOM ERROR"$'\n'
  EXP+="at this #1"$'\n'
  EXP+="at this #2"$'\n'
  EXP+="at this #3"$'\n'
  EXP+="::endgroup::"$'\n'
  EXP+="::group::~ TEST > | START:     10 || SEC: .. | ERR:     1 (+0)   | WRN:     0 (+0)   | DNL:      0 |"$'\n'
  EXP+="LINE6: $LOREM_IPSUM"$'\n'
  EXP+="LINE7: $LOREM_IPSUM"$'\n'
  EXP+="LINE8: $LOREM_IPSUM"$'\n'
  EXP+="::endgroup::"$'\n'
  EXP+="::group::~ TEST > | START:     13 || SEC: .. | ERR:     1 (+0)   | WRN:     0 (+0)   | DNL:      0 |"$'\n'
  EXP+="LINE9: $LOREM_IPSUM"$'\n'
  EXP+="::endgroup::"$'\n'

 # echo "$RES" > /tmp/a
  #echo "$EXP" > /tmp/b
  #meld /tmp/a /tmp/b
  
  ASSERT RES = "$EXP"
}

#TEST:lib
test_exec_cmd() {
  local RES
  
  # STARDARD EXECUTION
  # Both the summary and the full ourput are printed
  
  (
    _TEXT__EXEC_CMD_SAMPLE() {  
      for ((i=0;i<100;i++)); do
        echo "Line (${i})"
        echo "Progress 20 kB (${i})"
        echo "Important Error (${i})"
        echo "  at XXX (${i})"
        echo "Error message = null (${i}/a)"
        echo "Error message = null (${i}/b)"
      done
      return 55
    }
    
    #~~~

    local TMPFILE="$(mktemp)"
    # shellcheck disable=SC2064
    trap "rm \"$TMPFILE\"" exit
    
    RES="$(_exec_cmd \
      --hide "Progress.* kB" \
      --hide "Error message = null" \
      "_TEXT__EXEC_CMD_SAMPLE"

      ASSERT -v RESCODE "$?" = 55
    )"

    N1="$(echo "$RES" | grep -c "Line")"
    N2="$(echo "$RES" | grep -c "Important Error")"
    N3="$(echo "$RES" | grep -c -E "^\s+at\s")"
    N4="$(echo "$RES" | grep -c "Error message")"
    N5="$(echo "$RES" | grep -c "Progress")"
    
    # Both summarised and full log are printed
    
    ASSERT -v RES "$N1" = 100       # Standard lines are only printed in the full log 
    ASSERT -v RES "$N2" = 100       # Error lines if not explicitly
    ASSERT -v RES "$N3" = 100       # "  at" strings following an error shares the same visibility
    ASSERT -v RES "$N4" = 0         # Even error lines when explicitly filtered are hidden
    ASSERT -v RES "$N5" = 100       # Filtered lines only on the full log
  ) || _SOE
}

#TEST:lib
test_versioning_utils() {
  print_current_function_name "RUNNING TEST> "  ".."

  local ENCODED_REF="$(_ppl_encode-branch-for-tagging "KB" "epic/an-epic-branch")"
  ASSERT ENCODED_REF = "KB-epic+2F+an-epic-branch"
  
  local RES
  _ppl_extract_version_part RES "6.4.0-ENG-2268-PR-143+$ENCODED_REF" "base-version"
  ASSERT RES = "6.4.0"
  _ppl_extract_version_part RES "6.4.0-ENG-2268-PR-143+$ENCODED_REF" "qualifier"
  ASSERT RES = "ENG-2268"
  _ppl_extract_version_part RES "6.4.0-ENG-2268-PR-143+$ENCODED_REF" "pr-num"
  ASSERT RES = "143"
  _ppl_extract_version_part RES "v6.4.0-ENG-2268-PR-143+$ENCODED_REF" "base-version"
  ASSERT RES = "6.4.0"
  _ppl_extract_version_part RES "v6.4.0-ENG-2268-PR-143+$ENCODED_REF" "base-version"
  ASSERT RES = "6.4.0"
  _ppl_extract_version_part RES "v6.4.0-ENG-2268-PR-143+$ENCODED_REF" "meta:kb"
  ASSERT RES = "epic/an-epic-branch"
}

#TEST:lib
test__features() {
  print_current_function_name "RUNNING TEST> "  ".."
  
  # shellcheck disable=SC2034
  PPL_PARSED_CONTEXT="[test]"
  # shellcheck disable=SC2034
  PPL_FEATURES="MTX-SCAN-SNYK,MTX-MVN-SCAN-OWASP,DISABLE-INTEGRATION-TESTS,MVN-QUARKUS-NATIVE"
  _ppl_is_feature_enabled "MVN-QUARKUS-NATIVE" || {
    _FATAL -99 "Feature was configured but is has not been detected" 1>&2
  }
  _ppl_is_feature_enabled "MVN-VERIFY" && {
    _FATAL -99 "Feature was detected but was not actually configured" 1>&2
  }
  # shellcheck disable=SC2034
  PPL_FEATURES="-INHERIT-GLOBAL-FEATURES"
  _ppl_is_feature_enabled "INHERIT-GLOBAL-FEATURES" true && {
    _FATAL -99 "Feature was detected but was not actually configured" 1>&2
  }
  true
}

#TEST:lib
test__ppl_setup_custom_environment() {
  print_current_function_name "RUNNING TEST> "  ".."
  
  # shellcheck disable=SC2034
  local Z="_Z" K="_K"
  _ppl_setup_custom_environment "X=XX;Y=YY;Z=ZZ;W=W\;W"
  RES="$(bash -c 'echo "$X/$Y/$Z/$K/$W"')"
  echo "$RES"
  ASSERT RES = "XX/YY/ZZ//W;W"
}

#TEST:lib
test__ppl_extract_branch_name_from_ref() {
  print_current_function_name "RUNNING TEST> "  ".."

  local RES
  _ppl_extract_branch_name_from_ref RES "refs/pull/167/merge"
  ASSERT RES = ""
  _ppl_extract_branch_name_from_ref RES "refs/heads/develop"
  ASSERT RES = "develop"
  _ppl_extract_branch_name_from_ref RES "refs/tags/v7.0.0-ENG-3002-PR-166"
  ASSERT RES = "v7.0.0-ENG-3002-PR-166"
  _ppl_extract_branch_name_from_ref RES "refs/heads/release/1.2.3"
  ASSERT RES = "release/1.2.3"
  _ppl_extract_branch_name_from_ref RES "refs/heads/epic/an-epic-branch"
  ASSERT RES = "epic/an-epic-branch"
  _ppl_extract_branch_name_from_ref RES "refs/tags/TEST/v7.0.0-ENG-3002-PR-166"
  ASSERT RES = "TEST/v7.0.0-ENG-3002-PR-166"
}

#TEST:lib
test__ppl_extract_branch_short_name() {
  print_current_function_name "RUNNING TEST> "  ".."
  local RES
  #~ PRs
  _ppl_extract_branch_short_name RES "develop"
  ASSERT RES = ""
  _ppl_extract_branch_short_name RES "epic/mylongrunningbranch"
  ASSERT RES = "mylongrunningbranch"
  _ppl_extract_branch_short_name RES "epic/my-long-running-branch"
  ASSERT RES = "my-long-running-branch"
  _ppl_extract_branch_short_name RES "release/1.2.3"
  ASSERT RES = "1.2.3"
}

#TEST:lib
test__ppl_is_release_version_number() {
  print_current_function_name "RUNNING TEST> "  ".."
  _ppl_is_release_version_number "v1.2.3"
  ASSERT -v RES $? = 0
  _ppl_is_release_version_number "1.2.3"
  ASSERT -v RES $? = 0
  _ppl_is_release_version_number "1.2.3-fix.1"
  ASSERT -v RES $? = 0
  _ppl_is_release_version_number "v1.2.3-SNAPSHOT"
  ASSERT -v RES $? != 0
  _ppl_is_release_version_number "1.2.3-SNAPSHOT"
  ASSERT -v RES $? != 0
  _ppl_is_release_version_number "1.2.3-fix.1-SNAPSHOT"
  ASSERT -v RES $? != 0
}

#TEST:lib
test_path_functions() {
  print_current_function_name "> " ".."
  # shellcheck disable=SC2034
  local CONCAT_RES
  
  ASSERT -v CONCAT_RES "$(path-concat)" = ""
  ASSERT -v CONCAT_RES "$(path-concat "")" = ""
  ASSERT -v CONCAT_RES "$(path-concat "" "")" = ""
  ASSERT -v CONCAT_RES "$(path-concat "a" "b")" = "a/b"
  ASSERT -v CONCAT_RES "$(path-concat "a/" "b")" = "a/b"
  ASSERT -v CONCAT_RES "$(path-concat "a" "/b")" = "a/b"
  ASSERT -v CONCAT_RES "$(path-concat "a/" "/b")" = "a/b"
  ASSERT -v CONCAT_RES "$(path-concat "a" "")" = "a/"
  ASSERT -v CONCAT_RES "$(path-concat "a/" "")" = "a/"
  ASSERT -v CONCAT_RES "$(path-concat "" "b")" = "b"
  ASSERT -v CONCAT_RES "$(path-concat "" "/b")" = "/b"
  ASSERT -v CONCAT_RES "$(path-concat "a" "b" "c")" = "a/b/c"
  ASSERT -v CONCAT_RES "$(path-concat "a" "b" "c" "")" = "a/b/c/"
}
