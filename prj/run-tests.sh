#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC2046
cd "$SCRIPT_DIR/.." || { echo "Unable to enter the script dir"; exit 99; }

[ "$1" = "--with-docker" ] && {
  shift
  docker build -t entando-pipelines . &&  docker run -it --rm entando-pipelines prj/run-tests.sh "$@"
  exit "$?"
}

. "./lib/debug.sh"
. "./lib/base.sh"
. "./lib/misc.sh"     # only for the itmlst functions

ENTANDO_OPT_LOG_LEVEL="${ENTANDO_OPT_LOG_LEVEL:-DEBUG}"
# Composes the execution labels "itmlst"
EXECUTION_LABELS=""
ENTANDO_OPT_DATA_REPO="{{test-run}}"
_itmlst_fill EXECUTION_LABELS "$@"
_itmlst_empty "$EXECUTION_LABELS" && _itmlst_fill EXECUTION_LABELS "lib" "macro"

echo -e "\nTEST> Execution labels: ${EXECUTION_LABELS}\n"

_failend() { EC="$?"; echo -e "\nTEST> TEST FAILURE DETECTED (EXITCODE: $EC)\n"; exit "$EC"; }

#~
#~ SETUP TEST ENVIRONMENT
#~

TEST.RESET_TLOG() {
  echo "[REM] STARTED AT $(date +'%Y-%m-%d %H-%M-%S')" > "$TEST__TECHNICAL_LOG_FILE"
}

# shellcheck disable=SC1091
{
  PROJECT_DIR="$PWD"
  . "./lib/base.sh"
  cd "./test" || { echo "Error entering the test dir"; exit 2; }
  TEST__WORK_DIR="$(mktemp -d)"
  cd "$TEST__WORK_DIR"
  touch "$TEST__WORK_DIR/.effimeral-test-dir"
  tar xfz "$PROJECT_DIR/test/resources/repo-mocks.tgz" "repo-mocks"
  cp -ra "$PROJECT_DIR/test/resources/" "./resources"
}

{
  TEST__EXECUTION=true
  ENTANDO_OPT_SHELL_ON_TEST_ASSERT=${ENTANDO_OPT_SHELL_ON_TEST_ASSERT:-false}
  GITHUB_ACTIONS=true
  PPL_CONTEXT="{{test-run}}"
  PPL_PARSED_CONTEXT=true

  TEST__TECHNICAL_LOG_FILE="$TEST__WORK_DIR/ttlog"
}

[ -f "$PROJECT_DIR/test/_test-base.sh" ] && . "$PROJECT_DIR/test/_test-base.sh"
type TEST__BEFORE_RUN &>/dev/null && TEST__BEFORE_RUN

test-cleanup() {
  [ -f "$TEST__WORK_DIR/.effimeral-test-dir" ] && rm -rf "$TEST__WORK_DIR";
}
trap test-cleanup exit

[ -t 0 ] && IN_TTY=false || IN_TTY=true


TEST.RESET_STATE() {
  TEST__EXPECTED_ERROR=""
  TEST__APPLY_DEFAULT_OVERRIDES() {
    PPL_CLONE_URL="file://$TEST__WORK_DIR/repo-mocks/entando-test-repo-base"
  }
  
  TEST.RESET_TLOG
  
  ENTANDO_OPT_LOG_LEVEL="${ENTANDO_OPT_LOG_LEVEL:-DEBUG}"
  
  [ -z "$ENTANDO_OPT_REPO_BOM_URL" ] && \
    ENTANDO_OPT_REPO_BOM_URL="file://$TEST__WORK_DIR/repo-mocks/entando-core-bom"

  ENTANDO_OPT_REPO_BOM_MAIN_BRANCH="${ENTANDO_OPT_REPO_BOM_MAIN_BRANCH:-develop}"

  if [ "$ENTANDO_OPT_SUDO" != "-" ]; then
    ENTANDO_OPT_SUDO="${ENTANDO_OPT_SUDO:-"sudo"}"
  else
    ENTANDO_OPT_SUDO=""
  fi
}

#~
#~ RUNS THE TESTS
#~
{
  for label in ${EXECUTION_LABELS//,/ }; do
    while read -r file; do
      (
        . "$file"

        while read -r fn; do
          [[ "${fn:0:6}" = "#TEST:" || "${fn:0:2}" = "--" ]] && continue
          echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
          echo 'TEST> TEST FUNCTION "'"$fn"'"'

          TEST.RESET_STATE

          ($fn) || _exit "$?"
        done < <(grep  -A 1 "#TEST:$label" "$file" | sed 's/().*//')
      ) || _failend
    done  < <(grep -lr "#TEST:$label" "$PROJECT_DIR/test")
  done
}

#~
#~ GOODBYE
#~

echo -e "\nTEST> tests execution completed.\n"

true
