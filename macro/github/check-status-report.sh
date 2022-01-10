#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# PRINTS A GENERIC STATUS REPORT ABOUT CURRENT RUN
#
ppl--status-report() {
  # shellcheck disable=SC2034
  (
    START_MACRO "STATUS-REPORT" "$@"
    
    IN="$PPL_REPO: $PPL_WORKFLOW/$PPL_JOB ($PPL_EVENT)"
    PR_MERGE_TARGET_BRANCH="$PPL_BASE_REF"
    PR_BRANCH="$PPL_HEAD_REF"
    PR_NUMBER="$PPL_PR_NUM"
    PR_LABELS="$PPL_PR_LABELS"
    PR_TITLE="$PPL_PR_TITLE"
    LINK="$PPL_PR_HTML_URL"
    FEATURES="$PPL_FEATURES"
    CUSTOM_ENV="$ENTANDO_OPT_CUSTOM_ENV"
    OKD_LOGIN_ENABLED="$ENTANDO_OPT_OKD_LOGIN"
    [ "${FEATURES:0:1}" = "," ] && FEATURES="${FEATURES:1}"
    [ "${FEATURES: -1}" = "," ] && FEATURES="${FEATURES:0:-1}"
    
    if [ -n "$PR_TITLE" ]; then
      _pp \
        IN \
        LINK \
        FEATURES \
        OKD_LOGIN_ENABLED \
        CUSTOM_ENV \
        PPL_REF \
        PPL_COMMIT_ID \
        PPL_CLONE_URL \
        PR_TITLE \
        PR_NUMBER \
        PR_LABELS \
        PR_BRANCH \
        PR_MERGE_TARGET_BRANCH \
        PPL_NEAREST_WELL_KNOWN_BRANCH \
        PPL_BRANCHING_TYPE \
        PPL_EPIC_NAME \
      ;
    else
      _pp \
        IN \
        FEATURES \
        OKD_LOGIN_ENABLED \
        CUSTOM_ENV \
        PPL_REF \
        PPL_COMMIT_ID \
        PPL_CLONE_URL \
        PPL_NEAREST_WELL_KNOWN_BRANCH \
        PPL_BRANCHING_TYPE \
        PPL_EPIC_NAME \
      ;
    fi
  )
}

ppl--pr-status-report() {
  ppl--status-report "$@"
}
