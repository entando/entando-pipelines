#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# SETUP IN THE CI FEATURE ENABLING SETTINGS BY CHECKING USER PROVIDED FEATURES DIRECTIVES
# The funtion takes the features to check as parametes and the directives from the environment
#
# Params:
# $*: a list of features to check
#
# @see _ppl_get_feature_action for details
#
ppl--setup-feature-flags() {
  (
    START_MACRO "SETUP-FEATURES-FLAGS" "$@"
    
    local n=1 feature ACTION

    while [ $# -gt 0 ]; do
      ACTION=""
      _get_arg feature "$n"; ((n++)); shift
      
      _ppl_get_feature_action ACTION "$feature" ""
      
      case "$ACTION" in
        E*) _ppl-set-persistent-var "$feature" true;;
        D*) _ppl-set-persistent-var "$feature" false;;
        S*) _ppl-set-persistent-var "$feature" false;;
        I*)
          _log_w "Skip directives (SKIP-$feature) are not allowed in " \
                 "\"ENTANDO_OPT_FEATURES\" or \"ENTANDO_OPT_GLOBAL_FEATURES\" => ignored"
          ;;
      esac
      
      _common_action_handling "$feature" "$ACTION"
    done
  )
}

# SETUP IN THE CI A LIST OF ENABLED FEATURES ACCORDING WITH USER PROVIDED FEATURES DIRECTIVES
#
# @see _ppl_get_feature_action for details
#

ppl--setup-features-list() {
  (
    START_MACRO "SETUP-FEATURES-LIST" "$@"

    local n=1 feature ACTION RES

    _get_arg RES_VAR 1; ((n++)); shift
    _get_arg DEFVAL 2; ((n++)); shift
    
    while [ $# -gt 0 ]; do
      _get_arg feature "$n"; ((n++)); shift
      
      _ppl_get_feature_action ACTION "$feature" "$DEFVAL"
      
      case "$ACTION" in
        E*) RES+="'$feature',";;
      esac
      
      _common_action_handling "$feature" "$ACTION"
    done
    
    if [ -n "$RES" ]; then
      RES="[${RES::-1}]"
      _ppl-set-persistent-var "$RES_VAR" "$RES"
    fi    
  ) 
}

#~~~
# INTERNAL UTILS
_common_action_handling() {
  local _tmp_feature="$1"
  local _tmp_action="$2"
  
  case "$_tmp_action" in
    E*)
      _log_i "Explicitly enabling feature \"$_tmp_feature\" (due to ${_tmp_action:2})"
      ;;
    D*)
      _log_i "Explicitly disabling feature \"$_tmp_feature\" (due to ${_tmp_action:2})"
      ;;
    S*)
      _log_i "Explicitly skipping feature \"$_tmp_feature\" (due to ${_tmp_action:2})"
      _ppl-pr-remove-label "$PPL_PR_NUM" "SKIP-$_tmp_feature"
      ;;
  esac
}
