#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# SETUP IN THE CI TASK ENABLING SETTINGS BY CHECKING USER PROVIDED DIRECTIVES
# The funtion takes the tasks to check as parametes and the directives from the environment
#
# Business Rules:
# - Directives are in the format of labels
# - Directives are also read from the ENTANDO_OPT_DIRECTIVES, expect for SKIP directives
# - Directives will be converted into CI vars usable in CI conditions
# - SKIP directive are like DISABLE directives but they should supposed to be removed once evaluated
#
# Directives Formats:
# - Enable a task: ENABLE-{TASK-NAME}
# - Disable a task: DISABLE-{TASK-NAME}
# - Disable a task once: SKIP-{TASK-NAME}
#
# Directives Priority crieria:
# 1. LABEL WINS: labels always wins over ENTANDO_OPT_DIRECTIVES
# 2. LAST WINS:  the last directive of a given task overwrites the previous directives of the same task
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
      
      _get_task_action ACTION "$task" ""
      
      case "$ACTION" in
        E*) _ppl-set-persistent-var "$task" true;;
        D*) _ppl-set-persistent-var "$task" false;;
        S*) _ppl-set-persistent-var "$task" false;;
        ILLEGAL)
          _log_w "Skip directives (SKIP-$task) are not allowed in \"ENTANDO_OPT_DIRECTIVES\" => ignored"
          ;;
      esac
    done
  )
}

# SETUP IN THE CI A LIST OF ENABLED TASKS ACCORDING WITH USER PROVIDED DIRECTIVES
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
      _get_task_action ACTION "$task" "$DEFVAL"
      
      case "$ACTION" in
        E*) RES+="'$task',";;
      esac
    done
    
    if [ -n "$RES" ]; then
      RES="[${RES::-1}]"
      _ppl-set-persistent-var "$RES_VAR" "$RES"
    fi    
  ) 
}

#~~~
# INTERNAL UTILS
_get_task_action() {
  local _tmp_task="$2" _tmp_action
  
  case "$3" in
    "true") _tmp_action="E.fallback";;
    "false") _tmp_action="D.fallback";;
  esac
  
  # shellcheck disable=SC2154
  {
    _itmlst_contains "$ENTANDO_OPT_DIRECTIVES" "ENABLE-$_tmp_task" && _tmp_action="E.var"
    _itmlst_contains "$ENTANDO_OPT_DIRECTIVES" "DISABLE-$_tmp_task" && _tmp_action="D.var"
    _itmlst_contains "$ENTANDO_OPT_DIRECTIVES" "SKIP-$_tmp_task" && _tmp_action="ILLEGAL"
  }
  _ppl-pr-has-label "ENABLE-$_tmp_task" && _tmp_action="E.label"
  _ppl-pr-has-label "DISABLE-$_tmp_task" && _tmp_action="D.label"
  _ppl-pr-has-label "SKIP-$_tmp_task" && _tmp_action="S.label"
  
  case "$_tmp_action" in
    E*)
      _log_i "Explicitly enabling task \"$_tmp_task\" (due to ${_tmp_action:2})"
      ;;
    D*)
      _log_i "Explicitly disabling task \"$_tmp_task\" (due to ${_tmp_action:2})"
      ;;
    S*)
      _log_i "Explicitly skipping task \"$_tmp_task\" (due to ${_tmp_action:2})"
      _ppl-pr-remove-label "$EE_PR_NUM" "SKIP-$_tmp_task"
      ;;
  esac

  _set_var "$1" "$_tmp_action"
}
