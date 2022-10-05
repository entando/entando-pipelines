#!/bin/bash

DEFAULT_REPO=""
NO_TOPIC_BRANCH=false
NO_BANNER=false

DEFAULT_MAIN_REPO="https://github.com/entando-k8s/entando-de-app"
DEFAULT_BOM_REPO="https://github.com/entando/entando-core-bom"
DEFAULT_BOM_BRANCH="develop"

_configure_common_arg_flags() {
  ARGS_FLAGS=(--reuse --push --push-force --push-force-unconditional --use-existing-branch --pull --fetch --force-new-branch)
}

_safe_common_repo_args() {
  ARG_PULL=false
  ARG_PUSH=false
  ARG_FORCENEWBRANCH=false
  ARG_EXISTINGBRANCH=true
  FORCE_OPT=""
}

_read_common_repo_args() {
  FORCE_OPT=""; FORCE_PUSH=false;
  _get_arg -m ARG_BASE --base "develop"
  _get_arg ARG_TOPIC_BRANCH --branch
  _get_arg ARG_REUSE --reuse
  _get_arg ARG_PULL --pull
  _get_arg ARG_FETCH --fetch
  _get_arg ARG_PUSH --push
  _get_arg ARG_FORCENEWBRANCH --force-new-branch; $FORCENEWBRANCH
  _get_arg ARG_EXISTINGBRANCH --use-existing-branch; $ARG_EXISTINGBRANCH && FORCENEWBRANCH=false
  _get_arg ARG_TMP --push-force; $ARG_TMP && { FORCE_PUSH=true; ARG_PUSH=true; FORCE_OPT="--force-with-lease"; }
  _get_arg ARG_TMP --push-force-unconditional; $ARG_TMP && { FORCE_PUSH=true; ARG_PUSH=true; FORCE_OPT="--force"; }
  _get_arg ARG_MESSAGE --msg
  _get_arg ARG_DIALECT --dialect
  _get_arg ENTANDO_OPT_LOG_LEVEL --log-level
  _get_arg GIT_USER_NAME --git-user-name
  _get_arg GIT_USER_EMAIL --git-user-email
  _get_arg ARG_WORK_AREA --work-dir
}

_print_args() {
  _log_on_level TRACE && {
    _pp ARG_REUSE ARG_PULL ARG_FETCH ARG_PUSH ARG_FORCENEWBRANCH FORCE_OPT ARG_EXISTINGBRANCH \
        ARG_MESSAGE ARG_DIALECT ENTANDO_OPT_LOG_LEVEL GIT_USER_NAME GIT_USER_EMAIL
  }
}

_setup_work_area() {
  if [ -n "$ARG_WORK_AREA" ]; then
    _log_d "Initializing work area (persistent)"
    __cd "$ARG_WORK_AREA"
  else
    _log_d "Initializing work area (temporary)"
    __mk_tmp_work_area --and-enter
  fi
}

_custom_status_handler() {
  local action="$1"; shift
  local status="$1"; shift
  "ppl--$action" "$status" "$@"
  
  [[ "$status" = "exec" && -z "$(git status --porcelain)" ]] && {
    NOCHANGE=true
    _log_d "No change detected from \"ppl--$action\""
  }
}

_setup_local_clone() {
  local DIR="${ARG_REPO##*/}"

  if ! $ARG_REUSE; then
    [ -d "$DIR" ] && _FATAL "Repo clone already present on the work-area"
    _log_d "Cloning the repo \"$ARG_REPO\""

    _git_full_clone "$ARG_REPO" "$DIR" "" "${PPL_TOKEN_OVERRIDE:-$PPL_TOKEN}"
    __cd "$DIR"
  else
    _log_d "Reusing existing local clone \"$DIR\""
    __cd "$DIR"
    $ARG_FETCH && {
      _log_d "Updating local clone \"$DIR\""
      __git fetch -q
    }
  fi
  
  _use_existing_branch "$ARG_BASE"
}

_use_existing_branch() {
  git checkout "$ARG_BASE" origin "$1" &> /dev/null
}

_force_new_branch_if_requested() {
  $ARG_FORCENEWBRANCH && {
    __git reset --hard HEAD
    _checkout_base --must "$ARG_BASE"
    __git pull
    git branch -D "$ARG_TOPIC_BRANCH" &>/dev/null
  }
}

_new_topic_branch() {
  _checkout_base --must "$ARG_BASE"
  [ -n "$ARG_TOPIC_BRANCH" ] && {
    if $ARG_EXISTINGBRANCH; then
      _log_d "Checking out existing branch \"$ARG_TOPIC_BRANCH\""
      __git checkout "$ARG_TOPIC_BRANCH"
    else
      _log_d "Creating the new branch \"$ARG_TOPIC_BRANCH\""
      __git checkout -b "$ARG_TOPIC_BRANCH"
    fi
  }
}

_checkout_base() {
  local MUST=false; [ "$1" = "--must" ] && { MUST=true; shift; }
  git checkout "$1" &> /dev/null
  $MUST && [[ "$(git rev-parse --abbrev-ref HEAD)" != "$1" ]] && {
    _FATAL "Unsupported repository type (BASE != \"$1\")"
  }
}

_commit_if_necessary() {
  if ! $NOCHANGE; then
    _git_auto_setup_commit_config
    __git add -A .
    git status
    local GIT_MESSAGE="$ARG_MESSAGE"
    [ -z "$GIT_MESSAGE" ] && GIT_MESSAGE="$AUTO_MESSAGE"
    _NONNULL GIT_MESSAGE
    __git commit -m "$GIT_MESSAGE"
  fi
}

_push_if_necessary() {
  if ! $NOCHANGE || $FORCE_PUSH; then
    if $ARG_PUSH; then
      [ -z "$ARG_TOPIC_BRANCH" ] && _FATAL "PR BRANCH required for push"
      _log_d "Pushing the branch \"$ARG_TOPIC_BRANCH\""
      __git push $FORCE_OPT --set-upstream origin "$ARG_TOPIC_BRANCH"
    fi
  fi
}

_checkout_topic_branch() {
  local action="$1";shift

  if $ARG_REUSE && ! $ARG_FORCENEWBRANCH ; then
    git checkout "$ARG_TOPIC_BRANCH" 2>/dev/null || true
  fi

  if [[ "$ARG_REUSE" = "true" && "$(git rev-parse --abbrev-ref HEAD)" = "$ARG_TOPIC_BRANCH" ]]; then
    # REUSING BRANCH
    _log_d "Reusing existing topic branch: \"$ARG_TOPIC_BRANCH\""
    $ARG_PULL && __git pull -q --set-upstream origin "$ARG_TOPIC_BRANCH"
  else
    # CREATE BRANCH
    git checkout "$ARG_BASE" &> /dev/null
    _custom_status_handler "$action" ready "$@"
    _new_topic_branch
  fi
}

_repo_action() {
  local LPWD="$PWD"
  
  local action="$1";shift
  ARG_REPO="$1"
  #~ INIT PHASE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  _setup_work_area
  _custom_status_handler "$action" init "$@"
  
  #~ READY PHASE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  _setup_local_clone
  
   [[ ! $NO_TOPIC_BRANCH && -z "$ARG_TOPIC_BRANCH" ]] && _FATAL "PR BRANCH required"
  _force_new_branch_if_requested
  _checkout_topic_branch "$action"
  
  #~ EXEC PHASE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  _log_d "Executing the tasks"
  
  NOCHANGE=false
  _custom_status_handler "$action" exec "$@"
  _commit_if_necessary
  _push_if_necessary
  
  __cd "$LPWD"
}

_for_each_batch_item() {
  local batch="$1";shift
  local action="$1";shift
  local cmd="$1";shift
  local batch_file="$SCRIPT_DIR/cli-tools/_repo/$batch.list"
  __exist -f "$batch_file"
  while read -r item; do
    _read_common_repo_args
    
    case "${item:0:1}" in
      " "|""|"#")
        ;;
      *)
        ! $NO_BANNER && _print_banner "$action => $item"
        _print_args
        local LPWD="$PWD"
        "$cmd" "$action" "$item"
        __cd "$LPWD"
        ;;
    esac
  done <"$batch_file"
}


_parse_args() {
  #~ Common params
  _configure_common_arg_flags
  PARSE_ARGS -q "$@"
  _get_arg -m ARG_ACTION 1
  _shift_positional_args 1
  _read_common_repo_args
  _get_arg -m ARG_BATCH_FILE --batch
  
  #~ Action related params
  _custom_status_handler "$ARG_ACTION" pre "$@"
  PARSE_ARGS "$@"
}
