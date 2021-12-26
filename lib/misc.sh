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
          if [[ " ${ARGS_FLAGS[*]} " == *" ${K} "* ]]; then
            ARGS_OPT["$K"]=true
            shift
          else
            if [[ "${2:0:1}" = "-" && "${2:0:2}" != "-" ]]; then
              ! $QUIET && _log_w "Detected undeclared flag \"$1\""
              shift
            else
              ARGS_OPT["$K"]="$2"
              shift;shift
            fi
          fi
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
# [-m] is specified the function fails if no value can be extracted from argument or fallback
#
# Examples:
# _get_arg arg1 1         # sets the var "arg1" with the first positional argument
# _get_arg mode --mode    # sets the var "mode" with optional argument "--mode"
#
_get_arg() {
  local MANDATORY=false;[ "$1" = "-m" ] && { MANDATORY=true; shift; }
  local _tmp_
  case "$2" in
    ''|*[!0-9]*) _tmp_="${ARGS_OPT[$2]}";;
    *) _tmp_="${ARGS_POS[$((ARGS_POS_SHIFT+$2))]}";;
  esac
  _tmp_="${_tmp_:-$3}"
  [ -n "${_tmp_}" ] || { "$MANDATORY" && _FATAL "No value or fallback available for mandatory param \"$2\" ($1)" ; }
  _set_var "$1" "$_tmp_"
  [ -z "${_tmp_:-$3}" ] && return 1
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

# Decodes an ENTANDO_OPT variable encoded with a triple-hash prefix to evade the censoring
#
# Params:
# $@ a list of vars to decode
#
_decode_entando_opt() {
  for _deo_var_name in "$@"; do
    local _deo_var_value="${!_deo_var_name}"
    if [ "${_deo_var_value:0:4}" = '###'$'\n' ]; then
      _deo_var_value="${_deo_var_value:4}"
    elif [ "${_deo_var_value:0:3}" = '###' ]; then
      _deo_var_value="${_deo_var_value:3}"
    else
      continue
    fi
    _set_var "$_deo_var_name" "$_deo_var_value"
  done
}

# Scans the environment for ENTANDO_OPT_XXX variables and decodes them
# See also _decode_entando_opt
#
_auto_decode_entando_opts() {
  for varname in ${!ENTANDO_OPT*}; do
    _decode_entando_opt "$varname"
  done
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Successfully changes dir or fatals
#
__cd() {
  local L="$1"
  [ "${L:0:7}" = "file://" ] && L="${L:7}"
  [ -z "$L" ] && _FATAL "Null directory provided"
  cd "$L" 1>/dev/null || _FATAL -S 1 "Unable to enter directory \"$1\""
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
# --lf      uses LF instead of CR when terminating the summmary
# --no-tlf  the latest summary update will not be terminated by line-feedd
# --li      number of lines before updating the summary (default: 73)
# --ti      number of seconds before updating the summary (default: 5)
# --pe      immediately prints errors to stdout
# -f file   adds the command output to the given file
#
_summarize_stream() {
  local EOL=$'\r'; [ "$1" = "--lf" ] && { EOL=$'\n'; shift; }
  local TLF=$'\n'; [ "$1" = "--no-tlf" ] && { TLF=''; shift; }
  local LI=73; [ "$1" = "--li" ] && { LI="$2"; shift 2; }
  local TI=5; [ "$1" = "--ti" ] && { TI="$2"; shift 2; }
  local PE=false; [ "$1" = "--pe" ] && { PE=true; shift; }
  local OUTFILE; [ "$1" = "-f" ] && { OUTFILE="$2"; shift 2; }
  local _stat_nt=0 _stat_ne=0 _stat_nw=0 _stat_nd=0 _last_nt=-1000
  local started_at="$SECONDS" 
  local latest="$((started_at-100))" now elapsed
  local sln TITLE="${1:-SUMMARY}"
  local showNext=0
  
  while IFS= read -r ln; do
    [ -n "$OUTFILE" ] && echo "$ln" >> "$OUTFILE"
    
    sln="${ln:0:20}"
    
    ((_stat_nt++))
    
    case "${sln,,}" in
      *error*) 
        ((_stat_ne++))
        "$PE" && {
          echo "$ln"
          showNext=2
        }
      ;;
      *warning*) ((_stat_nw++));;
      *warn*) ((_stat_nw++));;
      *downloaded*) ((_stat_nd++));;
      *)
        if [ "$showNext" -gt 0 ]; then
          echo "$ln" | grep -E '^\s+at\s'
        fi
    esac

    [ "$showNext" -gt 0 ] && ((showNext--))

    if [ $((_stat_nt - _last_nt)) -ge "$LI" ]; then
      now="$SECONDS"
      if [ "$((now-latest))" -ge "$TI" ]; then
        latest="$now"
        _last_nt="$_stat_nt"
        elapsed="$((now-started_at))"
        printf "~ $TITLE > | SEC: %4d | TOT: %6d  | ERR: %6d | WRN: %6d | DNL: %6d |       %s" \
          "$elapsed" "$_stat_nt" "$_stat_ne" "$_stat_nw" "$_stat_nd" "$EOL"
      fi
    fi
  done < "/dev/stdin"
  
  now="$SECONDS"
  elapsed="$((now-started_at))"
  printf "~ $TITLE > | SEC: %4d | TOT: %6d  | ERR: %6d | WRN: %6d | DNL: %6d |       %s" \
    "$elapsed" "$_stat_nt" "$_stat_ne" "$_stat_nw" "$_stat_nd" "$TLF"
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
# --pe            see _summarize_stream
#
_exec_cmd() {
  local SIMPLE=false; [ "$1" = "--ppl-simple" ] && { SIMPLE=true; shift; }
  local TS=false; [ "$1" = "--ppl-timestamp" ] && { TS=true; shift; }
  local F1=""; [ "$1" = "--hide" ] && { F1="$(_str_quote "$2")"; shift 2; }
  local F2=""; [ "$1" = "--hide" ] && { F2="$(_str_quote "$2")"; shift 2; }
  local F3=""; [ "$1" = "--hide" ] && { F3="$(_str_quote "$2")"; shift 2; }
  local F4=""; [ "$1" = "--hide" ] && { F4="$(_str_quote "$2")"; shift 2; }
  local PE=''; [ "$1" = "--pe" ] && { PE="--pe"; shift; }
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
      
      _summarize_stream --lf ${PE:+"$PE"} -f "$TMPFILE" "$1" < <(
        (
          # shellcheck disable=SC2068
          $@ 2>&1
          echo "$?" > "$RVFILE"
        ) | perl -e "$CMD"
      )
    fi

    local RV="$(cat "$RVFILE")"
    if [ "$RV" = "0" ]; then
      # SUCCESS
      
      if $SIMPLE; then
        _log_d "$1 execution was successful"
      else
        _log_t "$1 execution was successful; log tail:"
        # shellcheck disable=SC2088
        echo '~/~~~~~~~/~~~~~~~/~~~~~~~/~~~~~~~/~~~~~~~/~'
        _ppl-print-file-paginated "$TMPFILE" 200 "LOG"
        sleep 0.3
      fi
    else
      # FAILURE
      
      if $SIMPLE; then
        _log_e "Command \"$1\" completed with error code \"$RV\""
      else
        _log_e "Command \"$1\" completed with error code \"$RV\"; full log:"
        # shellcheck disable=SC2088
        echo '~/~~~~~~~/~~~~~~~/~~~~~~~/~~~~~~~/~~~~~~~/~'
        _ppl-print-file-paginated "$TMPFILE" 200 "LOG"
        sleep 0.3
      fi
      
      return "$RV"
    fi
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



# Extracts a part of the snapshot version name
#
# Params:
# $1  output var
# $1  snapshot version name
# $2  part: "base-version" or "qualifier" or "pr-num"
#
_ppl_extract_snapshot_version_name_part() {
  local _tmp1_ _tmp2_ _tmp2a_ _tmp3_ _tmp4_ _tmp5_ _tmp_res_
  if [[ "$2" == *"-fix."* ]]; then
    # shellcheck disable=SC2034
    IFS='-' read -r _tmp1_ _tmp2a_ _tmp2_ _tmp3_ _tmp4_ _tmp5_ <<<"$2"
  else
    IFS='-' read -r _tmp1_ _tmp2_ _tmp3_ _tmp4_ _tmp5_ <<<"$2"
  fi
  case "$3" in
    "base-version") 
      _tmp_res_="$_tmp1_"
      [[ "${_tmp_res_:0:1}" = "v" ]] && _tmp_res_="${_tmp_res_:1}"
      ;;
    "qualifier") _tmp_res_="$_tmp2_-$_tmp3_";;
    "pr-num") _tmp_res_="$_tmp5_";;
    *) _FATAL "Invalid part name \"$3\" provided";;
  esac
  [[ -z "$_tmp_res_" || "$_tmp4_" != "PR" ]] && _FATAL "Provided snapshot version name \"$2\" is not valid"
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

# Determines the type of project in the current dir
#
# Params:
# $1: dest var
#
__ppl_determine_current_project_type() {
  local _tmp_

  if [ -f "pom.xml" ]; then
    _tmp_="MVN"
  elif [ -f "package.json" ]; then
    _tmp_="NPM"
  else
    _FATAL "Unable to determine the project type"
  fi
    
  if [ "$1" == "--print" ]; then
    echo "$_tmp_"
  elif [ "$1" == "--check" ]; then
    true
  else
    _set_var "$1" "$_tmp_"
  fi
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

# Determine the current branch qualified (the part after the first "-")
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
_ppl-determine-branch-qualifier() {
  local _tmp1_ _tmp2_
  IFS='/' read -r _tmp1_ _tmp2_ <<<"$2"
  _set_var "$1" "$_tmp2_"
}

