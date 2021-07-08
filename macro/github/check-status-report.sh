#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# PRINTS A GENERIC STATUS REPORT ABOUT THE PR
#
ppl--status-report() {
  # shellcheck disable=SC2034
  (
    START_MACRO "STATUS-REPORT" "$@"
    
    IN="$EE_REPO: $EE_WORKFLOW/$EE_JOB ($EE_EVENT)"
    PR_MERGE_TARGET_BRANCH="$EE_BASE_REF"
    PR_BRANCH="$EE_HEAD_REF"
    PR_NUMBER="$EE_PR_NUM"
    PR_LABELS="${EE_PR_LABELS:1:-1}"
    PR_TITLE="$EE_PR_TITLE"
    
    if [ -n "$PR_TITLE" ]; then
      _pp \
        IN \
        EE_REF \
        EE_COMMIT_ID \
        EE_CLONE_URL \
        PR_TITLE \
        PR_NUMBER \
        PR_LABELS \
        PR_BRANCH \
        PR_MERGE_TARGET_BRANCH \
      ;
    else
      _pp \
        IN \
        EE_REF \
        EE_COMMIT_ID \
        EE_CLONE_URL \
      ;
    fi
  )
}

ppl--pr-status-report() {
  ppl--status-report "$@"
}
