#!/bin/bash

# Load the pipeline configuration from the pipelines data repository
#
_ppl_clone_and_configure_data_repo() {
  if [ "${ENTANDO_OPT_DATA_REPO:0:3}" = "###" ]; then
    ENTANDO_OPT_DATA_REPO="${ENTANDO_OPT_DATA_REPO:3}"
  fi
  
  [ -z "$ENTANDO_OPT_DATA_REPO" ] && return 0
  [ "$ENTANDO_OPT_DATA_REPO" = "{{test-run}}" ] && return 0
  
  # GATHERING OF BUILT REPO INFORMATION
  local pr_title_qualifier=""
  pr_title_qualifier="$(
    RES=""
    if [ "$PPL_NO_REPO" ]; then
      _ppl_determine_qualifier --skip-if-merge RES 1>&2
    else
      __ppl_enter_local_clone_dir 1>&2
      _ppl_determine_qualifier RES 1>&2
    fi
    echo "$RES"
  )"
  
  local saved_pwd="$PWD"
  
  # SWITCHING TO THE DATA REPO
  local data_repo_dir="entando-data-repo"
  local first_step=false
  
  # EXTACT THE DATA REPO DIR
  __cd "$HOME"
  if [ ! -d "$data_repo_dir" ]; then
    _git_full_clone --shallow "$ENTANDO_OPT_DATA_REPO" "$data_repo_dir" "" "${ENTANDO_OPT_DATA_REPO_TOKEN}"
    first_step=true
  fi
  
  local branch_latest_indicator="${PPL_NEAREST_MAIN_BRANCH}-latest"
  
  __cd "$data_repo_dir"
  DATA_REPO_PATH="$PWD"
  ENTANDO_DATA_REPO_REF=""
  
  # Extract by project property
  if [ -z "$ENTANDO_DATA_REPO_REF" ]; then
    if [ "$PPL_NO_REPO" != "true" ]; then
      [ -z "$PPL_LOCAL_CLONE_DIR" ] && _FATAL "Unable to determine the local clone location"

      ENTANDO_DATA_REPO_REF="$(_extract_entando_prj_pipeline_config "$saved_pwd")"
      cfg.git_fetch_origin "$ENTANDO_DATA_REPO_REF"
    fi
  fi
  
  # Extract by STORY AFFINITY
  if [ -z "$ENTANDO_DATA_REPO_REF" ]; then
    if [ -n "$pr_title_qualifier" ]; then
      cfg.git_fetch_origin "$pr_title_qualifier"
      if [ -n "$pr_title_qualifier" ] && _git_ref_exists "$pr_title_qualifier" >/dev/null 2>&1; then
        ENTANDO_DATA_REPO_REF="$pr_title_qualifier"
      fi
    fi
  fi
  
  # Extract by BRANCH AFFINITY - TAG
  if [ -z "$ENTANDO_DATA_REPO_REF" ]; then
    cfg.git_fetch_origin "$branch_latest_indicator"
    if _git_ref_exists "$branch_latest_indicator" >/dev/null 2>&1; then
      ENTANDO_DATA_REPO_REF="$branch_latest_indicator"
    fi
  fi

  # Extract by BRANCH AFFINITY - BRANCH
  if [ -z "$ENTANDO_DATA_REPO_REF" ]; then
    ENTANDO_DATA_REPO_REF="${PPL_NEAREST_MAIN_BRANCH}"
    cfg.git_fetch_origin "$ENTANDO_DATA_REPO_REF"
  fi

  # ~
  _log_d "Selected data-repo ref \"${ENTANDO_DATA_REPO_REF}\""
  
  git checkout "${ENTANDO_DATA_REPO_REF}" &>/dev/null
  if [ "$?" != 0 ]; then
    if "$PPL_NO_REPO"; then
      _log_i "There is no configuration with name \"${ENTANDO_DATA_REPO_REF}\", falling back to the default config"
    else
      _FATAL "Unable to extract the pipeline configuration \"${ENTANDO_DATA_REPO_REF}\""
    fi
  fi
  
  _ppl_is_feature_enabled "DEBUG-CONFIG" && DEBUG_CONFIG=true
  
  _ppl_load_settings --stdin < <(
    __cd "$DATA_REPO_PATH"
    _exec_with_empty_env \
      "./configure.sh" \
        "$PPL_REPO" "${PPL_NEAREST_MAIN_BRANCH}" \
        "$PPL_BRANCHING_TYPE" "$PPL_JOB" "$ENTANDO_OPT_ENVIRONMENT_NAMES" \
        "$first_step" "$DEBUG_CONFIG" || {
      _FATAL "Configuration script returned error state \"$?\"" 1>&2
    }
  )

  
  # EXPECTED RESULT:
  # - ENTANDO_OPT_ENVIRONMENT_FILE            => always assigned
  # - ENTANDO_OPT_ENVIRONMENT_NAMES           => may be assigned
  # - ENTANDO_OPT_SNYK_SUPPRESSION_FILE       => may be assigned
  # - ENTANDO_OPT_SNYK_SCAN_SUPPRESSION_MODE  => may be assigned
  
  $DEBUG_CONFIG && $first_step && {
    _pp ENTANDO_DATA_REPO_REF ENTANDO_OPT_ENVIRONMENT_FILE ENTANDO_OPT_ENVIRONMENT_NAMES \
        ENTANDO_OPT_SNYK_SUPPRESSION_FILE ENTANDO_OPT_SNYK_SCAN_SUPPRESSION_MODE
  } 1>&2
  
  if [ -z "$ENTANDO_OPT_ENVIRONMENT_FILE" ]; then
    _FATAL "Error configuring the pipelines: configuration script returned no or empty ENTANDO_OPT_ENVIRONMENT_FILE"
  fi
    
  ENTANDO_OPT_ENVIRONMENTS="$(<"$ENTANDO_OPT_ENVIRONMENT_FILE")"
  
  if [ -z "$ENTANDO_OPT_ENVIRONMENTS" ]; then
    _FATAL "Error configuring the pipelines: configuration script returned unexistent or empty environment file ($ENTANDO_OPT_ENVIRONMENT_FILE)"
  fi

  __cd "$saved_pwd"
}

cfg.git_fetch_origin() {
  git fetch origin "$1":"$1" --depth 1 &> /dev/null || {
    _log_d "reference \"$1\" not found"
  }
}

# Scans the environment for ENTANDO_OPT_XXX variables and decodes/derefence them
# See also _decode_entando_opt and _resolve_entando_opt
#
# NOTE 
# 1) The reference resolution process is limited to 3 passes, so a sequence of
# nested references that goes beyond that limit will not be properly satisfied.
#
_load_entando_opts() {
  if [[ -n "$ENTANDO_OPT_ENVIRONMENT_NAMES" || -n "$ENTANDO_OPT_ENVIRONMENTS" ]]; then
    _decode_entando_opt ENTANDO_OPT_ENVIRONMENT_NAMES
    last=false
    while :; do
      IFS= read -r env_name || last=true
      _resolve_entando_opt env_name
       if [ -n "$env_name" ]; then
        _ppl_load_settings --section "$env_name" "$ENTANDO_OPT_ENVIRONMENTS"
      fi
      $last && break
    done <<< "${ENTANDO_OPT_ENVIRONMENT_NAMES//,/$'\n'}"
  fi
  
  for varname in ${!ENTANDO_OPT*}; do
    _decode_entando_opt "$varname"
  done
  
  for i in {1..3}; do
    for varname in ${!ENTANDO_OPT*}; do
      _resolve_entando_opt "$varname"
    done
  done
  for varname in ${!ENTANDO_OPT*}; do
    _resolve_entando_opt --finalize "$varname"
  done
  
  _ppl_load_settings "$ENTANDO_OPT_CUSTOM_ENV"
}


# Unsets all the ENTANDO_OPT* vars matching the criteria.
# All of the if no match criteria is provided
#
# Options:
# --like pattern   matches all the vars with a name mathing the pattern.
#                  can be specified up to 3 times
#
# shellcheck disable=SC2120
_unset_all_entano_options() {
  local WITH1=""; [ "$1" == "--like" ] && { WITH1="$2"; shift 2; }
  local WITH2=""; [ "$1" == "--like" ] && { WITH2="$2"; shift 2; }
  local WITH3=""; [ "$1" == "--like" ] && { WITH3="$2"; shift 2; }
  for varname in ${!ENTANDO_OPT*}; do
    if [[ "varname" =~ $WITH1 || "varname" =~ $WITH2 || "varname" =~ $WITH3 ]]; then
      unset "$varname"
    fi
  done
}


# Scans args for --ENTANDO_OPT_XXX arguments and uses them to set the related environment vars
#
_read_entando_options_from_args() {
  for i in "${!ARGS_OPT[@]}"; do
    if [ "${i:0:14}" == "--ENTANDO_OPT_" ]; then
      _get_arg "$@" "${i:2}" "$i"
    fi
  done
}

_extract_entando_prj_pipeline_config() {
  (
    cd "$1" 1> /dev/null || {
      echo "???"
      return 1
    }
    __ppl_enter_local_clone_dir &> /dev/null
    _enp_load &> /dev/null
    _enp_load_pipeline_local_settings &>/dev/null
    echo "$ENTANDO_PPL_CONFIG"
  )
}
