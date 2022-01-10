#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

ppl--run-tests() {
  (
    "SCRIPT_DIR/prj/run-tests.sh" "$@"
  )
}


# Development shell to test the pipeline code in interactive mode
#
# > It generates a temporary area where the current project is git-cloned
# > It can access almost all the internal function and global variables
#
# Please note these two helpers:
#
# - @r    command prefix (@r ppl-...) to prevent the called function to unexpectedly close the repl session
# - @rr   command to reload the scripts if you made some change to the code
#
ppl--repl() {
  local FORCE=false; [ "$1" == "--force" ] && { FORCE=true; shift; }
  local ENVFILE=""; [ "$1" == "--env" ] && { ENVFILE="$2"; shift 2; }
  
  _git_is_dirty || {
    if $FORCE; then
      _log_w "Uncommitted and/or untracked changes detected"
    else
      _log_e "Uncommitted and/or untracked changes detected"
      echo -e "Files: "
      git add . -A --dry-run | cut -d' ' -f2- | xargs -L 1 echo " -"
      _exit 1
    fi
  } 1>&2
  
  PROJECT_DIR="$PWD"
  __mk_tmp_work_area TEST__WORK_DIR
  __cd "$TEST__WORK_DIR"
  git clone "$PROJECT_DIR/" "project-clone"
  __cd "project-clone"
  
  DBGSHELL_CUSTOMIZE() {
    local rcfile="$2"
    
    ENTANDO_PPL_SET_PROMPT() {
      RED="\[\e[0;31m\]"
      COL_="\[\e[0m\]"
      if [ -n "$ENTANDO_PROJECT_NAME" ]; then
        export PS1="$ENTANDO_PROJECT_NAME>${RED}PPLSH$COL_> "
      else
        export PS1=".../${PWD##*/}>${RED}PPLSH$COL_> "
      fi
    }
    
    export -f "ENTANDO_PPL_SET_PROMPT"
    export PROMPT_COMMAND="ENTANDO_PPL_SET_PROMPT"
    
    @rr() {
      . "$SCRIPT_DIR/lib/all.sh"
      . "$SCRIPT_DIR"/macro/ppl-run.sh --source-only
      echo "script environent reloaded"
      true
    }
    
    export -f "@rr"
  
    [ -z "$ENTANDO_OPT_LOG_LEVEL" ] && export ENTANDO_OPT_LOG_LEVEL="TRACE"
    
    export PPL_CONTEXT="{{test-run}}"
    export PPL_PARSED_CONTEXT=true
    
    [ -n "$ENVFILE" ] && {
      __exist -f "$ENVFILE"
      echo ". '$ENVFILE'" >> "$rcfile"
    }
  }
  
  # shellcheck disable=SC2034
  [ -t 0 ] && IN_TTY=false || IN_TTY=true
  DBGSHELL --quiet --customize
}
