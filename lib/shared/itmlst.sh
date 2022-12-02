#/bin/bash

_require "lib/shared/vars.sh"


# Fills a itmlst (list of items) with the given list of entrie
#
# Note that a itmlst is defined as:
# - Comma-delimitest list started amd terminated bu a comma (eg: ",red,blue,")
#
# Params:
# $1  the label list
# $.. the entries to add
#
_itmlst.fill() {
  local _var_name_="$1"; shift
  local _tmp_
  for _tmp_L_ in "$@"; do
    _tmp_+=",$_tmp_L_"
  done
  _set_var "$_var_name_" "${_tmp_:1}"
}

# Checks if a given entry is present in a itmlst (list of items)
#
# @see _itmlst.fill for the definition of "lsblsst"
#
# Params:
# $1 the label list
# $2 the entry
#
_itmlst.contains() {
  local _il_tmp_
  _vars.str.last_pos _il_tmp_ "$1" "$2"
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
_itmlst.is_item_enabled() {
  local _il_tmpP_ _il_tmpN_ _il_tmpPa_ _il_tmpNa_

  _vars.str.last_pos _il_tmpPa_ "$1" "*"
  _vars.str.last_pos _il_tmpNa_ "$1" "-*"
  _vars.str.last_pos _il_tmpP_ "$1" "$2"
  _vars.str.last_pos _il_tmpN_ "$1" "-$2"

  [ "$_il_tmpPa_" -gt "$_il_tmpP_" ] && _il_tmpP_="$_il_tmpPa_"
  [ "$_il_tmpNa_" -gt "$_il_tmpN_" ] && _il_tmpN_="$_il_tmpNa_"

  [ "$_il_tmpP_" -gt "$_il_tmpN_" ]
}

# Checks if a given itmlst is empty
#
# @see _itmlst.fill for the definition of "lsblsst"
#
# Params:
# $1 the label list
#
_itmlst.empty() {
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
_itmlst.from_string() {
  local _tmp_="$2"
  _tmp_="${_tmp_//$'\n'/,}"
  _tmp_="${_tmp_//$'|'/,}"
  _set_var "$1" "$_tmp_"
}
