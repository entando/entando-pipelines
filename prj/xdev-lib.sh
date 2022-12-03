#!/bin/bash

#
# LICENSE: Public Domain
#

_xdev.get-config() {
  local res="$(grep "^$1=" ".xdev" | sed 's/[^=]*=//')"
  
  if [ "${res:0:1}" = '"' ]; then
    local len=${#res}
    if [ "${res:((len-1)):1}" = '"' ]; then
      res="${res:1:(($len-2))}"
    else
      _xdev.fatal "Unterminated quote detected in value for key: \"$1\""
    fi
  fi
  echo "${res:-$2}"
}

_xdev.log() {
  local type="$1"; [ "$type" = "-e" ] && { shift; }
  local pre="XDEV> "; [ "$1" = "--no-prefix" ] && { pre=""; shift; }
  case "$type" in
    "-e") echo -e "\e[0;31m$pre$*\e[0;0m";;
    *) echo -e "\e[1;30m$pre$*\e[0;0m";;
  esac
}

_xdev.fatal() {
  echo ""; _xdev.log -e "$2" 1>&2; echo ""; exit "$1";
}

_xdev.ensure-project-type() {
  [ ! -f ".xdev" ] && _xdev.fatal 77 'Unable to find the project file ".xdev"'
  local pt="$(_xdev.get-config "XDEV_LANG")"
  [ "$pt" != "$1" ] && _xdev.fatal 77 "Invalid project type: required \"$1\" but found \"$pt\" (check .xdev/XDEV_LANG)"
}

_xdev.list-src-files() {
  while IFS=':' read -d ';' -r dir patt depth; do
    [[ -z "$dir" && -z "$patt" ]] && continue
    [[ -z "$dir" || -z "$patt" ]] && exit 0
    find "$dir" -maxdepth "${depth:-10}" -type f -name "$patt"
  done <<< "${1};"
}

