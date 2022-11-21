#!/bin/bash

PROJECT_DIR="$PWD"

. "$PROJECT_DIR/lib/shared/shorts.sh"
. "$PROJECT_DIR/lib/shared/essential.sh"
. "$PROJECT_DIR/lib/shared/log.sh"
. "$PROJECT_DIR/lib/shared/sys.sh"
. "$PROJECT_DIR/lib/shared/verify.sh"

_IT() {
  TEST_CALLER="$(caller 0)"
  TEST_IT="$1"; shift
  
  _ESS_SILENCE_ERRORS=false
  _ESS_IGNORE_EXITCODE=false
  
  while [ $# -gt 0 ]; do
    case "$1" in
      "SILENCE-ERRORS") _ESS_SILENCE_ERRORS=true;;
      "IGNORE-EXITCODE") _ESS_IGNORE_EXITCODE=true;;
      "SUPPRESS-ERRORS") _ESS_SILENCE_ERRORS=true;_ESS_IGNORE_EXITCODE=true;;
    esac
    shift
  done

  if $_ESS_IGNORE_EXITCODE; then
    TEST_EXIT_TRAP() { :; }
  else
    TEST_EXIT_TRAP() {
      local rc="$?"
      [ "$rc" != 0 ] && {
        _xdev.test-failed-low-level "$rc" \
          "${TEST_CALLER}" "It $TEST_IT${TEST_FAIL_MESSAGE:+", details: $TEST_FAIL_MESSAGE"}"
      }
    }
    trap TEST_EXIT_TRAP EXIT
  fi
}

_FAIL() {
  local SKIP="1";[ "$1" = "-S" ] && { SKIP="$2"; shift 2; }
  local STOP="true";[ "$1" = "--continue" ] && { STOP="false"; shift 1; }
  TEST_FAIL_MESSAGE="$*"
  _xdev.failures --inc
  (_FATAL -S "${SKIP}" -99 "$*")
  $STOP && _exit 99
  return 99
}

_ASSERT_RC() {
  local rc="$?"
  _ASSERT -v "EXIT CODE" "$rc" = "$1"
}

DBGSHELL() { :; }

_ASSERT() {
  local SKIP="1";[ "$1" = "-S" ] && { SKIP="$((SKIP+$2))"; shift 2; }
  (
    _verify.verify-expression -S "$SKIP" "TEST" "$@"
  ) || {
    local rc="$?"
    "${TEST_RUN_DBGSHELL_ON_ASSERT:-false}" && DBGSHELL -S 1
    exit "$rc"
  }
}
