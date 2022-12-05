#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# MACRO OPERATIONS RELATED TO CODE AND DEPENDECIES SCANS
#
# Params:
# $1: action to apply
#
# Actions:
# - snyk:   runs a snyk based scan of the current project
#
# Env vars:
# - ENTANDO_OPT_SNYK_ORG                the project organization under the snyk cloud service
# - ENTANDO_OPT_SNYK_PRJ                the project name under the snyk cloud service
# - ENTANDO_OPT_SNYK_SCAN_BASE_IMAGES   if true activates the scan of the base images in container scans
#
ppl--scan() {
  (
    START_MACRO "SCAN" "$@"
    __ppl_enter_local_clone_dir
    ppl--scan.exec --no-parse
  )
}    

ppl--scan.exec() {
  if [ "$1" == "--no-parse" ] ; then
    shift
  else
    # shellcheck disable=SC2034      
    ARGS_FLAGS=(--no-skip --no-repo)
    PARSE_ARGS "$@"
  fi

  __ppl_determine_current_project_type --check

  local action
  _get_arg action 1

  case "$action" in
    snyk)
      ppl--scan.PREREQUIREMENTS
      ppl--scan.SETUP
      ppl--scan.SCAN || _SOE
      ppl--scan.CLEANUP
      ;;
    snyk-container)
      local imageAddress dockerFile
      _get_arg imageAddress 2
      _get_arg dockerFile 3
      ppl--scan.PREREQUIREMENTS
      ppl--scan.SCAN --container "$imageAddress" "$dockerFile"
      ;;
    *)
      _FATAL "Invalid scan macro action \"$action\""
      ;;
  esac
}

ppl--scan.PREREQUIREMENTS() {
  _pkg_get nodejs -c node
  _pkg_get npm -c npm
  _pkg_is_command_available || {
    ${ENTANDO_OPT_SUDO:+"$ENTANDO_OPT_SUDO" -n} npm install -g snyk 1>/dev/null
  }
  _pkg_is_command_available -m snyk
}

ppl--scan.SETUP() {
  local MD="mode = \"$ENTANDO_OPT_SNYK_SCAN_SUPPRESSION_MODE\""
  local FD="suppression file"

  # shellcheck disable=SC2034  
  ENTANDO_OPT_LOG_LEVEL=DEBUG
  
  case "$ENTANDO_OPT_SNYK_SCAN_SUPPRESSION_MODE" in
    "only-global") 
      ppl--scan.SETUP.use-global "Using global $FD ($MD)"
      ;;
    "local-fallback-to-global")
      if [ -f "$ENTANDO_SNYK_LOCAL_FILE" ]; then
        _log_d "Using local $FD ($MD)"
      else
        ppl--scan.SETUP.use-global "Using global $FD because no local $FD was found ($MD)"
      fi
      ;;
    "gobal-fallback-to-local")
      if [ -f "$ENTANDO_OPT_SNYK_SUPPRESSION_FILE" ]; then
        ppl--scan.SETUP.use-global "Using global $FD because no local $FD was found ($MD)"
      else
        _log_d "Using local $FD because no global $FD was found or specified ($MD)"
      fi
      ;;
    "only-local")
      _log_d "Using local $FD ($MD)"
      ;;
    *)
      ppl--scan.SETUP.use-global "Using global $FD ($MD)"
      ;;
  esac
}

ppl--scan.CLEANUP() {
  # Restores the original .snyk file
  git checkout "$ENTANDO_SNYK_LOCAL_FILE" &> /dev/null
  true
}

ppl--scan.SETUP.use-global() {
  _log_d "$1"
  (
    _NONNULL ENTANDO_OPT_SNYK_SUPPRESSION_FILE
    __exist -f "$ENTANDO_OPT_SNYK_SUPPRESSION_FILE"
    cp "$ENTANDO_OPT_SNYK_SUPPRESSION_FILE" "$ENTANDO_SNYK_LOCAL_FILE"
  ) || _FATAL "scan setup failed"
}

ppl--scan.SCAN() {
  local O1="" O2="";[ "$1" = "--container" ] && { O1="$2";O2="$3";shift 3; }
  local O3=""; [ -z "$O1" ] && O3="$PPL_REPO_GIT_URL"
  local O4=""; [ "$ENTANDO_OPT_SNYK_SCAN_BASE_IMAGES" != "true" ] && O4="--exclude-base-image-vulns"
  local org prj
  _get_arg -m -p org "--org" "${ENTANDO_OPT_SNYK_ORG:-$SNYK_ORG}"
  _get_arg prj "--prj" "$ENTANDO_OPT_SNYK_PRJ"
  
  local RV=0
  
  _log_i "Running snyk test.."
  
  local RESFILE="$(mktemp)"
  
  snyk ${O1:+container} test \
    ${O1:+"$O1"} \
    ${O2:+--file="$O2"} \
    --org="$org" \
    ${prj:+--project-name="$prj"} \
    ${O3:+--remote-repo-url="$O3"} \
    "$O4" \
  > "$RESFILE"
  
  RV="$?"

  if [ "$RV" != "0" ]; then
    _ppl_is_feature_enabled "ADD-REVIEW-ON-SECURITY-ERROR" && {
      _ppl-pr-request-change "Please fix the snyk issues"
    }
    
    echo "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"
    echo "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"
    _log_i "Issues detected by the scan:"
    cat "$RESFILE"
    echo "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"
    echo "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"
  fi
  
  _log_i "Running snyk monitor.."
  
  snyk ${O1:+container} monitor \
    ${O1:+"$O1"} \
    --org="$org" \
    ${prj:+--project-name="$prj"} \
    ${O3:+--remote-repo-url="$O3"} \
  || true

  if [ "$RV" != "0" ]; then
    _FATAL "Snyk reported error code \"$RV\""
  fi
}
