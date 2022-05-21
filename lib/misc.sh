#!/bin/bash

# Adds a token or replaces a tocken to/in a URL
#
# Params:
# $1  destination var
# $2  url
# $3  token
#
_url_add_token() {
  local _tmp_="$2"
  local token="$3"
  if [ -n "$token" ]; then
    _tmp_="${_tmp_/:\/\/*@/:\/\/}"
    _tmp_="${_tmp_/:\/\//:\/\/$token@}"
  fi
  _set_var "$1" "$_tmp_"
}

# Gets the prefix of the PR title
#
# Params:
# $1 destination var
# $2 the PR title
#
_extract_pr_title_prefix() {
  local _tmp_="$2"
  [ "${_tmp_:0:8}" = "Revert \"" ] && _tmp_="${_tmp_:8}"
  _tmp_="${_tmp_//: */}"
  _tmp_="${_tmp_// */}"
  _set_var "$1" "$_tmp_"
}

# Gets from a PR title the part of the prefix that should qualify the artifacts
#
# Params:
# $1 destination var
# $2 the PR title
#
_ppl_extract_artifact_qualifier_from_pr_title() {
  if [ "$1" = "--epic-name" ]; then
    local _tmp_epic_name_="$2" _tmp_="$4" _tmp2_
    shift 2
  else
    local _tmp_="$2" _tmp2_
  fi
  
  [ "${_tmp_:0:8}" = "Revert \"" ] && _tmp_="${_tmp_:8}"
  
  if [ -n "$_tmp_epic_name_" ]; then
    local _tmp2_="${#_tmp_epic_name_}"; ((_tmp2_++))
    [ "${_tmp_:0:$_tmp2_}" = "$_tmp_epic_name_/" ] && _tmp_="${_tmp_:$_tmp2_}"
  fi
  
  IFS=' ' read -r _tmp_ _tmp2_ <<<"$_tmp_"
  _tmp_="${_tmp_/:/}"
  IFS='/' read -r _tmp_ _tmp2_ <<<"$_tmp_"
  _set_var "$1" "${_tmp1_:-$_tmp_}"
}


# Sets a variable on a template string
# The variable placeholder should respect one of these form:
# - Form #1: {var}
# - Form #2: {/var}
#
# Params:
# $1  the destination var
# $2  the var name
# $3  the var value
# $.. params $2,$3 repeated at will
#
_tpl_set_var() {
  local _var_="$1"; shift
  local _tmp_="$1"; shift

  while true; do
    K=$1
    [ -z "$K" ] && break
    shift; V=$1; shift
    _tmp_="${_tmp_//\{${K}\}/${V}}"
    _tmp_="${_tmp_//\{\/${K}\}/\/${V}}"
  done
  _set_var "$_var_" "$_tmp_"
}

# Adds a token or replaces a tocken to/in a URL
#
# Params:
# $1  destination var
# $2  url
# $3  token
#
_url_add_token() {
  local _tmp_="$2"
  local token="$3"
  if [ -n "$token" ]; then
    _tmp_="${_tmp_/:\/\/*@/:\/\/}"
    _tmp_="${_tmp_/:\/\//:\/\/$token@}"
  fi
  _set_var "$1" "$_tmp_"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ITMLST

# Fills a itmlst (list of items) with the given list of entrie
#
# Note that a itmlst is defined as:
# - Comma-delimitest list started amd terminated bu a comma (eg: ",red,blue,")
#
# Params:
# $1  the label list
# $.. the entries to add
#
_itmlst_fill() {
  local _var_name_="$1"; shift
  local _tmp_
  for _tmp_L_ in "$@"; do
    _tmp_+=",$_tmp_L_"
  done
  _set_var "$_var_name_" "${_tmp_:1}"
}

# Checks if a given entry is present in a itmlst (list of items)
#
# @see _itmlst_fill for the definition of "lsblsst"
#
# Params:
# $1 the label list
# $2 the entry
#
_itmlst_contains() {
  local _il_tmp_
  _str_last_pos _il_tmp_ "$1" "$2"
  [ "$_il_tmp_" != -1 ]
}

# Checks if a given entry enabled in itmlst, which means:
# - it's contained
# - its negative (prefixed with a minus) is not contained
#
# Params:
# $1 the label list
# $2 the entry
#
# Options:
# [-W] consider the "*" as a wildcard matching for every item
#
_itmlst_is_item_enabled() {
  local _il_tmpP_ _il_tmpN_ _il_tmpPa_ _il_tmpNa_

  _str_last_pos _il_tmpPa_ "$1" "*"
  _str_last_pos _il_tmpNa_ "$1" "-*"
  _str_last_pos _il_tmpP_ "$1" "$2"
  _str_last_pos _il_tmpN_ "$1" "-$2"

  [ "$_il_tmpPa_" -gt "$_il_tmpP_" ] && _il_tmpP_="$_il_tmpPa_"
  [ "$_il_tmpNa_" -gt "$_il_tmpN_" ] && _il_tmpN_="$_il_tmpNa_"

  [ "$_il_tmpP_" -gt "$_il_tmpN_" ]
}

# Checks if a given itmlst is empty
#
# @see _itmlst_fill for the definition of "lsblsst"
#
# Params:
# $1 the label list
#
_itmlst_empty() {
  [ "$EXECUTION_LABELS" = "," ] || [ "$EXECUTION_LABELS" = "" ]
}

# Generates an itemlist from a list string
#
# Params:
# $1 the receiver of the itmlst
# $2 the source list string
#
# Supports the following separators:
# - ","
# - "|"
# - <LINEFEED>
#
_itmlst_from_string() {
  local _tmp_="$2"
  _tmp_="${_tmp_//$'\n'/,}"
  _tmp_="${_tmp_//$'|'/,}"
  _set_var "$1" "$_tmp_"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ARGS_FLAGS=()
ARGS_POS=("")
declare -A ARGS_OPT

# Program Arguments Parser
# 
# Parses argumets array for positional and optional arguments
# and sends the result to ARGS_POS (array) and ARGS_OPT (map)
#
# Node:
# - ARGS_FLAGS indicates "PARSE_ARGS" which optional arguments should be considered booleans with no explicit value
# 
# See also:
# - _get_arg
# - test_args
#
PARSE_ARGS() {
  QUIET=false; [ "$1" == "-q" ] && { QUIET=true; shift; }
  local K
  local eoo=false

  ARGS_POS=("")
  ARGS_POS_SHIFT=0
  unset ARGS_OPT
  declare -A -g ARGS_OPT

  for K in "${ARGS_FLAGS[@]}";do
    ARGS_OPT["$K"]=false
  done
  
  while [[ $# -gt 0 ]]; do
    K="$1"

    if ! $eoo; then
      case "$K" in
        --)
          eoo=true
          shift
          continue
          ;;
        --*|-*)
          shift
          #~ FLAGS..
          if [[ " ${ARGS_FLAGS[*]} " == *" ${K} "* ]]; then
            #.. NORMAL FLAG
            ARGS_OPT["$K"]=true
            continue
          fi          
          if [[ " --no-${ARGS_FLAGS[*]} " == *" --no-${K} "* ]]; then
            #.. FLAGS NEGATION
            ARGS_OPT["$K"]=false
            continue
          fi

          #~ ASSIGNMENTS..
          #~ .. --OPT=A-VAL
          IFS='=' read -r KK VV <<< "$K"
          if [[ -n "$VV" ]]; then
            ARGS_OPT["$KK"]="$VV"
            continue
          fi
          #~ .. --OPT --NOT-A-VAL
          if [[ "${1:0:1}" = "-" && "${1:0:2}" != "-" ]]; then
            ! $QUIET && _log_w "Detected undeclared flag \"$1\""
            shift
            continue
          fi
          #~ .. --OPT A-VAL
          ARGS_OPT["$K"]="$1"
          shift
          continue
          ;;
      esac
    fi
    
    ARGS_POS+=("$1")
    shift
  done
}

# Extracts a positional or optional argument from the arguments passed to "PARSE_ARGS"
#
# Params:
# $1 the receiver var
# $2 the option name or the positional index
# $3 the fallback value
#
# Options:
# [-m] if specified the function fails if no value can be extracted from argument or fallback
# [-p] if specified the receiver var is not affected if no value can be extracted from argument or fallback
# [-e] if specified the receiver var is also exported
#
# Examples:
# _get_arg arg1 1         # sets the var "arg1" with the first positional argument
# _get_arg mode --mode    # sets the var "mode" with optional argument "--mode"
#
_get_arg() {
  local MANDATORY=false;[ "$1" = "-m" ] && { MANDATORY=true; shift; }
  local PRESERVE=false;[ "$1" = "-p" ] && { PRESERVE=true; shift; }
  local EXPORT=false;[ "$1" = "-e" ] && { EXPORT=true; shift; }
  local _tmp_
  case "$2" in
    ''|*[!0-9]*) _tmp_="${ARGS_OPT[$2]}";;
    *) _tmp_="${ARGS_POS[$((ARGS_POS_SHIFT+$2))]}";;
  esac
  _tmp_="${_tmp_:-$3}"
  [ -n "${_tmp_}" ] || { "$MANDATORY" && _FATAL "No value or fallback available for mandatory param \"$2\" ($1)" ; }
  $PRESERVE && [ -z "${_tmp_:-$3}" ] && return 1
  _set_var "$1" "$_tmp_"
  [ -z "${_tmp_:-$3}" ] && return 1
  # shellcheck disable=SC2163
  $EXPORT && export "$1"
  return 0
}

# Shifts left the positional arguments of the given number of positions (equivalent of bash "shift")
# 
_shift_positional_args() {
  ((ARGS_POS_SHIFT+=$1))
}


# Returns the position of the last occurrent of string in a comma separed list
#
_str_last_pos() { 
  local _slp_tmp1_ _slp_tmp2_="$2" _slp_tmp3_=0 _slp_tmp4_=-1
  while IFS= read -r _slp_tmp1_; do
    if [ "$_slp_tmp1_" = "$3" ]; then
      _slp_tmp4_="$_slp_tmp3_"
    fi
    ((_slp_tmp3_++))
  done <<<"${_slp_tmp2_//,/$'\n'}"  
  _set_var "$1" "$_slp_tmp4_"
}

# prints a quoted version of the give value
#
_str_quote() {
  local _sq_simple_=false;[ "$1" = "-s" ] && { _sq_simple_=true; shift; }
  local tmp="$1"
  tmp="${tmp//\\/\\\\}"
  tmp="${tmp//\"/\\\"}"
  tmp="${tmp//$'\n'/"\$'\\n'"}"
  if $_sq_simple_; then
    echo "$tmp"
  else
    echo "\"$tmp\""
  fi
}

# prints an escaped string given the a source string and the char to escape
#
_str_escape_char() {
  echo "${1//$2/\\$2}"
}

# Decodes an environment variable encoded with a triple-hash prefix to evade the censoring
#
_decode_entando_opt() {
  local _deo_var_value="${!1}"
  if [ "${_deo_var_value:0:4}" = '###'$'\n' ]; then
    _deo_var_value="${_deo_var_value:4}"
  elif [ "${_deo_var_value:0:3}" = '###' ]; then
    _deo_var_value="${_deo_var_value:3}"
  else
    return 0
  fi
  _set_var "$1" "$_deo_var_value"
}


# Resolve an environment variable by interpreting the standard bash dereferencing syntax
# the capability is intentionally limited and supports these syntaxes:
#
# - VAR="$REFVAR" 
# - VAR="${REFVAR}"
#
# And these forms:
#
# - VAR="$REFVAR something else"
# - VAR="${REFVAR} something else"
#
# But other forms with more than dereferences or the dereference in other positions
# Also note that the dereference can be escaped with the backslash
#
_resolve_entando_opt() {
  local FIN=false;[ "$1" == "--finalize" ] && { FIN=true; shift; }
  
  local _reo_var_name="${!1}" _reo_rest=""
  
  if [[ "${_reo_var_name:0:2}" = '\$' ]]; then
    # NOT A REF
    if $FIN; then
      _set_var "$1" "${_reo_var_name:1}"
    else
      _set_var "$1" "${_reo_var_name}"
    fi
    return 0
  fi
  
  # shellcheck disable=SC2016
  if [[ "$_reo_var_name" =~ ^\$\{([a-zA-Z_][a-zA-Z0-9_]*)\}(.*)$ ]]; then
    # A REF
    _reo_var_name="${BASH_REMATCH[1]}"
    _reo_rest="${BASH_REMATCH[2]}"
  elif [[ "$_reo_var_name" =~ ^\$([a-zA-Z_][a-zA-Z0-9_]*)(.*)$ ]]; then
    # A REF
    _reo_var_name="${BASH_REMATCH[1]}"
    _reo_rest="${BASH_REMATCH[2]}"
  else
    # NOT A REF
    _set_var "$1" "${_reo_var_name}"
    return 0
  fi
  
  _is_valid_var_name "$_reo_var_name" || _FATAL "Invalid reference \"$_reo_var_name\""
  _set_var "$1" "${!_reo_var_name}${_reo_rest}"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Successfully changes dir or fatals
#
__cd() {
  local L="$1"
  [ "${L:0:7}" = "file://" ] && L="${L:7}"
  [ -z "$L" ] && _FATAL "Null directory provided"
  cd "$L" 1>/dev/null || _FATAL -S 2 "Unable to enter directory \"$1\""
  _log_t "Entered directory \"$L\""
}

# File/dir existsor fatals
#
# Params:
# $1  mode (-f: fiile, -d: dir)
# $2  file/dir
#
__exist() {
  local where="";[[ "${2:0:1}" != "/" && "${2:0:1}" != "~" ]] && where=" under directory \"$PWD\""
  case "$1" in
    "-f") [ ! -f "$2" ] && _FATAL "Unable to find the file \"$2\" $where";;
    "-d") [ ! -d "$2" ] && _FATAL "Unable to find the dir \"$2\" $where";;
    *) _FATAL "Invalid mode \"$1\"";;
  esac
  return 0
}

# Executes a jq command
# FATALS on error
# 
__jq() {
  jq "$@" || _FATAL "Error parsing the json input"
}

# Intercept the stdin and instead prints an summary
#
# Params:
# $1    the title of the summary
#
# Options:
# --ppl-pg page-size  activates pagination and specifies the page size
#
_summarize_stream() {
  local PAGE=""; [ "$1" = "--ppl-pg" ] && { PAGE="$2"; shift 2; }
  local _stat_nt=0 _stat_ne=0 _stat_nw=0 _stat_nd=0
  local _stat_pg_ne=0 _stat_pg_nw=0
  local started_at="$SECONDS" 
  local now elapsed
  local sln TITLE="${1:-SUMMARY}"
  local page_title=""
  
  local break_page_now min_page_size=2 _page_nt _prev_page_nt=0 _page_buf="" _error_tail_size=0 error_tail_max_size=20

  while IFS= read -r ln; do
    if [ -z "$PAGE" ]; then
      echo "$ln"
      continue
    fi
    
    _page_buf+="$ln"$'\n'

    sln="${ln:0:30}"
    
    ((_stat_nt++))
    _page_nt="$((_stat_nt - _prev_page_nt))"
    
    if [ "$_page_nt" -lt "$min_page_size" ]; then
      break_page_now=false
    else
      break_page_now=false
    fi
    
    case "${sln,,}" in
      *error*|*severe*) _error_tail_size=1; ((_stat_ne++));((_stat_pg_ne++));;
      *warning*) ((_stat_nw++));((_stat_pg_nw++));;
      *warn*) ((_stat_nw++));((_stat_pg_nw++));;
      *downloaded*) ((_stat_nd++));;
      *) break_page_now=false;;
    esac
    
    if [[ "$_error_tail_size" -gt 0 ]]; then
      [[ "$_error_tail_size" -lt "$error_tail_max_size" ]] &&
      [[ "$_page_nt" -lt "$((PAGE*2))" ]] && {
        ((_error_tail_size++))
        continue   # <= CONTINUE
      }
      _error_tail_size=0
    fi

    if [[ "$_page_nt" -ge "$PAGE" || "$break_page_now" == "true" ]]; then
      now="$SECONDS"
      elapsed="$((now - started_at))"
      printf -v page_title "~ $TITLE > | START: %6d || SEC: %4d | ERR: %5s %-6s | WRN: %5s %-6s | DNL: %6d |" \
        "$((_prev_page_nt+1))" "$elapsed"  \
        "$_stat_ne" "(+$_stat_pg_ne)" \
        "$_stat_nw" "(+$_stat_pg_nw)" \
        "$_stat_nd"

      _ppl-stdout-group start "$page_title"
      echo -n "$_page_buf"
      _ppl-stdout-group stop
      _page_buf=""
      _error_tail_size=0
      _prev_page_nt="$_stat_nt"
      _stat_pg_ne=0;_stat_pg_nw=0
    fi
  done < "/dev/stdin"
  
  if [ -n "$_page_buf" ]; then
      now="$SECONDS"
      elapsed="$((now - started_at))"
      printf -v page_title "~ $TITLE > | START: %6d || SEC: %4d | ERR: %5s %-6s | WRN: %5s %-6s | DNL: %6d |" \
        "$((_prev_page_nt+1))" "$elapsed"  \
        "$_stat_ne" "(+$_stat_pg_ne)" \
        "$_stat_nw" "(+$_stat_pg_nw)" \
        "$_stat_nd"
    _ppl-stdout-group start "$page_title"
    echo -n "$_page_buf"
    _ppl-stdout-group stop
  fi
}

# Puts a stream in a group given the group name
#
_group_stream() {
  _ppl-stdout-group start "$1"
  while IFS= read -r ln; do
    echo "$ln"
  done
  _ppl-stdout-group stop
}


# Executes a command and handle the output
# 
# Params:
# $@ the full command line
# 
# Options
# --ppl-simple    no summarization is executed
# --ppl-timestamp a timestamp is added to the output lines
# --hide regex    suppress the given regex from the output, can be repeated up to 4 times
#
_exec_cmd() {
  local SIMPLE=false; [ "$1" = "--ppl-simple" ] && { SIMPLE=true; shift; }
  local TS=false; [ "$1" = "--ppl-timestamp" ] && { TS=true; shift; }
  local F1=""; [ "$1" = "--hide" ] && { F1="$(_str_quote "$2")"; shift 2; }
  local F2=""; [ "$1" = "--hide" ] && { F2="$(_str_quote "$2")"; shift 2; }
  local F3=""; [ "$1" = "--hide" ] && { F3="$(_str_quote "$2")"; shift 2; }
  local F4=""; [ "$1" = "--hide" ] && { F4="$(_str_quote "$2")"; shift 2; }
  local PO=''; [ "$1" = "--po" ] && { PO="$2"; shift 2; }
  # shellcheck disable=SC2016
  {
    CMD='while (<STDIN>) {'$'\n'
    [ -n "$F1" ] && CMD+='  if (index($_, '"$F1"') != -1) { next; }'$'\n'
    [ -n "$F2" ] && CMD+='  if (index($_, '"$F2"') != -1) { next; }'$'\n'
    [ -n "$F3" ] && CMD+='  if (index($_, '"$F3"') != -1) { next; }'$'\n'
    [ -n "$F4" ] && CMD+='  if (index($_, '"$F4"') != -1) { next; }'$'\n'
    if $TS; then
      CMD+='  my ($S,$M,$H,$d,$m,$y,$wd,$yd,$id)=localtime(time);'$'\n';
      CMD+='  my $TS = sprintf ( "%04d-%02d-%02d_%02d:%02d:%02d", $y+1900, $m+1,$d,$H,$M,$S);'$'\n';
      CMD+='  print($TS . " | " . $_);'$'\n'
    else
      CMD+='  print($_);'$'\n'
    fi
    CMD+='}'$'\n'
  }
  
  echo "$CMD"  > /tmp/t
  
  (
    local RVFILE="$(mktemp)"
    if "$SIMPLE"; then
      # shellcheck disable=SC2064
      trap "rm \"$RVFILE\"" exit
      (
        _unset_all_entano_options
        # shellcheck disable=SC2068
        $@ 2>&1
        echo "$?" > "$RVFILE"
      ) | perl -e "$CMD"
    else
      if [ -n "$PO" ]; then
        local TMPFILE="$PO"
        # shellcheck disable=SC2064
        trap "rm \"$RVFILE\"" exit
      else
        local TMPFILE="$(mktemp)"
        # shellcheck disable=SC2064
        trap "rm \"$TMPFILE\" \"$RVFILE\"" exit
      fi
      
      _summarize_stream ${PE:+"$PE"} --ppl-pg 50 "$1" < <(
        (
          _unset_all_entano_options
          # shellcheck disable=SC2068
          $@ 2>&1
          echo "$?" > "$RVFILE"
        ) | perl -e "$CMD"
      )
    fi

    local RV="$(cat "$RVFILE")"
    if [ "$RV" = "0" ]; then
      _log_d "$1 execution was successful"
    else
      _log_e "Command \"$1\" completed with error code \"$RV\""
    fi
    _exit "$RV"
  )
}

# Determines the name of the release branch for the given reference version
#
# Params:
# $1: the receiver var of the designated release branch
# $2: the reference version
#
# The business rule is simple:
# - Versions X.Y.Z are released under the branch "release/X.Y.0"
#
_ppl_determine_release_branch() {
  local _referenceVersion_="$2"
  local _releaseBranch_
  _semver_parse maj min ptc "" "$_referenceVersion_"
  # shellcheck disable=SC2154
  _releaseBranch_="release/$maj.$min.0"
  _set_var "$1" "$_releaseBranch_"
}

__ppl_enter_local_clone_dir() {
  [ -n "$PPL_LOCAL_CLONE_DIR" ] && __cd "$PPL_LOCAL_CLONE_DIR"
  true
}

# Determines the action related to a feature
#
# Params:
# $1 output var for the result
# $2 feature name
# $3 fallback value
#
# Rules:
# - Features are in the format of labels
# - Features are also read from the ENTANDO_OPT_FEATURES, expect for SKIP directives
# - Features are also read from the ENTANDO_OPT_GLOBAL_FEATURES, expect for SKIP directives
# - Features will be converted into CI vars usable in CI conditions
# - SKIP directive are like DISABLE directives but they are removed once evaluated
#
# Directives Formats:
# - Enable a feature: +{FEATURE}
# - Disable a feature: -{FEATURE}
# - Disable a feature once: SKIP-{FEATURE}
#
# Directives Priority crieria:
# 1. LABEL then ENTANDO_OPT_FEATURES then ENTANDO_OPT_GLOBAL_FEATURES
# 2. LAST directive of a given feature overwrites the previous directives of the same feature
# 3. Above crieria #1 wins over crieria #2
# 
# Returns a result of this structure:
# - {main-result}.{detail}
# 
# where {main-result} can be:
# - D => disabled
# - E => enabled
# - I => illegal
#
# and {detail} can be:
# - var => result source is ENTANDO_OPT_FEATURES or ENTANDO_OPT_GLOBAL_FEATURES
# - label => result source is a label
# - any other arbitrary text => non-functional text providing details
#
_ppl_get_feature_action() {
  local _tmp_feature="$2" _tmp_action
  
  case "$3" in
    "true") _tmp_action="E.fallback";;
    "false") _tmp_action="D.fallback";;
  esac

  # shellcheck disable=SC2154
  {
    _itmlst_contains "$PPL_FEATURES" "$_tmp_feature" && _tmp_action="E.var"
    _itmlst_contains "$PPL_FEATURES" "+$_tmp_feature" && _tmp_action="E.var"
    _itmlst_contains "$PPL_FEATURES" "ENABLE-$_tmp_feature" && _tmp_action="E.var"
    _itmlst_contains "$PPL_FEATURES" "-$_tmp_feature" && _tmp_action="D.var"
    _itmlst_contains "$PPL_FEATURES" "DISABLE-$_tmp_feature" && _tmp_action="D.var"
    _itmlst_contains "$PPL_FEATURES" "SKIP-$_tmp_feature" && _tmp_action="I.skip-in-var"
  }
  _ppl-pr-has-label "+$_tmp_feature" && _tmp_action="E.label"
  _ppl-pr-has-label "-$_tmp_feature" && _tmp_action="D.label"
  _ppl-pr-has-label "SKIP-$_tmp_feature" && _tmp_action="S.label"
  
  _set_var "$1" "$_tmp_action"
}

# Returns the status of a feature
#
# Params:
# $1 feature name
# $2 fallback value
#
# [$? == 0] => directive is present
# [$? != 0] => directive is not present
#
_ppl_is_feature_enabled() {
  local ACTION
  _ppl_get_feature_action ACTION "$1" "$2"
  
  case "$ACTION" in
    E*) return 0;;
    D*) return 1;;
    S*) return 2;;
    I*)
      _log_w "Skip directives (SKIP-$1) are not allowed in "
              "\"ENTANDO_OPT_FEATURES\" or \"ENTANDO_OPT_GLOBAL_FEATURES\" => ignored"
      [ "$2" == "true" ] && return 0
      return 9
      ;;
    "") return 3;;
  esac
}

# Checks the action status of a feature
#
# Params:
# $1 feature name
# $2 action status
#    S: skipped
#    E: enabled
#    D: disabled
#    I: illegal feature specification
#
# [$? == 0] => directive is present
# [$? != 0] => directive is not present
#
_ppl_is_feature_action() {
  local ACTION
  _ppl_get_feature_action ACTION "$1" ""
  
  if [[ "$ACTION" = "${2}"* ]]; then
    return 0
  else
    return 1
  fi
}



# Extracts a part of the snapshot version number
#
# Params:
#
# $1  output var
# $2  snapshot version number
# $3  part: 
#     - base-version        the initial 3digit version with or without prefix (eg: v7.0.0 or 7.0.0)
#     - qualifier           usually a ticket number (eg: ENT-999)
#     - pr-num              pull request number
#     - meta:kb             current branch of event that generated the tag
#     - meta:bb             bash branch branch of event that generated the tag
#     - effective-number    the effective part of the version (all the version but with no metadata)
#
_ppl_extract_version_part() {
  local _tmp1_ _tmp2_ _tmp2a_ _tmp3_ _tmp4_ _tmp5_ _tmp_res_
  local _tmpV_ _tmpM_
  _ppl_split_version_tag _tmpV_ _tmpM_ "$2"
  if [[ "$2" == *"-fix."* ]]; then
    # shellcheck disable=SC2034
    IFS='-' read -r _tmp1_ _tmp2a_ _tmp2_ _tmp3_ _tmp4_ _tmp5_ <<< "$_tmpV_"
  else
    # shellcheck disable=SC2034
    IFS='-' read -r _tmp1_ _tmp2_ _tmp3_ _tmp4_ _tmp5_<<< "$_tmpV_"
  fi
  case "$3" in
    "base-version") 
      _tmp_res_="$_tmp1_"
      [[ "${_tmp_res_:0:1}" = "v" ]] && _tmp_res_="${_tmp_res_:1}"
      ;;
    "qualifier") _tmp_res_="$_tmp2_-$_tmp3_";;
    "pr-num") _tmp_res_="$_tmp5_";;
    "meta:kb"|"meta:bb")
      if [[ "${_tmpM_:0:3}" =~ ^..- ]]; then
        _tmp_res_="${_tmpM_:3}"
        _tmp_res_="${_tmp_res_//++/+}"
        _tmp_res_="${_tmp_res_//+2F+/\/}"
      else
        _tmp_res_=""
      fi
      ;;
    "effective-number")
      _tmp_res_="$_tmpV_"
      [[ "${_tmp_res_:0:1}" = "v" ]] && _tmp_res_="${_tmp_res_:1}"
      ;;
    *) _FATAL "Invalid part name \"$3\" provided";;
  esac
  #[[ -z "$_tmp_res_" || "$_tmp4_" != "PR" ]] && _FATAL "Provided snapshot version \"$2\" is not valid"
  _set_var "$1" "$_tmp_res_"
}

_ppl_validate_command_version() {
  local DESC="$1"; REQ_VER="$2" shift
  local VER
  
  VER=$(eval "$3")
  
  if [ $? -ne 0 ] || [ -z "$VER" ]; then
    _FATAL "Command \"$DESC\" is not available"
  fi
  
  local maj min
  _semver_parse maj min "" "" "$VER"
  
  REQ_VER="${REQ_VER//x/}"
  
  [[ "${maj}.${min}." =~ $REQ_VER. ]] || _FATAL "Command \"$DESC\" has invalid version ($VER)"
}

# Creates a temporary directory that self destructs
#
# Options:
# --and-enter:  after creating the area, enters it
#
# Params:
# $1: optional variable that receives the area full-path
#
__mk_tmp_work_area() {
  local _tmp_tmpdir_="$(mktemp -d)"
  if [ "${_tmp_tmpdir_:0:1}" != "/" ]; then
    _FATAL "Error creating the temporary working area"
  else
    echo ".tmp-work-area" > "$_tmp_tmpdir_/.tmp-work-area"
    # shellcheck disable=SC2064
    trap "[ -f \"$_tmp_tmpdir_/.tmp-work-area\" ] && rm -rf \"$_tmp_tmpdir_\"" exit
    [ "$1" = "--and-enter" ] && { __cd "$_tmp_tmpdir_"; shift; }
    [ -n "$1" ] && _set_var "$1" "$_tmp_tmpdir_"
  fi
}

# Prints a colorized banner given its text
#
_print_banner() {
  (
    H() { echo -e '\033[44m\033[1;37m' ; }
    E() { echo -e '\033[0;39m'; }
    local txt="$1"
    local SEP="~~~~~~~~~~"
    SEP="$SEP$SEP$SEP$SEP$SEP$SEP$SEP$SEP$SEP$SEP"
    SEP=${SEP:0:${#txt}}
    echo "$(H)▒ $SEP ▒$(E)"
    echo -e "$(H)▒ $txt ▒$(E)"
    echo "$(H)▒ $SEP ▒$(E)"
    echo ""
  )
}

# Let the use pick an item out of the given list of items
#
# Params:
# $1: prompt 
# $2  bash array containing the items
#
select_one() {
  local i=1
  local SELECTED=""
  local ALL=false
  local AUTO_SET_IF_SINGLE=false
  [ "$1" = "-s" ] && AUTO_SET_IF_SINGLE=true && shift
  [ "$1" = "-a" ] && ALL=true && shift
  P="$1"
  shift
  select_one_res=""
  select_one_res_alt=""

  if $AUTO_SET_IF_SINGLE && [ "$#" -eq 1 ]; then
    select_one_res="1"
    select_one_res_alt="$1"
    return 0
  fi

  for item in "$@"; do
    echo "$i) $item"
    i=$((i + 1))
  done
  ${ALL:-false} && echo "a) all"
  echo "q) to quit"

  while true; do
    printf "%s" "$P"
    set_or_ask "SELECTED" "" ""
    [[ "$SELECTED" == "q" ]] && EXIT_UE "User interrupted"
    [[ ! "$SELECTED" =~ ^[0-9]+$ ]] && continue
    [[ "$SELECTED" -gt 0 && "$SELECTED" -lt "$i" ]] && break
    [[ "$SELECTED" -gt 0 && "$SELECTED" -lt "$i" ]] && break
  done

  # shellcheck disable=SC2034
  {
    select_one_res="$SELECTED"
    select_one_res_alt="${!SELECTED}"
  }
}

# Convers stdin to bash array or list
#
# Params:
# $1:   separator, ' ' for arrays
# $2:   destinationvar
#
# Example:
#   stdin_to_arr ' ' AN_ARRAY < <(ls)
#
stdin_to_arr() {
  local i=0
  local arr
  IFS="$1" read -d '' -r -a arr
  for line in "${arr[@]}"; do
    _set_var "$2[$i]" "$line"
    ((i++))
  done
}

# Extracts from a full git ref the actual branch name even if it contains slashes
# 
_ppl_extract_branch_name_from_ref() {
  # shellcheck disable=SC2034
  {
    local _tmp_ _tmp_ignore_

    case "$2" in
      refs/heads/*|refs/tags/*)
        IFS='/' read -r _tmp_ignore_ _tmp_ignore_ _tmp_ <<< "$2";;
      refs/pull/*) _tmp="";;
      *) _tmp="";;
    esac
    
    _set_var "$1" "$_tmp_"
  }
  
  return 0
}

# Determine the current branch short name (the part after the first "/")
# It's usuful as discriminant for identifiers related to a long running branch.
# 
# Params:
# $1  the result receiver var
# $2  the branch name
# 
# Examples:
# - "develop" => ""
# - "epic/mylongrunningbranch" => "mylongrunningbranch"
# - "epic/my-long-running-branch" => "my-long-running-branch"
#
_ppl_extract_branch_short_name() {
  local _tmp1_ _tmp2_
  IFS='/' read -r _tmp1_ _tmp2_ <<<"$2"
  _set_var "$1" "$_tmp2_"
}

# Tells if a version number is a release
#
_ppl_is_release_version_number() {
  _semver_parse _maj_ _min_ _ptc_ _tag_ "$1"
  # shellcheck disable=SC2154
  [[ -z "$_tag_" ]] || [[ "${_tag_:0:4}" == "fix." && ! "$_tag_" = *"-"* ]]
}

# Extracts from the version tag the version and the original reference branch
#
# Params:
# $1  the version receiver
# $2  the metadata receiver
# $3  the full-version
#
_ppl_split_version_tag() {
  local _tmp1_ strip_pre=false; [ "$1" = "--strip-prefix" ] && { strip_pre=true; shift; }
  IFS='+' read -r _tmp1_ _tmp2_ <<< "$3"
  [ -n "$1" ] && {
    if $strip_pre; then
      _set_var "$1" "${_tmp1_:1}"
    else
      _set_var "$1" "$_tmp1_"
    fi
  }
  [ -n "$2" ] && {
    _set_var "$2" "$_tmp2_"
  }
}

# Encodes a branch name for tagging
# 
# > adds the segment-tag "KB-" 
# > encodes any forward slash to "+2F+"
# > encodes the escape char "+" to "++"
#
_ppl_encode-branch-for-tagging() {
  local tmp="${2//+/++}"
  echo "$1-${tmp//\//+2F+}"
}

# Concatenates two or more path parts
#
# Note that the function tries to preserve local paths, so:
# - path-concat "" "b"
# generates:
# - "b"
#
# For further info check `test_path_functions`
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# $1: destination var name 
# $2: the source value #1 
# $3: the source value #2
#
path-concat() {
  local ACC="$1"; shift
  while true; do
    local terminated=false
    [[ "$ACC" = "-t" ]] && terminated=true && shift
    local NEXT="$1"
    shift
    
    if [[ -n "$ACC" ]]; then
      [[ "$ACC" =~ ^.*/$ ]] && {
        ACC_len="${#ACC}"
        ACC="${ACC::$ACC_len-1}"
      }
      [[ -n "$NEXT" ]] && [[ "$NEXT" =~ ^/.*$ ]] && NEXT="${NEXT:1}"
      ACC="${ACC}/${NEXT}"
    else
      ACC="${NEXT}"
    fi
    
    if $terminated; then
      [[ ! "$ACC" =~ ^.*/$ ]] && ACC+="/"
    fi
    [ "$#" = 0 ] && break
  done
  echo "$ACC"
}

sys_trace_ctl() {
  case "$1" in
    enable)
      #export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
      export PS4='\033[0;33m+[${SECONDS}][${BASH_SOURCE}:${LINENO}]:\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
      set -x
      ;;
    disable)
      set +x
      export PS4='+'
      ;;
  esac
}
