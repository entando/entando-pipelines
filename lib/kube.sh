#!/bin/bash

kube.oc() {
  if [ "$TEST__EXECUTION" != "true" ]; then
    oc "$@"
  else
    echo "[DOK] oc $*" >> "$TEST__TECHNICAL_LOG_FILE"
    true
  fi
}

# Waits for a condition on given resource
# $1: max wait
# $2: condition (until-present, until-not-present)
# $3: resource type
# $4: resource name
#
kube.oc.wait_for_resource() {
  if [ "$1" != "0" ]; then
    TMO="$1"; shift
    export -f kube.oc
    export -f kube.oc.wait_for_resource
    timeout "$TMO" bash -c 'kube.oc.wait_for_resource 0 "$@"' "" "$@"
  else
    while true; do
      if [ "$2" == "until-not-present" ]; then
        ! kube.oc get "$3" "$4" &>/dev/null && return 0
      else
        kube.oc get "$3" "$4" &>/dev/null && return 0
      fi
      sleep 0.5
    done
  fi
}

# Logins to an OKD instance given the related OKD variables
#
# Required environment variables:
#  ENTANDO_OPT_OKD_LOGIN_URL        the url of the OKD instance
#  ENTANDO_OPT_OKD_LOGIN_TOKEN      the tocken to use for the login operation
#  ENTANDO_OPT_OKD_LOGIN_NAMESPACE  the namespace to use
#
# Optional environment variables:
#   ENTANDO_OPT_OKD_LOGIN_INSECURE  forces a TLS-insecure login (default: false)
#   ENTANDO_OPT_OKD_CLI_URL         the URL from which the download tool should be downloaded
#                                   Note that this is a semicolon-delimited list, where the first element
#                                   is the url and the others are the optional curl options
#
kube.oc-login() {
  _NONNULL ENTANDO_OPT_OKD_LOGIN_URL ENTANDO_OPT_OKD_LOGIN_TOKEN ENTANDO_OPT_OKD_LOGIN_NAMESPACE
  
  _pkg_get --tar-install "$ENTANDO_OPT_OKD_CLI_URL" "oc" -c "oc"
  
  if [ "${ENTANDO_OPT_OKD_LOGIN_INSECURE:-}" == "true" ]; then
    local INSECURE=true
  else
    local INSECURE=false
  fi
  
  kube.oc login --insecure-skip-tls-verify="$INSECURE" \
    --token="$ENTANDO_OPT_OKD_LOGIN_TOKEN" --server="$ENTANDO_OPT_OKD_LOGIN_URL" || {
    _FATAL "Unable to login to \"$ENTANDO_OPT_OKD_LOGIN_URL\""
  }
  kube.oc project "$ENTANDO_OPT_OKD_LOGIN_NAMESPACE" || {
    _FATAL "Unable to switch to namespace \"$ENTANDO_OPT_OKD_LOGIN_NAMESPACE\""
  }
}

# Deletes and recreates a namespace
#
kube.oc.namespace.reset() {
  kube.oc.namespace.delete "$@"
  kube.oc.namespace.create "$@"
}

kube.oc.namespace.create() {
  local ns="$1" tmo="$2"
  _NONNULL ns tmo
  ! kube.oc get namespace "$ns" &> /dev/null && {
    _log_d "Creating the new test namespace \"$ns\""
    kube.oc create namespace "$ns"
    _log_d "Waiting for namespace creation.."
    kube.oc.wait_for_resource "$tmo" until-present namespace "$ns"
  }
}

kube.oc.namespace.delete() {
  local ns="$1" tmo="$2"
  _NONNULL ns tmo
  kube.oc get namespace "$ns" &> /dev/null && {
    _log_d "Deleting the old test namespace"
    kube.oc delete namespace "$ns" &> /dev/null
    _log_d "Waiting for namespace deletion.."
    kube.oc.wait_for_resource "$tmo" until-not-present namespace "$ns"
  }
}

kube.oc.namespace.suspend() {
  local ns="$1" tmo="$2"
  _NONNULL ns tmo
  _log_d "Suspending the test namespace: $ns"
  timeout "$tmo" kubectl scale statefulset,deployment -n "$ns" --all --replicas=0
}

# Filters out from the standard-input the triple-dash (---) separed documents that matches the given kind
#
# Params:
# $1 document kind
#
kube.manifest.filter-document-by-kind() {
  local block="" kind line
  local regex="^[[:blank:]]*deployment[[:blank:]]*$"
  while IFS= read -r line; do
    [ "${line:0:5}" == "kind:" ] && kind="${line:5}"
    block+="$line"$'\n'
    if [ "${line:0:3}" == "---" ]; then
      [[ ! "${kind,,}" =~ $regex ]] && echo -n "$block"
      block=""
    fi
  done
  [[ ! "${kind,,}" =~ $regex ]] && echo -n "$block"
}
