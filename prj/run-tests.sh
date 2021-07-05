#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC2046
cd "$SCRIPT_DIR/.." || { echo "Unable to enter the script dir"; exit 99; }

[ "$1" = "--with-docker" ] && {
  shift
  docker build -t entando-pipelines . &&  docker run -it --rm entando-pipelines prj/run-tests.sh "$@"
  exit "$?"
}

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
#ENTANDO_CORE_BOM_REPO_URL="${ENTANDO_OPT_REPO_BOM_URL}"
ENTANDO_OPT_REPO_BOM_MASTER_BRANCH="${ENTANDO_OPT_REPO_BOM_MASTER_BRANCH:-master}"

TEST_APPLY_DEFAULT_OVERRIDES() {
  EE_CLONE_URL="file://$TEST_WORK_DIR/6017ee92-ba94-40a2-b098-91b2c04f107b/entando-portal-ui"
}

test-cleanup() {
  [ -f "$TEST_WORK_DIR/.effimeral-test-dir" ] && rm -rf "$TEST_WORK_DIR";
}
trap test-cleanup exit

#~
#~ RUNS THE TESTS
#~
for label in ${EXECUTION_LABELS//,/ }; do
  while read -r file; do
    (
      . "$file"

      while read -r fn; do
        echo '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
        echo 'TEST> TEST FILE "'"$fn"'"'
        ($fn) || exit "$?"
      done < <(grep  -A 1 "#TEST:$label" "$file" | tail -1 | sed 's/().*//')
    ) || _failend
  done  < <(grep -lr "#TEST:$label" "$PROJECT_DIR/test")
done

#~
#~ GOODBYE
#~

echo -e "\nTEST> tests execution completed.\n"

true
