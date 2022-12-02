#/bin/bash 

_require "lib/shared/filesystem.sh"
_require "lib/shared/vars.sh"
_require "lib/shared/cli.sh"


ppl.enter_local_clone_dir() {
  [ -z "$1" ] && _FATAL -S 1 "Null local clone dir detected"
  cd "$1" || _FATAL -S 1 "Unable to enter local clone dir \"$1\""
}

ppl.start_macro() {
  local PPL_MACRO="$1";shift
  local enterlc

  _cli.parse_args "--enter-local-clone --checkout" "$@"
  _cli.get_arg -m PPL_ACTION 1
  _cli.get_arg -m PPL_LOCAL_CLONE_DIR --lcd
  _cli.get_arg PPL_TYPE --type
  _cli.get_arg PPL_CHECKOUT --checkout
  _cli.get_arg PPL_CHECKOUT_TOKEN --checkout-with-token && PPL_CHECKOUT=true
  
  _cli.get_arg -m enterlc --enter-local-clone
  
  _pp PPL_MACRO PPL_ACTION PPL_LOCAL_CLONE_DIR PPL_TYPE PPL_CHECKOUT
  
  "$enterlc" && { 
    ppl.enter_local_clone_dir "$PPL_LOCAL_CLONE_DIR"
    PPL_PROJECT_TYPE="$(prj.current.determine_type)"
    _NONNULL PPL_PROJECT_TYPE
  }
}

ppl.plan.run() {
  local AUTHVAR="$1"
  local project_type
  local plan="$3"
  
  _vars.str.lower project_type "$2"

  while read -d ',' -r step; do
    [ -z "$step" ] && continue
    
    _log_i "> Running step: $step"

    if ppl.is-project-action "$step"; then
      IFS='.' read prefix action <<< "$step"
      ppl.safe-dynamic-invokation "$AUTHVAR" "$project_type" "plan.$action"
    else
      ppl.safe-dynamic-invokation "$AUTHVAR" "global" "$step"
    fi
  done <<< "$plan,"
}

ppl.safe-dynamic-invokation() {
  local AUTHVAR="$1" MODULE="$2" FUNCTION="$3"
  shift 3 || _FATAL "Internal error"
  
  local spec="$MODULE.$FUNCTION"
  local fn="$(tr [:upper:] [:lower:] <<< "macro.$spec")"
  
  local arrname="$AUTHVAR[@]"
  _vars.array.contains "$fn" "${!arrname}" || _FATAL -S 1 "Unautorized call \"$spec\""
  type "$fn" &>/dev/null || _FATAL -S 1 "Unable to find the implementation of call \"$spec\""
  
  [[ "$((++PPL_NESTING_LEVEL))" -gt 30 ]] && _FATAL "Nesting oveflow"
  
  ("$fn" "$@")
  local rv="$?"
  
  ((--PPL_NESTING_LEVEL))
  return "$?"
}

ppl.is-project-action() {
  [ "${1:0:4}" = "prj." ]
}
