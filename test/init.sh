#!/bin/bash

PROJECT_DIR="$PWD"

. "$PROJECT_DIR/lib/local/shorts.sh"
. "$PROJECT_DIR/lib/shared/essential.sh"
_sys.require "$PROJECT_DIR/lib/shared/log.sh"
_sys.require "$PROJECT_DIR/lib/shared/sys.sh"
_sys.require "$PROJECT_DIR/lib/shared/verify.sh"

_IT() {
  _ESS_TEST_CALLER="$(caller 0)"
  _ESS_TEST_IT="$1"; shift

  local ignored
  read -r ignored fn ignored <<<"$_ESS_TEST_CALLER"
  _xdev.log "It $_ESS_TEST_IT"
  
  _ESS_SILENCE_ERRORS=false
  _ESS_IGNORE_EXITCODE=false
  _ESS_TEST_FAIL_MESSAGE=""
  _ESS_TEST_FAIL_RC=0

  
  while [ $# -gt 0 ]; do
    case "$1" in
      "SILENCE-ERRORS") _ESS_SILENCE_ERRORS=true;;
      "IGNORE-EXITCODE") _ESS_IGNORE_EXITCODE=true;;
      "SUPPRESS-ERRORS") _ESS_SILENCE_ERRORS=true;_ESS_IGNORE_EXITCODE=true;;
    esac
    shift
  done

  TEST_EXIT_TRAP() {
    local rc="$?"

    [ "$_ESS_IGNORE_EXITCODE" == "true" ] && {
      rc=0
      [ "$_ESS_TEST_FAIL_RC" != "0" ] && rc="${_ESS_TEST_FAIL_RC:-0}"
    }

    [ "$rc" != 0 ] && {
      _xdev.test-failed-low-level "$rc" \
        "${_ESS_TEST_CALLER}" "It $_ESS_TEST_IT${_ESS_TEST_FAIL_MESSAGE:+", details: $_ESS_TEST_FAIL_MESSAGE"}"
    }
  }
  trap TEST_EXIT_TRAP EXIT
}

_FAIL() {
  local SKIP=1;[ "$1" = "-S" ] && { ((SKIP+=$2)); shift 2; }
  local STOP=true;[ "$1" = "--and-continue" ] && { STOP=false; shift 1; }
  _ESS_TEST_FAIL_MESSAGE="$*"
  _ESS_TEST_FAIL_RC=99
  _xdev.failures --inc
  (_FATAL -S "${SKIP}" -99 "${_ESS_TEST_FAIL_MESSAGE:-"TEST FAILED"}") && $STOP && _exit 99
  return 99
}

_ASSERT_RC() {
  local rc="$?"
  _ASSERT -v "EXIT CODE" "$rc" = "$1"
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