#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC2046
cd "$SCRIPT_DIR/.." || { echo "Unable to enter the script dir"; exit 99; }

. "./lib/base.sh"     # only for the itmlst functions

ENTANDO_OPT_LOG_LEVEL="${ENTANDO_OPT_LOG_LEVEL:-DEBUG}"
# Composes the execution labels "itmlst"
EXECUTION_LABELS=""
_itmlst_fill EXECUTION_LABELS "$@"
_itmlst_empty "$EXECUTION_LABELS" && _itmlst_fill EXECUTION_LABELS "lib" "macro"

echo -e "\nTEST> Execution labels: ${EXECUTION_LABELS:1:-1}\n"

_failend() { EC="$?"; echo -e "\nTEST> TEST FAILURE DETECTED (EXITCODE: $EC)\n"; exit "$EC"; }

#~
#~ SETUP TEST ENVIRONMENT
#~

# shellcheck disable=SC1091
{
  PROJECT_DIR="$PWD"
  . "./lib/base.sh"
  cd "./test" || { echo "Error entering the test dir"; exit 2; }
  TEST_WORK_DIR="$(mktemp -d)"
  cd "$TEST_WORK_DIR"
  touch "$TEST_WORK_DIR/.effimeral-test-dir"
  tar xfz "$PROJECT_DIR/test/resources/6017ee92-ba94-40a2-b098-91b2c04f107b.tgz" "6017ee92-ba94-40a2-b098-91b2c04f107b"
}

TEST_EXECUTION=true
TEST_TECHNICAL_LOG_FILE="$TEST_WORK_DIR/ttlog"
echo "[REM] STARTED AT $(date +'%Y-%m-%d %H-%M-%S')" > "$TEST_TECHNICAL_LOG_FILE"
GITHUB_ACTIONS=true
#PPL_CONTEXT="{{test-run}}"
PPL_CONTEXT="$(cat "$PROJECT_DIR/test/resources/github-context-sample-02.json")"
ENTANDO_OPT_REPO_BOM_URL="file://$TEST_WORK_DIR/6017ee92-ba94-40a2-b098-91b2c04f107b/entando-core-bom"

TEST_APPLY_DEFAULT_OVERRIDES() {
  EE_CLONE_URL="file://$TEST_WORK_DIR/6017ee92-ba94-40a2-b098-91b2c04f107b/entando-portal-ui"
}

test-cleanup() {
  [ -f "$TEST_WORK_DIR/.effimeral-test-dir" ] && rm -rf "$TEST_WORK_DIR"; 
}
trap test-cleanup exit

#~
#~ RUNS THE LIB TESTS
#~

_itmlst_contains "$EXECUTION_LABELS" "lib" && {
  # shellcheck disable=SC1091
  {
    . "$PROJECT_DIR/test/test_base.sh"
    . "$PROJECT_DIR/test/test_git.sh"
    . "$PROJECT_DIR/test/test_pom.sh"
    . "$PROJECT_DIR/test/github/test_github_tools.sh"
  }

  test_base || _failend
  test_git || _failend
  test_pom || _failend
  test_github_tools || _failend
}

#~
#~ RUNS THE MACRO TESTS
#~

_itmlst_contains "$EXECUTION_LABELS" "macro" && {
  # shellcheck disable=SC1091
  . "$PROJECT_DIR/test/github/test_github_full_pipeline.sh"

  test_github_full_pipeline || _failend
}

#~
#~ GOODBYE
#~

echo -e "\nTEST> tests execution completed.\n"

true
