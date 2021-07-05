#!/bin/bash

# Updates the state of the current pipeline job
#
# Params:
# $1: the STATUS ID
# $2: the new status
# $3: the state context
# $4: the state description
#
# Expected Env:
# - EE_TOKEN
#
_ppl-job-update-status() {
  github-request POST "$EE_STATUSES_URL" \
    "{\"state\":\"$2\", \"description\": \"$3\", \"context\":\"$4\"}" \
    "sha" "$1" || true
}


# Adds a label to a PR
#
# Params:
# $1: the PR number
# $2: the label to add
#
_ppl-pr-add-label() {
  if github-request POST "$EE_ISSUES_URL/labels" "[\"$2\"]" "number" "$1"; then
    _log_d "Added label \"$2\" to pr #$1"
    return 0
  else
    _log_d "Failed adding label \"$2\" to pr #$1"
    return 1
  fi
}

# Rempves a label frpm a PR
#
# Params:
# $1: the PR number
# $2: the label to remove
#
_ppl-pr-remove-label() {
  if github-request DELETE "$EE_ISSUES_URL/labels/{label}" "" "number" "$1" "label" "$2"; then
    _log_d "Removed label \"$2\" from pr #$1"
    return 0
  else
    _log_d "Failed removing label \"$2\" from pr #$1"
    return 1
  fi
}

# Sets a persistent variable
#
# Params:
# $1: var name
# $1: var values
#
_ppl-set-persistent-var() {
  local var_name="$1"
  local var_value="$2"
  _log_t "> Setting persistent var: $var_name <= $var_value"
  echo "::set-output name=$var_name::$var_value"
}

_ppl-pr-has-label() {
  _ppl_must_have_env
  if _itmlst_contains "$EE_PR_LABELS" "$1"; then
    return 0
  else
    return 1
  fi
}


# Send a request to a github resource endpoint
#
# $1: VERB
# $2: DATA
# $3: URL
# $4: var_name
# $5: var_value
# $.. $4 and $5 repeated at will
#
# Expected Env:
# - EE_TOKEN
#
github-request() {
  _ppl_must_have_env
  local VERB="$1"; shift
  local URL="$1"; shift
  local DATA="$1"; shift

  _tpl_set_var URL "$URL" "$@"
  
  CMD="\"$VERB\" to \"$URL\" with \"${DATA:+-d "$DATA"}\""
  
  if [ "$TEST_EXECUTION" != "true" ] || [ "$VERB" = "GET" ]; then
    _log_t "Sending $CMD"
    
    
    local RESFILE STATUS
    RESFILE="$(mktemp)"
    
    STATUS="$(
      curl -sL -o "$RESFILE" -w "%{http_code}" "$URL" \
        -X "$VERB" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: token $EE_TOKEN" \
        ${DATA:+-d "$DATA"} \
      ;
    )"
    
    _log_on_level TRACE && cat "$RESFILE"
    rm "$RESFILE"
    
    if [ "${STATUS:0:1}" = "2" ]; then
      _log_t "GitHub Request succeed with status: $STATUS"
      return 0
    else
      _log_t "GitHub Request failed with status: $STATUS"
      return 1
    fi
  else
    echo "[HTS] $CMD" >> "$TEST_TECHNICAL_LOG_FILE"
    _log_t "Suppessed unsafe call due to TEST_EXECUTION: $CMD"
    true
  fi
}


# Parses the pipelines environment and loads accordingly
# environment variables.
#
# Params:
# $1: the JSON environment provided by the "github" object
#
_ppl-load-context() {
  NOOVR=false;[ "$1" = "--disable-overrides" ] && shift && NOOVR=true
  local PPL_CONTEXT="$1"
  _NONNULL PPL_CONTEXT
  
  #~
  #~ CONTEXT JSON
  #~
  
  [ "$PPL_CONTEXT" = "{{test-run}}" ] && {
    _log_t "Pipeline context was already loaded by test script"
    return 0
  }
  
  [ "$EE_PARSED_CONTEXT" = "$PPL_CONTEXT" ] && [ -n "$PPL_CONTEXT" ] && {
    _log_t "Pipeline context was already loaded"
    return 0
  }

  _pkg_get "jq" -c "jq"

  local Q="["
  Q+=".repository,"
  Q+=".workflow,"
  Q+=".job,"
  Q+=".event_name,"
  Q+=".token,"
  Q+='.ref,'
  Q+='.sha,'
  Q+='.base_ref,'
  Q+='.head_ref,'
  Q+=".event.repository.clone_url,"
  Q+='.event.repository.statuses_url,'
  Q+='.event.repository.issues_url,'
  Q+='.event.pull_request.number,'
  Q+='.event.pull_request.title'
  Q+="] | @csv"
  local RES
  RES="$(__jq "$Q" -r <<< "$PPL_CONTEXT")"
  RES="${RES//\"/}"
  # shellcheck disable=SC2034
  {
    IFS=',' read -r \
      EE_REPO \
      EE_WORKFLOW \
      EE_JOB \
      EE_EVENT \
      EE_TOKEN \
      EE_REF \
      EE_COMMIT_ID \
      EE_BASE_REF \
      EE_HEAD_REF \
      EE_CLONE_URL \
      EE_STATUSES_URL \
      EE_ISSUES_URL \
      EE_PR_NUM \
      EE_PR_TITLE \
    <<< "$RES"
    _extract_pr_title_prefix EE_PR_TITLE_PREFIX "$EE_PR_TITLE"
    EE_PARSED_CONTEXT="$PPL_CONTEXT"
    EE_PR_LABELS="$(
      __jq ".event.pull_request.labels | map(.name)? | join(\",\")?" -r <<< "$PPL_CONTEXT" 2> /dev/null
    )"
    EE_PR_LABELS=",${EE_PR_LABELS//\"/},"   # itmlst format
  }

  # TEST_EXECUTION OVERRIDES
  ! $NOOVR && {
    type TEST_APPLY_DEFAULT_OVERRIDES &>/dev/null && {
      TEST_APPLY_DEFAULT_OVERRIDES || true
    }
    type TEST_APPLY_OVERRIDES &>/dev/null && {
      TEST_APPLY_OVERRIDES || true
    }
  }
  
  return 0
}

_ppl_must_have_env() {
  [ -z "${EE_PARSED_CONTEXT}" ] && _FATAL "Please run _ppl-load-context"
}
