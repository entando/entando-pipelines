#/bin/bash

# Sets a variable given the name and the value
#
# WARNING:
# This function can be used to set a variable of the caller's scope and this tecnique
# is commonly used to return values to the caller.
# But note that if there is a variable with same name in the local scope, the local one
# is preferred leaving the caller's variable untouched.
# That's why functions that returns values uses a special naming convention for their
# internal variables (_tmp_...).
#
# Params:
# - $1: variable to set
# - $2: value
#
# Alias:
# _set_var() { ... }
#
_vars.set_var() {
  [ -z "$1" ] && _ess.low_level_fatal "null var_name provided"
  _vars.is_valid_var_name "$1" || _ess.low_level_fatal -S 1 "invalid var_name \"$1\" provided"
  if [ -z "$2" ]; then
    read -r -d '' "$1" <<< ""
  else
    read -r -d '' "$1" <<< "$2"
  fi

  return 0
}

# Tells if an array contains the given element
#
# WARNING: DO NOT OPTIMIZE
# used in sensible contexts, it must be as safe and not fast
#
# Params:
# $1    the element to find
# $..   the array to search into
#
# Examples:
# > _vars.array.contains "b" "a" "b" "c"
# > _vars.array.contains "--init" "$@"
# 
_vars.array.contains() {
  local match="$1";shift
  while [ $# -gt 0 ]; do
    [ "$1" = "$match" ] && return 0
    shift
  done
  return 1
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SUBORDINATE METHODS
#

_vars.is_valid_var_name() {
  # shellcheck disable=SC2234
  ([[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]])  # NOTE: the subshell restricts the side effects, don't remove it
}


# Sets one ore more evironment variables given a semicolon-delimited list of assignments
#
# WARNING: the parser interprets the backslash
# WARNING: the parser doesn't support quotes like a CSV, however you can still escape the colon with the backslash ("\;")
#
# Options:
# --var-sep value    the var separator to assume
# --section          select a specific section of the settings
# --stdin            reads the environment the stdin
#
# Line level options:
#
# [p]VAR=VALUE   <= VAR is set only if currently empty
#
# Paramers:
# $1                unless "--stdin" is provider it's the environment to be loaded
#
# eg:
# - LEGAL:   _ppl_load_settings 'A=1;B=hey there;C=true'
# - ILLEGAL: _ppl_load_settings 'A=1;B="hey;there";C=true'
# - LEGAL:   _ppl_load_settings 'A=1;B=hey\;there;C=true'
#
# Multisection example:
# [SECT01]
# A=1
# [SECT02]
# A=2
#
_vars.load() {
  local LNSEP=';';[ "$1" == "--var-sep" ] && { LNSEP="$2"; shift 2; }
  local SECT="";[ "$1" == "--section" ] && { SECT="$2"; shift 2; }

  {
    if [ "$1" != "--stdin" ]; then
      local tmp="${1//$LNSEP/$'\n'}"
      tmp="${tmp//\\$'\n'/\\$LNSEP}"
      _vars.load ${SECT:+--section "$SECT"} --stdin <<< "$tmp"
      return "$?"
    fi
    
    local last=false
    local in_sect=""
    local preserve
    
    while true; do
      # shellcheck disable=SC2162
      read line || last=true
      
      preserve=false
      append=false
      
      if [ -n "$line" ]; then
        [[ "${line:0:3}" == "###" ]] && line="${line:3}"
        [[ "${line:0:1}" == "#" ]] && continue;
        [[ "${line:0:3}" == "[p]" ]] && { line="${line:3}"; preserve=true; }
        [[ "${line:0:3}" == "[a]" ]] && { line="${line:3}"; append=true; }
        [[ "${line:0:2}" == "p;" ]] && { line="${line:2}"; preserve=true; }
        [[ "${line:0:2}" == "a;" ]] && { line="${line:2}"; append=true; }
        
        [[ "${line:0:1}" == "[" ]] && { in_sect="${line:1:-1}"; continue; }
        [[ "$in_sect" != "$SECT" ]] && continue;
      
        # shellcheck disable=SC2162
        IFS='=' read -r name value <<< "$line"
        [[ "$(_vars.str.last_char_of "$name")" = "+" ]] && { name="$(_vars.str.chop "$name")"; append=true; }
        
        _vars.is_valid_name "$name" || {
          _log.d "Invalid var name: \"$name\""
          _sys.fatal "Invalid var name"
        }
        if [[ "${!name}" != "" ]]; then
          "$preserve" && continue
          "$append" && value="${!name},${value}"
        fi
        _vars.set_var "$name" "$value"
        # shellcheck disable=SC2163
        export "$name"
      fi
      $last && break
    done
  }
}

_vars.str.last_char_of() {
  local len="${#1}"
  ((len--))
  if [ "$len" -ge 0 ]; then
    echo -n "${1:$len}"
  else
    echo -n ""
  fi
}

_vars.str.chop() {
  local len="${#1}"
  ((len--))
  if [ "$len" -ge 0 ]; then
    echo -n "${1:0:$len}"
  else
    echo -n ""
  fi
}

_vars.is_valid_name() {
  # shellcheck disable=SC2234
  ([[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]])  # NOTE: the subshell restricts the side effects, don't remove it
}

# Converts a value to lowercase
_vars.str.lower() {
  _vars.set_var "$1" "$(echo "$2" | tr '[:upper:]' '[:lower:]')"
}

# Returns the position of the last occurrent of string in a comma separed list
#
_vars.str.last_pos() { 
  local _slp_tmp1_ _slp_tmp2_="$2" _slp_tmp3_=0 _slp_tmp4_=-1
  while IFS= read -r _slp_tmp1_; do
    if [ "$_slp_tmp1_" = "$3" ]; then
      _slp_tmp4_="$_slp_tmp3_"
    fi
    ((_slp_tmp3_++))
  done <<<"${_slp_tmp2_//,/$'\n'}"  
  _vars.set_var "$1" "$_slp_tmp4_"
}
