#/bin/bash

_sys.require "lib/shared/filesystem.sh"

prj.current.determine_type() {
  local _tmp_
  
  if [[ -f "entando-project" ]]; then
    _tmp_="ENP"
    local _tmp_="$(prj.get_config_value "entando-project" "PROJECT_TYPE")"
    [ -z "$_tmp_" ] && _tmp_="ENP"
  elif [ -f "pom.xml" ]; then
    _tmp_="MVN"
  elif [ -f "package.json" ]; then
    _tmp_="NPM"
  else
    _FATAL -S 1 "Unable to determine the project type"
  fi
  
  echo "$_tmp_"
}


# Reads a configuration value from an enp configuration file.
#
# An ENP configuration is a multiline sequence of rows.
# Multiline values are not supported.
#
# Params:
# $1: config file
# $2: config key
# $3: fallback value
#
# Row Format: 
# - key: identifier
# - sep: the leftmost symbol "="
# - val: a sequence of any char except for the linefeed, optionally enclosed in quotes
#
prj.get_config_value() {
  __exist -f "$1"

  local res="$(grep "^$2=" "$1" | sed 's/[^=]*=//' | tail -1)"
  if [ "${res:0:1}" = '"' ]; then
    local len=${#res}
    if [ "${res:((len-1)):1}" = '"' ]; then
      res="${res:1:(($len-2))}"
    else
      _FATAL "Unterminated quote detected in value for key: \"$2\""
    fi
  fi
  echo "${res:-$3}"
}
