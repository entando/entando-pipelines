#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# PRINTS A GENERIC STATUS REPORT ABOUT THE PR
#
ppl--pr-status-report() {
  # shellcheck disable=SC2034
  (
    START_MACRO "PR-STATUS-REPORT" "$PPL_CONTEXT"
    
    PR_MERGE_TARGET_BRANCH="$EE_BASE_REF"
    PR_BRANCH="$EE_HEAD_REF"
    PR_LATEST_COMMIT_ID="$EE_COMMIT_ID"
    PR_NUMBER="$EE_PR_NUM"
    PR_LABELS="${EE_PR_LABELS:1:-1}"
    PR_TITLE="$EE_PR_TITLE"
    
    _pp \
      PR_TITLE \
      PR_NUMBER \
      PR_LABELS \
      PR_BRANCH \
      PR_MERGE_TARGET_BRANCH \
      PR_LATEST_COMMIT_ID \
    ;
  )
}
