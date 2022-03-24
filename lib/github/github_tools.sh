#!/bin/bash

# Query informations about the current PR
# $1  the receiver var of the value
# $2  the PR value to get
# $.. $1 & $2 repeated at will
#
_ppl-query-pr-info() {
  if ! $TEST__EXECUTION; then
    github-request --set RES GET "$PPL_PULLS_URL" "" "number" "$PPL_PR_NUM"
    Q="["; for ((i=2;i<=$#;i+=2)); do Q+=".${!i}"; done; Q+="]"
    i=1
    while IFS= read -r var; do
      [[ "${var}" = "[" || "${var}" = "]" ]] && continue
      [[ "${var: -1}" = "," ]] && var="${var::-1}"
      [[ "${var:0:3}" = "  \"" ]] && {
        var="${var:3:-1}"
        var="${var//\\\"/\"}"
      }
      _set_var "${!i}" "$var"
    done < <(__jq "$Q" --indent 2 <<< "$RES")
  else
    TEST__EXECUTION._ppl-query-pr-info "$@"
  fi
}

TEST__EXECUTION._ppl-query-pr-info() {
  for ((i=2;i<=$#;i+=2)); do 
    if [ "${!i}" = "title" ]; then
      ((i--))
      _set_var "${!i}" "$PPL_PR_TITLE"
    fi
  done
}

# Updates the state of the current pipeline job
#
# Params:
# $1: the STATUS ID
# $2: the new status
# $3: the state context
# $4: the state description
#
# Expected Env:
# - PPL_TOKEN
#
_ppl-job-update-status() {
  github-request POST "$PPL_STATUSES_URL" \
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
  if github-request POST "$PPL_ISSUES_URL/labels" "[\"$2\"]" "number" "$1"; then
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
  if github-request DELETE "$PPL_ISSUES_URL/labels/{label}" "" "number" "$1" "label" "$2"; then
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
# $2: var value
#
_ppl-set-persistent-var() {
  local var_name="$1"
  local var_value="$2"
  _log_t "> Setting persistent var: $var_name <= $var_value"
  echo "::set-output name=$var_name::$var_value"
}

# Set the current macro error indicator and the current exit status with the value provided
#
_ppl-set-return-var() {
  [ "$1" -ne 0 ] && {
    #~ ON ERROR
    _ppl-set-persistent-var "ERROR_${PPL_CURRENT_MACRO}" true
  }
  return "$1"
}

# Tells if the PR has a label given its number
#
_ppl-pr-has-label() {
  _ppl_must_have_env
  if _itmlst_contains "$PPL_PR_LABELS" "$1"; then
    return 0
  else
    return 1
  fi
}


# Send a request to a github resource endpoint
#
# $1: VERB
# $2: URL
# $3: DATA
# $4: var_name
# $5: var_value
# $.. $4 and $5 repeated at will
#
# Expected Env:
# - PPL_TOKEN
#
github-request() {
  local TOKEN="$PPL_TOKEN";[ "$1" = "--no-auth" ] && { TOKEN=""; shift; }
  local SET=false VAR;[ "$1" = "--set" ] && { SET=true; shift; VAR="$1"; shift; }
  _ppl_must_have_env
  local VERB="$1"; shift
  local URL="$1"; shift
  local DATA="$1"; shift

  _tpl_set_var URL "$URL" "$@"
  
  CMD="\"$VERB\" to \"$URL\" with \"${DATA:+-d "$DATA"}\""
  
  if [ "$TEST__EXECUTION" != "true" ] || [ "$VERB" = "GET" ]; then
    _log_t "Sending $CMD"
    
    local RESFILE STATUS
    RESFILE="$(mktemp)"
    
    STATUS="$(
      curl -sL -o "$RESFILE" -w "%{http_code}" "$URL" \
        -X "$VERB" \
        -H "Accept: application/vnd.github.v3+json" \
        ${TOKEN:+-H "Authorization: token $TOKEN"} \
        ${DATA:+-d "$DATA"} \
      ;
    )"
    
    _log_on_level TRACE && cat "$RESFILE"
    
    $SET && _set_var "$VAR" "$(cat "$RESFILE")"
    rm "$RESFILE"
    
    if [ "${STATUS:0:1}" = "2" ]; then
      _log_t "GitHub Request succeed with status: $STATUS"
      return 0
    else
      _log_w "GitHub Request \"$VERB\" to \"$URL\" failed with status: $STATUS"
      return 1
    fi
  else
    echo "[HTS] $CMD" >> "$TEST__TECHNICAL_LOG_FILE"
    _log_t "Suppessed unsafe call due to TEST__EXECUTION: $CMD"
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
  local CTX="$1"
  _NONNULL CTX
  
  #~
  #~ CONTEXT JSON
  #~

  [ "$CTX" = "{{test-run}}" ] && {
    _log_t "Pipeline context was already loaded by test script"
    # TEST__EXECUTION OVERRIDES
    _ppl-apply-overrides
    return 0
  }

  [ "$PPL_PARSED_CONTEXT" = "$CTX" ] && [ -n "$CTX" ] && {
    _log_t "Pipeline context was already loaded"
    # TEST__EXECUTION OVERRIDES
    _ppl-apply-overrides
    return 0
  }

  _pkg_get "jq"

  local Q="["
  Q+=".repository,"
  Q+=".repositoryUrl,"
  Q+=".workflow,"
  Q+=".job,"
  Q+=".event_name,"
  Q+=".token,"
  Q+=".run_id,"
  Q+='.ref,'
  Q+='.sha,'
  Q+='.base_ref,'
  Q+='.head_ref,'
  Q+=".event.repository.name,"
  Q+=".event.repository.clone_url,"
  Q+='.event.repository.statuses_url,'
  Q+='.event.repository.issues_url,'
  Q+='.event.repository.pulls_url,'
  Q+=".event.pull_request.html_url",
  Q+='.event.pull_request.number,'
  Q+='(.event.pull_request.title|@base64),'
  Q+='.event.pull_request.head.sha'
  Q+="] | @csv"
  local RES
  RES="$(__jq "$Q" -r <<< "$CTX")"
  RES="${RES//\"/}"
  
  # shellcheck disable=SC2034
  {
    IFS=',' read -r \
      PPL_REPO \
      PPL_REPO_GIT_URL \
      PPL_WORKFLOW \
      PPL_JOB \
      PPL_EVENT \
      PPL_TOKEN \
      PPL_RUN_ID \
      PPL_REF \
      PPL_SHA \
      PPL_BASE_REF \
      PPL_HEAD_REF \
      PPL_REPO_NAME \
      PPL_CLONE_URL \
      PPL_STATUSES_URL \
      PPL_ISSUES_URL \
      PPL_PULLS_URL \
      PPL_PR_HTML_URL \
      PPL_PR_NUM \
      PPL_PR_TITLE \
      PPL_PR_SHA \
    <<< "$RES"

    PPL_PR_TITLE="$(echo "$PPL_PR_TITLE" | base64 -d)"
    [ "$PPL_PR_TITLE" = "null" ] && PPL_PR_TITLE=""

    # TEST__EXECUTION OVERRIDES
    _ppl-apply-overrides
    
    _extract_pr_title_prefix PPL_PR_TITLE_PREFIX "$PPL_PR_TITLE"
    
    PPL_PARSED_CONTEXT="$CTX"
    PPL_PR_LABELS="$(
      __jq ".event.pull_request.labels | map(.name)? | join(\",\")?" -r <<< "$CTX" 2> /dev/null
    )"
    PPL_PR_LABELS="${PPL_PR_LABELS//\"/}"
    PPL_REF_NAME="${PPL_REF##*/}"
  }
  
  PPL_COMMIT_ID="${PPL_PR_SHA:-$PPL_SHA}"
  
  return 0
}

_ppl-apply-overrides() {
  ! $NOOVR && {
    type TEST__APPLY_DEFAULT_OVERRIDES &>/dev/null && {
      TEST__APPLY_DEFAULT_OVERRIDES || true
    }
    type TEST__APPLY_OVERRIDES &>/dev/null && {
      TEST__APPLY_OVERRIDES || true
    }
  }
}

_ppl_must_have_env() {
  [ -z "${PPL_PARSED_CONTEXT}" ] && _FATAL "Please run _ppl-load-context"
}

# Submits to the current PR/commit a review with a request for change
#
# Params:
# $1  the request message
#
# ref:
# - https://docs.github.com/en/rest/reference/pulls#create-a-review-comment-for-a-pull-request
# - https://docs.github.com/en/rest/reference/pulls#submit-a-review-for-a-pull-request
#
_ppl-pr-request-change() {
  if ! $TEST__EXECUTION; then
    local data="{"
    data+="\"commit_id\":\"$PPL_COMMIT_ID\","
    data+="\"body\":$(_str_quote "$1")"
    data+="}"
    
    github-request --set RES POST "$PPL_PULLS_URL/reviews" "$data" "number" "$PPL_PR_NUM"
      
    local review_id=$(echo "$RES" | jq '.id' -r)
    local data="{\"event\":\"REQUEST_CHANGES\"}"
    github-request --set RES POST "$PPL_PULLS_URL/reviews/$review_id/events" "$data" "number" "$PPL_PR_NUM"
  fi  
}

# Submits to the given PR/commit a comment
#
# Params:
# $1  the PR number
# $2  the comment text
#
_ppl-pr-submit-comment() {
  if ! $TEST__EXECUTION; then
    local data="{"
    data+="\"body\":$(_str_quote "$2")"
    data+="}"
    
    github-request POST "$PPL_ISSUES_URL/comments" "$data" "number" "$1"
  fi  
}


# Allows grouping togheter a set of lines in a collapsable element
#
# Params:
# $1    action: "start" or "stop"
# [$2]  the group title title, only required if action is "start"
#
_ppl-stdout-group() {
  case "$1" in
    start) 
      [ -z "$2" ] && _FATAL "Please provide the group title"
      echo "::group::$2"
      ;;
    stop)
      echo "::endgroup::"
      ;;
    *) _FATAL "Invalid action \"$1\" provided";;
  esac
}


# Prints a file content into a set of groups
#
# Params:
# $1    file pathname
# $2    group max size
# $3    file description
#
_ppl-print-file-paginated() {
  local n=1 ln
  _ppl-stdout-group start "FULL $3 from line $n"
  while read -r ln; do
    if [[ "$n" -gt 1 && "$((n % $2))" = 1 ]]; then
      _ppl-stdout-group stop
      _ppl-stdout-group start "FULL $3 from line $n"
    fi
    echo "$ln"
    ((n++))
  done <"$1"
  _ppl-stdout-group stop
}

# Create or starts the creation of the PR
#
# Params:
# $1: PR title
# $2: base branch
# $3: PR branch
# [$4]  optional comma-delimited reviewers
#
_ppl_create_pr() {
  gh pr create --title "$1" --base "$2" --head "$3" ${4:+--reviewer "$4"} --web
}
