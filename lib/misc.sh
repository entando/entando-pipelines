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
  if [[ "$1" = *",$2,"* ]]; then
    return 0
  else
    return 1
  fi
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

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SEMVER


# Parses a semver into its complonent digits
# - "v" prefix is suppored and stripped
# - all params are optional and accept ""
#
# Params:
# $1  major version receiver var
# $2  minor version receiver var
# $3  patch version receiver var
# $4  update version receiver var
# $5  semver to parse
#
_semver_parse() {
  local _tmpV_ _tmpT_ _tmp1_ _tmp2_ _tmp3_

  IFS='-' read -r _tmpV_ _tmpT_ <<< "$5"
  IFS='.' read -r _tmp1_ _tmp2_ _tmp3_ <<< "$_tmpV_"
  [ "${_tmp1_:0:1}" = "v" ] && _tmp1_="${_tmp1_:1}"
  [ "${_tmp1_:0:1}" = "p" ] && _tmp1_="${_tmp1_:1}"
  [ -n "$1" ] && _set_var "$1" "$_tmp1_"
  [ -n "$2" ] && _set_var "$2" "$_tmp2_"
  [ -n "$3" ] && _set_var "$3" "$_tmp3_"
  [ -n "$4" ] && _set_var "$4" "$_tmpT_"
  
  true
}

# increments a semver
#
# Params:
# $1  receiver var
# $2  base semver
# $3  major increment
# $4  minor increment
# $5  patch increment
#
_semver_add() {
  local _maj_ _min_ _ptc_ _tag_
  _semver_parse _maj_ _min_ _ptc_ _tag_ "$2"
  _set_var "$1" "$((_maj_+$3)).$((_min_+$4)).$((_ptc_+$5))${_tag_:+-$_tag_}"
}

# Updates or add a tag to a version string
#
# Params:
# $1 the destination var
# $2 the source version
# $3 the new tag to set
#
_semver_set_tag() {
  if [[ "$2" = *"-"* ]]; then
    _set_var "$1" "${2//-*/-$3}"
  else
    _set_var "$1" "$2-$3"
  fi
}


# Compares 2 sem version and return
# - 1 if the first is > than the second
# - 0 if they are equals
# - -1 if the first is < than the second
#
# Params:
# $1 destination var
# $2 the first var
# $3 the second version
#
_semver_cmp() {

  _semver_parse _maj1_ _min1_ _ptc1_ "" "$2"
  _semver_parse _maj2_ _min2_ _ptc2_ "" "$3"

  [ "${_maj1_:-0}" -gt "${_maj2_:-0}" ] && { _set_var "$1" 1; return; }
  [ "${_maj1_:-0}" -lt "${_maj2_:-0}" ] && { _set_var "$1" -1; return; }
  [ "${_min1_:-0}" -gt "${_min2_:-0}" ] && { _set_var "$1" 1; return; }
  [ "${_min1_:-0}" -lt "${_min2_:-0}" ] && { _set_var "$1" -1; return; }
  [ "${_ptc1_:-0}" -gt "${_ptc2_:-0}" ] && { _set_var "$1" 1; return; }
  [ "${_ptc1_:-0}" -lt "${_ptc2_:-0}" ] && { _set_var "$1" -1; return; }
  _set_var "$1" 0
}

# Successfully changes dir or fatals
#
__cd() {
  local L="$1"
  [ "${L:0:7}" = "file://" ] && L="${L:7}"
  [ -z "$L" ] && _FATAL "Null directory provided"
  cd "$L" 1>/dev/null || _FATAL "Unable to enter directory $1"
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
    "-f") [ ! -f "$2" ] && _FATAL "Unable to find the file \"$2\"";;
    "-d") [ ! -d "$2" ] && _FATAL "Unable to find the dir \"$2\"";;
    *) _FATAL "Invalid mode \"$1\"";;
  esac
}

# Executes a jq command
# FATALS on error
# 
__jq() {
  jq "$@" || _FATAL "Error parsing the json input"
}
