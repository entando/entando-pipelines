#/bin/bash 

_require "lib/shared/vars.sh"
_require "lib/support/cli-utils.sh"

# Parses the pipelines environment and loads accordingly
# environment variables.
#
# Params:
# $1: the JSON environment provided by the "github" object
#
_github.parse_context() {
  local CTX="$1"
  local VAR_PREFIX="$2"
  _NONNULL CTX VAR_PREFIX
  
  #~
  #~ EXTRACTION
  #~

  local Q="["
  Q+=".repository,";
  Q+=".repositoryUrl,"
  Q+=".repository_owner,"
  Q+=".workflow,"
  Q+=".job,"
  Q+=".token,"
  Q+=".run_id,"
  Q+='.ref,'
  Q+='.sha,'
  Q+='.base_ref,'
  Q+='.head_ref,'
  Q+='.event_name,'
  Q+='.event.base_ref,'
  Q+=".event.repository.name,"
  Q+=".event.repository.clone_url,"
  Q+='.event.repository.statuses_url,'
  Q+='.event.repository.issues_url,'
  Q+='.event.repository.pulls_url,'
  Q+=".event.pull_request.html_url",
  Q+='.event.pull_request.number,'
  Q+='(.event.pull_request.title // "" |@base64),'
  Q+='.event.pull_request.head.sha'
  Q+="] | @csv"
  local RES
  RES="$(_github.must.jq "$Q" -r <<< "$CTX")"
  RES="${RES//\"/}"
  
  local _gh_tmp_REPO _gh_tmp_REPO_GIT_URL _gh_tmp_REPO_OWNER _gh_tmp_WORKFLOW _gh_tmp_JOB \
        _gh_tmp_TOKEN _gh_tmp_RUN_ID _gh_tmp_REF _gh_tmp_SHA _gh_tmp_BASE_REF _gh_tmp_HEAD_REF _gh_tmp_EVENT_NAME \
        _gh_tmp_EVENT_BASE_REF _gh_tmp_REPO_NAME _gh_tmp_CLONE_URL _gh_tmp_STATUSES_URL _gh_tmp_ISSUES_URL \
        _gh_tmp_PULLS_URL _gh_tmp_PR_HTML_URL _gh_tmp_PR_NUM _gh_tmp_PR_TITLE _gh_tmp_PR_SHA _gh_tmp_PR_LABELS
        
  # shellcheck disable=SC2034
  IFS=',' read -r \
    _gh_tmp_REPO \
    _gh_tmp_REPO_GIT_URL \
    _gh_tmp_REPO_OWNER \
    _gh_tmp_WORKFLOW \
    _gh_tmp_JOB \
    _gh_tmp_TOKEN \
    _gh_tmp_RUN_ID \
    _gh_tmp_REF \
    _gh_tmp_SHA \
    _gh_tmp_BASE_REF \
    _gh_tmp_HEAD_REF \
    _gh_tmp_EVENT_NAME \
    _gh_tmp_EVENT_BASE_REF \
    _gh_tmp_REPO_NAME \
    _gh_tmp_CLONE_URL \
    _gh_tmp_STATUSES_URL \
    _gh_tmp_ISSUES_URL \
    _gh_tmp_PULLS_URL \
    _gh_tmp_PR_HTML_URL \
    _gh_tmp_PR_NUM \
    _gh_tmp_PR_TITLE \
    _gh_tmp_PR_SHA \
  <<< "$RES"
  
  _gh_tmp_PR_TITLE="$(echo "$_gh_tmp_PR_TITLE" | base64 -d)"
  
  _gh_tmp_PR_LABELS="$(
    _github.must.jq ".event.pull_request.labels | map(.name)? | join(\",\")?" -r <<< "$CTX" 2> /dev/null
  )"

  #~
  #~ NORMALIZATION
  #~

  _vars.set_var "${VAR_PREFIX}_COMMIT_ID" "${_gh_tmp_PR_SHA:-$_gh_tmp_SHA}"
  _vars.set_var "${VAR_PREFIX}_PR_TITLE" "$_gh_tmp_PR_TITLE"
  _vars.set_var "${VAR_PREFIX}_CLONE_URL" "$_gh_tmp_CLONE_URL"
  
  case "$_gh_tmp_EVENT_NAME" in
    "pull_request") 
      _vars.set_var "${VAR_PREFIX}_BRANCH" "$_gh_tmp_HEAD_REF"
      _vars.set_var "${VAR_PREFIX}_BASE_BRANCH" "$_gh_tmp_BASE_REF"
    ;;
    *)
      _vars.set_var "${VAR_PREFIX}_BRANCH" "$_gh_tmp_HEAD_REF"
      _vars.set_var "${VAR_PREFIX}_BASE_BRANCH" "$_gh_tmp_BASE_REF"
    ;;
  esac 

  return 0
}

_github.must.jq() {
  jq "$@" || _FATAL -S 1 "Error parsing the json input"
}
