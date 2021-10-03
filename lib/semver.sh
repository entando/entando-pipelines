#!/bin/bash

# Parses a semver into its complonent digits
# - "v" prefix is suppored and stripped
# - all params are optional and accept ""
#
# Params:
# $1  major version receiver var
# $2  minor version receiver var
# $3  patch version receiver var
# $4  tag version receiver var
# $5  semver to parse
#
_semver_parse() {
  _semver_ex_parse "$1" "$2" "$3" "" "$4" "$5"
  true
}

# Extended version of _semver_parse that also supports 4 digit versions
#
_semver_ex_parse() {
  local _tmpV_ _tmpT_ _tmp1_ _tmp2_ _tmp3_ _tmp4_

  IFS='-' read -r _tmpV_ _tmpT_ <<< "$6"
  IFS='.' read -r _tmp1_ _tmp2_ _tmp3_ _tmp4_ <<< "$_tmpV_"

  [ "${_tmp1_:0:1}" = "v" ] && _tmp1_="${_tmp1_:1}"
  [ "${_tmp1_:0:1}" = "p" ] && _tmp1_="${_tmp1_:1}"
  
  [ -n "$1" ] && _set_var "$1" "$_tmp1_"
  [ -n "$2" ] && _set_var "$2" "$_tmp2_"
  [ -n "$3" ] && _set_var "$3" "$_tmp3_"
  [ -n "$4" ] && _set_var "$4" "$_tmp4_"
  [ -n "$5" ] && _set_var "$5" "$_tmpT_"
  
  true
}

# Increments a semver
#
# Also supports:
#  - version prefix (v1.2.3)
#  - version tags  (1.2.3-SNAPSHOT)
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
  local _tmpP_="${2:0:1}"
  [[ "$_tmpP_" =~ [0-9] ]] && _tmpP_=""
  _set_var "$1" "${_tmpP_}$((_maj_+$3)).$((_min_+$4)).$((_ptc_+$5))${_tag_:+-$_tag_}"
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
