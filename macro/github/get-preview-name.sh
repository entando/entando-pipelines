#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# COMPOSES THE NAME OF THE PREVIEW TAG RESPECTING THE FORMAT p<PREFIX>-<PRNUM> (e.g. pENG-0001-142)
#
# Business Rules:
# - If the PR title is composed by multiple ticket id, use only the last one
#
# Params:
# $1: the folder containing the related repo/branch
# $2: the format rules to respect or nothing for the default
#
ppl--get-preview-name() {
  (
    set +e
    START_MACRO "GET-PREVIEW-NAME" "$PPL_CONTEXT"

    local TICKET_ID_REGEX="[A-Z]{2,5}-[0-9]{1,5}"
    local REGEX_H="^${TICKET_ID_REGEX}\/${TICKET_ID_REGEX}"

    local _ticketIdList_ _ticketId_
    IFS=' ' read -r _ticketIdList_ _ <<< "$EE_PR_TITLE"

    if [[ "$_ticketIdList_" =~ $REGEX_H ]]; then
      IFS='/' read -r _ _ticketId_ <<< "$_ticketIdList_"
    else
      _ticketId_="$_ticketIdList_"
    fi

    echo "p$_ticketId_-PR$EE_PR_NUM"
  )
}
