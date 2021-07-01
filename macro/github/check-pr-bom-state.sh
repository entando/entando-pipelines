#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# EXECUTES THE BOM ALIGNMENT CHECK ABOUT THE CURRENT PR
#
# Business Rules:
# - The PR bom should be aligned with the latest published BOM
#
# Params:
# $1: the folder containing the related repo/branch
#
ppl--check-pr-bom-state() {
  (
    START_MACRO "CHECK-PR-BOM" "$PPL_CONTEXT"

    _pkg_get "xmlstarlet" -c "xmlstarlet"

    local repoFolder="$1"
    
    __cd "$repoFolder"
    __exist -f "pom.xml"

    # ~
    # ~ GATERING INFO - BOM OF THE PR
    # ~
    local prBomVersion
    _pom_get_depman_artifact_version prBomVersion "pom.xml" "entando-core-bom"

    # ~
    # ~ GATERING INFO - THE ACTUAL LATEST BOM VERSION
    # ~
    local latestBomVersion
    _ppl_query_latest_bom_version latestBomVersion "$ENTANDO_OPT_REPO_BOM_URL"

    # ~
    # ~ COMPARISON
    # ~

    _log_d "> THE BOM VERSION REFERENCED ON PR IS: $prBomVersion"
    _log_d "> THE LATEST BOM VERSION PUBLISHED IS: $latestBomVersion"

    if [ "$prBomVersion" != "$latestBomVersion" ]; then
      _ppl-job-update-status "$STATUSES_URL" "$EE_COMMIT_ID" "failure" "Failed" "BOM misalignment error"
      local MSG="The BOM version requested by this PR is not aligned with"
      MSG+="the latest BOM version released ($prBomVersion != $latestBomVersion)"
      _FATAL "$MSG"
    else
      _log_i "BOM check ok ($prBomVersion = $latestBomVersion)"
    fi
  )
}
