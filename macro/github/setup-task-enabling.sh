#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# SETUP IN THE CI TASK ENABLING SETTINGS BY CHECKING USER PROVIDED FEATURES DIRECTIVES
# The funtion takes the tasks to check as parametes and the directives from the environment
#
# Business Rules:
# - Features are in the format of labels
# - Features are also read from the ENTANDO_OPT_FEATURES, expect for SKIP directives
# - Features are also read from the ENTANDO_OPT_GLOBAL_FEATURES, expect for SKIP directives
# - Features will be converted into CI vars usable in CI conditions
# - SKIP directive are like DISABLE directives but they should supposed to be removed once evaluated
#
# Features Directives Formats:
# - Enable a task: ENABLE-{TASK-NAME}
# - Disable a task: DISABLE-{TASK-NAME}
# - Disable a task once: SKIP-{TASK-NAME}
#
# Features Directives Priority crieria:
# 1. LABEL then ENTANDO_OPT_FEATURES then ENTANDO_OPT_GLOBAL_FEATURES
# 2. LAST directive of a given task overwrites the previous directives of the same task
# 3. Above crieria #1 wins over crieria #2
#
# Params:
# $*: a list of labels to check
#
ppl--setup-task-enabling() {
  (
    START_MACRO "setup-task-enabling" "$@"
    
    local n=1 task ACTION

    while [ $# -gt 0 ]; do
      ACTION=""
      _get_arg task "$n"; ((n++)); shift
      
      _ppl_get_feature_action ACTION "$task" ""
      
      case "$ACTION" in
        E*) _ppl-set-persistent-var "$task" true;;
        D*) _ppl-set-persistent-var "$task" false;;
        S*) _ppl-set-persistent-var "$task" false;;
        ILLEGAL)
          _log_w "Skip directives (SKIP-$task) are not allowed in "
                 "\"ENTANDO_OPT_FEATURES\" or \"ENTANDO_OPT_GLOBAL_FEATURES\" => ignored"
          ;;
      esac
      
      _common_action_handling "$task" "$ACTION"
    done
  )
}

# SETUP IN THE CI A LIST OF ENABLED TASKS ACCORDING WITH USER PROVIDED FEATURES DIRECTIVES
#
# @see ppl--setup-task-enabling
#

ppl--setup-task-list() {
  (
    START_MACRO "CHECK-TASK-LIST" "$@"

    local n=1 task ACTION RES

    _get_arg RES_VAR 1; ((n++)); shift
    _get_arg DEFVAL 2; ((n++)); shift
    
    while [ $# -gt 0 ]; do
      _get_arg task "$n"; ((n++)); shift
      
      _ppl_get_feature_action ACTION "$task" "$DEFVAL"
      
      case "$ACTION" in
        E*) RES+="'$task',";;
      esac
      
      _common_action_handling "$task" "$ACTION"
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
  local _tmp_task="$1"
  local _tmp_action="$2"
  
  case "$_tmp_action" in
    E*)
      _log_i "Explicitly enabling task \"$_tmp_task\" (due to ${_tmp_action:2})"
      ;;
    D*)
      _log_i "Explicitly disabling task \"$_tmp_task\" (due to ${_tmp_action:2})"
      ;;
    S*)
      _log_i "Explicitly skipping task \"$_tmp_task\" (due to ${_tmp_action:2})"
      _ppl-pr-remove-label "$PPL_PR_NUM" "SKIP-$_tmp_task"
      ;;
  esac
}
