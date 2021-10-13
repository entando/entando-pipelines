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
  test_str
  test_versioning
  
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
  _extract_pr_title_prefix RES "Revert \"ENG-101/ENG-102: A title\""
  ASSERT RES = "ENG-101/ENG-102"

  _ppl_extract_artifact_qualifier_from_pr_title RES "ENG-101 A title"
  ASSERT RES = "ENG-101"
  _ppl_extract_artifact_qualifier_from_pr_title RES "ENG-101/ENG-102: A title"
  ASSERT RES = "ENG-101"
  _ppl_extract_artifact_qualifier_from_pr_title RES "Revert \"ENG-101/ENG-102: A title\""
  ASSERT RES = "ENG-101"
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

  RES="$(_str_quote "Started publication as 101")"
  ASSERT RES = '"Started publication as 101"'
  RES="$(_str_quote -s "Started publication as 101")"
  ASSERT RES = 'Started publication as 101'
}

#TEST:lib
test_stream_utils() {
  print_current_function_name "RUNNING TEST> "  ".."

  
  local RES="$(
    _summarize_stream --lf --li 3 --ti 0 TEST < <(
      for ((i=0;i<10;i++)); do
        echo "dsaas   ERROR  das"
        echo "saad WARN asdsa"
      done
    ) | sed 's/SEC:\s*[0-9]*/../';
    echo "X"
  )"
  
  RES="${RES:0:-1}"
  
  local EXP
  EXP+="~ TEST > | .. | TOT:      1  | ERR:      1 | WRN:      0 | DNL:      0 |       "$'\n'
  EXP+="~ TEST > | .. | TOT:      4  | ERR:      2 | WRN:      2 | DNL:      0 |       "$'\n'
  EXP+="~ TEST > | .. | TOT:      7  | ERR:      4 | WRN:      3 | DNL:      0 |       "$'\n'
  EXP+="~ TEST > | .. | TOT:     10  | ERR:      5 | WRN:      5 | DNL:      0 |       "$'\n'
  EXP+="~ TEST > | .. | TOT:     13  | ERR:      7 | WRN:      6 | DNL:      0 |       "$'\n'
  EXP+="~ TEST > | .. | TOT:     16  | ERR:      8 | WRN:      8 | DNL:      0 |       "$'\n'
  EXP+="~ TEST > | .. | TOT:     19  | ERR:     10 | WRN:      9 | DNL:      0 |       "$'\n'
  EXP+="~ TEST > | .. | TOT:     20  | ERR:     10 | WRN:     10 | DNL:      0 |       "$'\n'
  
  ASSERT RES = "$EXP"
}

#TEST:lib
test_exec_cmd() {
  local RES
  
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
      return 1
    }

    local TMPFILE="$(mktemp)"
    # shellcheck disable=SC2064
    trap "rm \"$TMPFILE\"" exit

    RES="$(_exec_cmd \
      --hide "Progress.* kB" \
      --hide "Error message = null" \
      --pe \
      --po "$TMPFILE" \
      "_TEXT__EXEC_CMD_SAMPLE"
    )"
    
    N1="$(echo "$RES" | grep -c "Line")"
    N2="$(echo "$RES" | grep -c "Important Error")"
    N3="$(echo "$RES" | grep -c -E "^\s+at\s")"
    N4="$(echo "$RES" | grep -c "Error message")"
    N5="$(echo "$RES" | grep -c "Progress")"
    
    ASSERT -v RES "$N1" = 100
    ASSERT -v RES "$N2" = 200
    ASSERT -v RES "$N3" = 100
    ASSERT -v RES "$N4" = 200
    ASSERT -v RES "$N5" = 100
    
    N1="$(grep -c "Line" "$TMPFILE")"
    N2="$(grep -c "Important Error" "$TMPFILE")"
    N3="$(grep -c "Error message" "$TMPFILE")"
    N4="$(grep -c "Progress" "$TMPFILE")"
    
    ASSERT -v RES "$N1" = 100
    ASSERT -v RES "$N2" = 100
    ASSERT -v RES "$N3" = 200
    ASSERT -v RES "$N4" = 100

  ) || _SOE
}

test_versioning() {
  print_current_function_name "RUNNING TEST> "  ".."

  local RES
  _ppl_extract_snapshot_version_name_part RES "6.4.0-ENG-2268-PR-143" "base-version"
  ASSERT RES = "6.4.0"
  _ppl_extract_snapshot_version_name_part RES "6.4.0-ENG-2268-PR-143" "qualifier"
  ASSERT RES = "ENG-2268"
  _ppl_extract_snapshot_version_name_part RES "6.4.0-ENG-2268-PR-143" "pr-num"
  ASSERT RES = "143"
  _ppl_extract_snapshot_version_name_part RES "v6.4.0-ENG-2268-PR-143" "base-version"
  ASSERT RES = "6.4.0"
}
true
