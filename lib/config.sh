#!/bin/bash

# Load the pipeline configuration from the pipelines data repository
#
_ppl_clone_and_configure_data_repo() {
  _NONNULL ENTANDO_OPT_DATA_REPO
  
  if [ "${ENTANDO_OPT_DATA_REPO:0:3}" = "###" ]; then
    ENTANDO_OPT_DATA_REPO="${ENTANDO_OPT_DATA_REPO:3}"
  fi
  
  local data_repo_dir="entando-data-repo"
  local first_step=false
  
  __cd "$HOME"
  if [ ! -d "$data_repo_dir" ]; then
    _git_full_clone --shallow "$ENTANDO_OPT_DATA_REPO" "$data_repo_dir" "$PPL_NEAREST_WELL_KNOWN_BRANCH" "${ENTANDO_OPT_DATA_REPO_TOKEN}"
    first_step=true
  fi
  
  local branch_latest_indicator="$PPL_NEAREST_WELL_KNOWN_BRANCH-latest"
  
  (
    __cd "$data_repo_dir"
    if _git_tag_exists "$branch_latest_indicator" >/dev/null 2>&1; then
      __git chekout "$branch_latest_indicator"
    fi
  )
  
  DATA_REPO_PATH="$PWD/$data_repo_dir"
  
  DEBUG_CONFIG=false
  _ppl_is_feature_enabled "DEBUG-CONFIG" && DEBUG_CONFIG=true

  _ppl_load_settings --stdin < <(
    _exec_with_empty_env \
      "$data_repo_dir/configure.sh" \
      "$DATA_REPO_PATH" "$PPL_REPO" "$PPL_NEAREST_WELL_KNOWN_BRANCH" \
      "$PPL_BRANCHING_TYPE" "$PPL_JOB" "$ENTANDO_OPT_ENVIRONMENT_NAMES" \
      "$first_step" "$DEBUG_CONFIG" || {
      _FATAL "Configuration script returned error state \"$?\""
    }
  ) || _SOE
  
  # EXPECTED RESULT:
  # - ENTANDO_ENVIRONMENT_FILE  => always assigned
  # - ENTANDO_ENVIRONMENT_NAMES => may be assigned
  # - ENTANDO_SNYK_FILE         => may be assigned
  
  $DEBUG_CONFIG && {
    _pp ENTANDO_ENVIRONMENT_FILE ENTANDO_ENVIRONMENT_NAMES ENTANDO_SNYK_FILE
  }
  
  if [ -z "$ENTANDO_ENVIRONMENT_FILE" ]; then
    _FATAL "Error configuring the pipelines: configuration script returned no or empty ENTANDO_ENVIRONMENT_FILE"
  fi
    
  ENTANDO_OPT_ENVIRONMENTS="$(<"$ENTANDO_ENVIRONMENT_FILE")"
  
  if [ -z "$ENTANDO_OPT_ENVIRONMENTS" ]; then
    _FATAL "Error configuring the pipelines: configuration script returned unexistent or empty environment file ($ENTANDO_ENVIRONMENT_FILE)"
  fi
  
  __cd "$saved_pwd"
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
