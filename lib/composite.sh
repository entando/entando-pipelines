#!/bin/bash

# Extracts the latest bom version given the bom repository URL
#
# Params:
# $1: dest var
# $2: bom repo URL
#
_ppl_query_latest_bom_version() {
  local TMPDIR
  TMPDIR="$(mktemp -d)"
  local TMP
  _git_full_clone --shallow "$2" "$TMPDIR" ""
  __cd "$TMPDIR"
  _git_determine_latest_version TMP
  __cd -
  rm -rf "$TMPDIR"
  [ -n "$TMP" ] && _set_var "$1" "$TMP"
}

# Sets one ore more evironment variables given a semicolon-delimited list of assignments
#
# WARNING: the parser interprets the backslash
# WARNING: the parser doesn't support quotes like a CSV, however you can still escape the colon with the backslash ("\;")
#
# Options:
# --var-sep value    the var separator to assume
# --stdin            reads the environment the stdin
#
# Paramers:
# $1                unless "--stdin" is provider it's the environment to be loaded
#
# eg:
# - LEGAL:   _ppl_load_settings 'A=1;B=hey there;C=true'
# - ILLEGAL: _ppl_load_settings 'A=1;B="hey;there";C=true'
# - LEGAL:   _ppl_load_settings 'A=1;B=hey\;there;C=true'
#
_ppl_load_settings() {
  local LNSEP=';';[ "$1" = "--var-sep" ] && { LNSEP="$2"; shift 2; }
  {
    if [ "$1" != "--stdin" ]; then
      exec <<< "$1"
    fi
    
    local last=false
    
    while true; do
      # shellcheck disable=SC2162
      read -d "$LNSEP" assign || last=true
      if [ -n "$assign" ]; then
        IFS='=' read -r name value <<< "$assign"
        _set_var "$name" "$value"
        # shellcheck disable=SC2163
        export "$name"
      fi
      $last && break
    done
  }
}

# Runs a the preview environment provisioning script
#
# Params:
# $1 the test namespace to use
# $2 the project name
# $3 the project version
#
_ppl_run_post-deployment-test_setup_script() {
  [ ! -f "./.github/setup-post-deployment" ] && return 99
  if "./.github/setup-post-deployment.sh" "$@"; then
    _log_i "Custom preview environment provisioning script passed"
    true
  else
    _FATAL "Custom preview environment provisioning script failed with error code: \"$?\""
  fi
}

# Creates a preview environment by using helm charts present in the dir
#
# Params:
# $1: project name
# $2: project version
# $3: test namespace
# $4: hostname suffix
#
_ppl_provision_helm_preview_environment() {
  local projectName="$1" projectVersion="$2" ns="$3" hostname_suffix="${4:-"null"}"
  
  [ ! -f "./charts/preview/Chart.yaml" ] && return 99
  _log_i "Started the provisiong of the helm preview environment"
  _pkg_get --tar-install "$ENTANDO_OPT_HELM_CLI_URL" "helm" -c "helm"

  # ~ PARAMETERS RESOLUTION
  _log_i "Provisioning - PHASE1"
  __cd "charts"
  
  _helm_update_placeholder_parameters "$projectName" "$projectVersion" "$ns" "$hostname_suffix"
  
  # EXECUTION
  _log_i "Provisioning - PHASE2"
  __cd "preview"
  
  _log_d "Deploying.."
  _helm_apply "$projectName" "$ns"
}

_helm_update_placeholder_parameters() {
  local projectName="$1" projectVersion="$2" ns="$3" hostname_suffix="$4"
  for d in */ ; do
    (
      if [[ -f "$d/Chart.yaml" ]]; then
        _log_d "Found chart in directory \"$d\""
        __cd "$d"
        _ppl_set_provisioning_placeholders_in_files \
            "Chart.yaml;values.yaml;requirements.yaml" \
            "$projectName" "$projectVersion" "$ns" "$hostname_suffix"
      fi
      true
    ) || _SOE
  done
}

# Generates the helm chart in the current dir and then applies it to kubernetes
#
_helm_apply() {
  local name="$1" ns="$2"
  (
    local TMPFILE="$(mktemp --suffix=".yaml")"
    # shellcheck disable=SC2064
    trap "rm \"${TMPFILE}\"" exit
    [ -f "./requirements.yaml" ] && { helm dep update || _FATAL "Heml update failed"; }
    helm template -n "$ns" "$name" . > "${TMPFILE}" || _FATAL "Heml template failed"
    kube.oc apply -n "$ns" -f "${TMPFILE}" || _FATAL "OC apply failed"
  ) || _SOE
}

# Sets a set of well-known provisioning parameters in a given file
#
# Params:
# $1: list of files to set, separed by semicolon
# $2: Project name
# $3: Project version
# $4: Namespace to use for testing
# $5: Hostname suffix
#
_ppl_set_provisioning_placeholders_in_files() {
  local prj_name="$(_str_escape_char "$2" "/")"
  local prj_ver="$(_str_escape_char "$3" "/")"
  local ns="$(_str_escape_char "$4" "/")"
  local hostname_suffix="$(_str_escape_char "$5" "/")"
  local reg_cred="$(_str_escape_char "$ENTANDO_OPT_IMAGE_REGISTRY_CREDENTIALS" "/")"
  local _reg_ov="${ENTANDO_OPT_IMAGE_REGISTRY_OVERRIDE:-$ENTANDO_OPT_IMAGE_REGISTRY}"
  local reg_ov="$(_str_escape_char "$_reg_ov" "/")"
  local image_repo="$(_str_escape_char "$(path-concat "$_reg_ov" "$ENTANDO_OPT_DOCKER_ORG" "$prj_name")" "/")"
  local tls_crt="$(_str_escape_char "$ENTANDO_OPT_TEST_TLS_CRT" "/")"
  local tls_key="$(_str_escape_char "$ENTANDO_OPT_TEST_TLS_KEY" "/")"

  while IFS= read -r file; do
    if [ -f "$file" ]; then
      sed -i -e "s/{{ENTANDO_PROJECT_NAME}}/$prj_name/g" \
             -e "s/{{ENTANDO_PROJECT_VERSION}}/$prj_ver/g" \
             -e "s/{{ENTANDO_IMAGE_ORG}}/$ENTANDO_OPT_DOCKER_ORG/g" \
             -e "s/{{ENTANDO_IMAGE_REPO}}/$image_repo/g" \
             -e "s/{{ENTANDO_IMAGE_TAG}}/$prj_ver/g" \
             -e "s/{{ENTANDO_TEST_NAMESPACE}}/$ns/g" \
             -e "s/{{ENTANDO_OPT_TEST_HOSTNAME_SUFFIX}}/$hostname_suffix/g" \
             -e "s/{{ENTANDO_OPT_TEST_NAMESPACE}}/$ENTANDO_OPT_TEST_NAMESPACE/g" \
             -e "s/{{ENTANDO_OPT_TEST_TLS_CRT}}/$tls_crt/g" \
             -e "s/{{ENTANDO_OPT_TEST_TLS_KEY}}/$tls_key/g" \
             -e "s/{{ENTANDO_OPT_IMAGE_REGISTRY_CREDENTIALS}}/$reg_cred/g" \
             -e "s/{{ENTANDO_OPT_IMAGE_REGISTRY_OVERRIDE}}/$reg_ov/g" \
          "$file";
    fi
  done <<< "${1//;/$'\n'}"
}

# Sets the the project snapshot version according with the current pr information
#
_ppl_autoset_snapshot_version() {
  _pkg_get "xmlstarlet"
  local snapshotversionNumber
  ppl--publication._determine_snapshot_version_number snapshotversionNumber
  _pom_set_project_version "$snapshotversionNumber" "./pom.xml"
}

# Reads the current branch from a give dir, or the current one if none is given
#
_ppl_print_current_branch_of_dir() {
  local old_dir="$PWD"
  [ -n "$1" ] && __cd "$1"
  git rev-parse --abbrev-ref HEAD 2>/dev/null
  [ -n "$1" ] && __cd "$old_dir"
}


# Determines the type of project in the current dir
#
# Params:
# $1: dest var
#
__ppl_determine_current_project_type() {
  local _tmp_
  
  if [[ -f ".ent/ent-prj" || -f "entando-project" ]]; then
    _tmp_="ENP"
  elif [ -f "pom.xml" ]; then
    _tmp_="MVN"
  elif [ -f "package.json" ]; then
    _tmp_="NPM"
  else
    _FATAL "Unable to determine the project type"
  fi

  if [ "$1" == "--print" ]; then
    echo "$_tmp_"
  elif [ "$1" == "--check" ]; then
    true
  else
    _set_var "$1" "$_tmp_"
  fi
}

