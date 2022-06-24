#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# SETUP IN THE CI A SET OF FEATURE-FLAGS ACCORDING WITH USER DIRECTIVES
# The funtion takes the features to check as parametes and the directives from the environment
#
# Params:
# $*: a list of features to check
#
# @see _ppl_get_feature_action for details
#
ppl--setup-feature-flags() {
  (
    START_MACRO --no-repo "SETUP-FEATURES-FLAGS" "$@"
    
    local n=1 feature feature_as_var ACTION

    while [ $# -gt 0 ]; do
      # shellcheck disable=SC2030
      ACTION=""
      _get_arg feature "$n"; ((n++)); shift
      
      feature_as_var="${feature//-/_}"
      
      _ppl_get_feature_action ACTION "${feature//_/-}" ""
      [ -z "$ACTION" ] && _ppl_get_feature_action ACTION "${feature_as_var}" ""
      
      case "$ACTION" in
        E*) _ppl-set-persistent-var "${feature_as_var}" true;;
        D*) _ppl-set-persistent-var "${feature_as_var}" false;;
        S*) _ppl-set-persistent-var "${feature_as_var}" false;;
        I*)
          _log_w "Skip directives (SKIP-$feature) are not allowed in " \
                 "\"ENTANDO_OPT_FEATURES\" or \"ENTANDO_OPT_GLOBAL_FEATURES\" => ignored"
          ;;
      esac
      
      _common_action_handling -v "$feature" "$ACTION"
    done
  )
}

# SETUP IN THE CI A LIST OF ENABLED FEATURES ACCORDING WITH USER PROVIDED FEATURES DIRECTIVES
#
# @see _ppl_get_feature_action for details
#
# Options
# -p prefix mode
# 
# Normal Params:
# $1: a list of features to check
#
# Prefix mode params:
# $1: prefix used to filter ENTANDO_OPT_GLOBAL_FEATURES and ENTANDO_OPT_FEATURES
#
ppl--setup-features-list() {
  (
    START_MACRO --no-repo "SETUP-FEATURES-LIST" "$@"
    
    _get_arg res_var 1
    _get_arg def_val 2
    
    local prefix 
    _get_arg prefix --prefix
    
    if [ -n "$prefix" ]; then
      local exclusion_prefix
      _get_arg exclusion_prefix --exclude
      ppl--setup-features-list.with-prefix "$res_var" "$prefix" "$exclusion_prefix"
    else
      shift 2
      ppl--setup-features-list.with-list "$res_var" "$def_val" "$@"
    fi
  )
}

ppl--setup-features-list.with-prefix() {
  local LIST=() TMP
  IFS=, read -ra TMP <<< "$PPL_FEATURES"
  for feature in "${TMP[@]}"; do
    feature="${feature/#-/}"
    feature="${feature/#+/}"
    feature="${feature/#SKIP-/}"
    ppl--setup-features-list.has-prefix "$feature" "$2" "$3" && LIST+=("$feature")
  done <<< "$PPL_FEATURES"
  ppl--setup-features-list.with-list "$1" true "${LIST[@]}"
}

ppl--setup-features-list.has-prefix() {
  IFS=, read -ra TMP <<< "$2"
  for pre in "${TMP[@]}"; do
    [[ "$1" == *"$pre"* ]] && [[ -z "$3" || ! "$1" == *"$3"* ]] && return 0
  done
  return 1
}


ppl--setup-features-list.with-list() {
  local n=1 feature ACTION RES

  res_var="$1"; shift
  def_val="$2"; shift
  
  # shellcheck disable=SC2031
  while [ $# -gt 0 ]; do
    feature="$1"; shift
    
    _ppl_get_feature_action ACTION "$feature" "$def_val"
    
    case "$ACTION" in
      E*) RES+="'$feature',";;
    esac

    _common_action_handling "$feature" "$ACTION"
  done
  
  if [ -n "$RES" ]; then
    RES="[${RES::-1}]"
    _ppl-set-persistent-var "$res_var" "$RES"
  fi
}

# INTERNAL UTILS
#
_common_action_handling() {
  local VERBOSE=false; [ "$1" = "-v" ] && { VERBOSE=true; shift; }
  local _tmp_feature="$1"
  local _tmp_action="$2"
  
  case "$_tmp_action" in
    E*)
      $VERBOSE && _log_i "Explicitly enabling feature \"$_tmp_feature\" (due to ${_tmp_action:2})"
      ;;
    D*)
      $VERBOSE && _log_i "Explicitly disabling feature \"$_tmp_feature\" (due to ${_tmp_action:2})"
      ;;
    S*)
      $VERBOSE && _log_i "Explicitly skipping feature \"$_tmp_feature\" (due to ${_tmp_action:2})"
      _ppl-pr-remove-label "$PPL_PR_NUM" "SKIP-$_tmp_feature"
      ;;
  esac
}
