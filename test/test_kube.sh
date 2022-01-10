#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/base.sh"
  . "$PROJECT_DIR/lib/kube.sh"
}

#TEST:lib
test_kube() {
  print_current_function_name "RUNNING TEST> "  ".."
  
  local SAMPLE=""
  SAMPLE+=$'\n'"apiVersion: v1"
  SAMPLE+=$'\n'"stringData:"
  SAMPLE+=$'\n'"  tls.crt: ''"
  SAMPLE+=$'\n'"  tls.key: ''"
  SAMPLE+=$'\n'"kind: Secret"
  SAMPLE+=$'\n'"metadata:"
  SAMPLE+=$'\n'"  name: entando-empty-tls-secret"
  SAMPLE+=$'\n'"type: kubernetes.io/tls"
  SAMPLE+=$'\n'""
  SAMPLE+=$'\n'"---"
  SAMPLE+=$'\n'"apiVersion: v1"
  SAMPLE+=$'\n'"kind: Deployment"
  SAMPLE+=$'\n'"metadata:"
  SAMPLE+=$'\n'"  name: entando-docker-image-info"
  SAMPLE+=$'\n'"data:"
  SAMPLE+=$'\n'"---"
  SAMPLE+=$'\n'"apiVersion: v1"
  SAMPLE+=$'\n'"kind:   Deployment  "
  SAMPLE+=$'\n'"metadata:"
  SAMPLE+=$'\n'"  name: entando-docker-image-info"
  SAMPLE+=$'\n'"data:"
  SAMPLE+=$'\n'"---"
  SAMPLE+=$'\n'"apiVersion: v1"
  SAMPLE+=$'\n'"kind: ConfigMap"
  SAMPLE+=$'\n'"metadata:"
  SAMPLE+=$'\n'"  name: entando-docker-image-info"
  
  kube.manifest.filter-document-by-kind <<< "$SAMPLE"

  # shellcheck disable=SC2034
  local DEPLOYMENTS_FOUND="$(kube.manifest.filter-document-by-kind <<< "$SAMPLE" | grep 'Deployment' -c)"
  ASSERT DEPLOYMENTS_FOUND = 0
}

true
