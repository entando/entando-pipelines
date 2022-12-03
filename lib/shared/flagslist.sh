#/bin/bash

# flagslist are strings containing a list of flags.
#
# They support:
#
# - multiple separators ("," "|" "\n")
# - wildcards ("*")
# - substractions ("-flag")
#

_require "lib/shared/strings.sh"
_require "lib/shared/vars.sh"

# Fills a flagslist (list of flags) with the given list of entrie
#
# Note that a flagslist is defined as:
# - Comma-delimitest list started amd terminated bu a comma (eg: ",red,blue,")
#
# Params:
# $1  the label list
# $.. the entries to load
#
_flagslist.build() {
  local _var_name_="$1"; shift
  local _tmp_
  for _tmp_L_ in "$@"; do
    _tmp_+=",$_tmp_L_"
  done
  _vars.set_var "$_var_name_" "${_tmp_:1}"
}

# Checks if a given entry enabled in flagslist, which means:
# - it's contained
# - its negative (prefixed with a minus) is not contained
#
# Params:
# $1 the label list
# $2 the entry
#
# Options:
# [-W] consider the "*" as a wildcard matching for every flag
#
_flagslist.is_flag_enabled() {
  local idx_wcd_pos="$(_strings.list.last_index_of  "$1" "*")"
  local idx_wcd_neg_="$(_strings.list.last_index_of "$1" "-*")"
  local idx_elm_pod="$(_strings.list.last_index_of "$1" "$2")"
  local idx_elm_neg="$(_strings.list.last_index_of "$1" "-$2")"

  [ "$idx_wcd_pos" -gt "$idx_elm_pod" ] && idx_elm_pod="$idx_wcd_pos"
  [ "$idx_wcd_neg_" -gt "$idx_elm_neg" ] && idx_elm_neg="$idx_wcd_neg_"

  [ "$idx_elm_pod" -gt "$idx_elm_neg" ]
}

# Checks if a given flagslist is empty
#
# @see _flagslist.build for the definition of "lsblsst"
#
# Params:
# $1 the label list
#
_flagslist.is_empty() {
  [[ "$1" = "," || "$1" = ",," || "$1" = "" ]]
}

# Generates an flagslist from a list string
#
# Params:
# $1 the receiver of the flagslist
# $2 the source list string
#
# Supports the following separators:
# - ","
# - "|"
# - "\n"
#
_flagslist.from_string() {
  local _tmp_="$2"
  _tmp_="${_tmp_//$'\n'/,}"
  _tmp_="${_tmp_//$'|'/,}"
  _vars.set_var "$1" "$_tmp_"
}
