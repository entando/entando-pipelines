#!/bin/bash

PROJECT_DIR="$PWD"

. "$PROJECT_DIR/lib/local/shorts.sh"
. "$PROJECT_DIR/lib/shared/essential.sh"

_require() {
  local SKIP=1;[ "$1" = "-S" ] && { ((SKIP+=$2)); shift 2; }
  \_sys.require -S "$SKIP" "$1"
}

_require "$PROJECT_DIR/lib/shared/log.sh"
_require "$PROJECT_DIR/lib/shared/sys.sh"
_require "$PROJECT_DIR/lib/shared/verify.sh"

export ENTANDO_OPT_GIT_USER_NAME="test-user"
export ENTANDO_OPT_GIT_USER_EMAIL="test-user@example.com"

_IT() {
  _ESS_TEST_CALLER="$(caller 0)"
  _ESS_TEST_IT="$1"; shift

  local ignored
  read -r ignored fn ignored <<<"$_ESS_TEST_CALLER"
  _xdev.log "It $_ESS_TEST_IT"
  
  _ESS_SILENCE_ERRORS=false
  _ESS_IGNORE_EXITCODE=true
  _ESS_TEST_FAIL_MESSAGE=""
  _ESS_TEST_FAIL_RC=0
  _ESS_IN_TEST_EXIT_TRAP=false
  
  while [ $# -gt 0 ]; do
    case "$1" in
      "SILENCE-ERRORS") _ESS_SILENCE_ERRORS=true;;
      "CHECK-EXITCODE") _ESS_IGNORE_EXITCODE=false;;
    esac
    shift
  done

  TEST_EXIT_TRAP() {
    local rc="$?"
    
    [ "$_ESS_IN_TEST_EXIT_TRAP" == true ] && return 0
    _ESS_IN_TEST_EXIT_TRAP=true

    [ "$_ESS_IGNORE_EXITCODE" == "true" ] && {
      rc=0
      [ "$_ESS_TEST_FAIL_RC" != "0" ] && rc="${_ESS_TEST_FAIL_RC:-0}"
    }

    [ "$rc" != 0 ] && {
      local postmsg=""
      [ "$(_xdev.failures)" = 0 ] && {
        postmsg="\n\nPLEASE NOTE that no explicit test failure was detected, but the test cloure returned error.\n---"
      }
      
      _xdev.test-failed-low-level "$rc" \
        "${_ESS_TEST_CALLER}" "It $_ESS_TEST_IT${_ESS_TEST_FAIL_MESSAGE:+", details: $_ESS_TEST_FAIL_MESSAGE"}$postmsg"
    }
  }
  trap TEST_EXIT_TRAP EXIT
  
  return 0
}

_FAIL() {
  local SKIP=1;[ "$1" = "-S" ] && { ((SKIP+=$2)); shift 2; }
  local STOP=true;[ "$1" = "--and-continue" ] && { STOP=false; shift 1; }
  _ESS_TEST_FAIL_MESSAGE="$*"
  _ESS_TEST_FAIL_RC=99
  _xdev.failures --inc
  (_FATAL -S "${SKIP}" -99 "${_ESS_TEST_FAIL_MESSAGE:-"TEST FAILED"}") 
  $STOP && _exit 99
  return 99
}

_ASSERT_RC() {
  local rc="$?"
  _ASSERT -S 1 -v "EXIT CODE" "$rc" = "$1"
}

DBGSHELL() { :; }

_ASSERT() {
  local SKIP=1;[ "$1" = "-S" ] && { ((SKIP+=$2)); shift 2; }
  (
    _verify.verify-expression -S "$SKIP" "TEST" "$@"
  ) || {
    local rc="$?"
    "${TEST_RUN_DBGSHELL_ON_ASSERT:-false}" && DBGSHELL -S 1
    _xdev.failures --inc
    exit "$rc"
  }
}

_DETERMINE_TEST_RESOURCE_PATH() {
  if [ "$1" = "--global" ]; then
    local F="$PROJECT_DIR/test/resource/$2"
  else
    local F="$XDEV_FILE_DIR/resource/test/$1"
  fi
  [ -f "$F" ] || _FATAL -S 1 "Unable to find test file \"$F\""
  echo "$F"
}

_PRINT_TEST_FILE() {
  cat "$(_DETERMINE_TEST_RESOURCE_PATH "$@")"
}

_LOAD_TEST_FILE() {
  local OPT="";[ "$1" = "--global" ] && { OPT="$1"; shift; }
  local VAR="$1";shift
  _vars.set_var "$VAR" "$(_PRINT_TEST_FILE ${OPT:+"$OPT"} "$@")"
}

_IMPORT_TEST_RESOURCE() {
  local OPT="";[ "$1" = "--global" ] && { OPT="$1"; shift; }
  mkdir -p "resource"
  if [ "$1" = "--untar" ]; then
    shift
    (
      cd "resource"
      _log.d "Importing resource $* ($OPT)"
      tar xfvz "$(_DETERMINE_TEST_RESOURCE_PATH ${OPT:+"$OPT"} "$@")" 1>/dev/null
    )
  else
    _log.d "Importing resource $* ($OPT)"
    cp "$(_DETERMINE_TEST_RESOURCE_PATH "${OPT:+"$OPT"}" "$@")" "resource"
  fi
}
