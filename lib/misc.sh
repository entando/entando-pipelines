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
  _tmp_="${_tmp_//: */}"
  _tmp_="${_tmp_// */}"
  _set_var "$1" "$_tmp_"
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
  _set_var "$_var_name_" "${_tmp_},"
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
# - "\n"
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
            shift 1
          else
            ARGS_OPT["$K"]="$2"
            shift;shift
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
    *) _tmp_="${ARGS_POS[$2]}";;
  esac
  _set_var "$1" "${_tmp_:-$3}"
  [ -n "${_tmp_}" ] || { "$MANDATORY" && _FATAL "Mandatory param  \"$2\" was not provided"; }
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
  local tmp="$1"
  tmp="${tmp//\\/\\\\}"
  tmp="${tmp//\"/\\\"}"
  echo "\"$tmp\""
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
  case "$1" in
    "-f") [ ! -f "$2" ] && _FATAL "Unable to find the file \"$2\" in directory \"$PWD\"";;
    "-d") [ ! -d "$2" ] && _FATAL "Unable to find the dir \"$2\" under dir \"$PWD\"";;
    *) _FATAL "Invalid mode \"$1\"";;
  esac
}

# Executes a jq command
# FATALS on error
# 
__jq() {
  jq "$@" || _FATAL "Error parsing the json input"
}
