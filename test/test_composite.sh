#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/misc.sh"
  . "$PROJECT_DIR/lib/semver.sh"
}

#TEST:lib
test_ppl_provision_helm_preview_environment() {
  print_current_function_name "RUNNING TEST> "  ".."

  TEST.mock.kube.oc
  
  __cd "$TEST__WORK_DIR"
  __cd "repo-mocks/repo-with-charts"
  # shellcheck disable=SC2034
  PPL_PR_NUM="11"
  # shellcheck disable=SC2034
  PPL_REPO_GIT_URL="https://github.com/entando/example"
  ENTANDO_OPT_DOCKER_ORG="b7fb0cd3-859f-43eb-acac-d13de40b1bf2"
  ENTANDO_OPT_IMAGE_REGISTRY_OVERRIDE="b3fa1fcd-0b40-48e1-936a-1036adfdb80e"
  ENTANDO_OPT_IMAGE_REGISTRY_CREDENTIALS="ffb4d60a-3ad1-41ff-b178-105a5c370ad8"

  (
    _ppl_provision_helm_preview_environment "example" "7.0.0-SNAPSHOT" "test-entando-k8s-controller-coordinator"
  ) || _SOE

  # shellcheck disable=SC2034
  local count="$(grep -F "{{ENTANDO_" . -r  2>/dev/null | wc -l)"
  ASSERT count = 0
  
  ASSERT -v CHECK_DOCKER_ORG "$(grep "$ENTANDO_OPT_DOCKER_ORG" . -r 2>/dev/null | wc -l)" = 2
  ASSERT -v CHECK_PROJECT_VER "$(grep "7.0.0-SNAPSHOT" . -r  2>/dev/null | wc -l)" = 7
  ASSERT -v CHECK_IMAGE_REGISTRY_OVERRIDE "$(grep "$ENTANDO_OPT_IMAGE_REGISTRY_OVERRIDE" . -r  2>/dev/null | wc -l)" = 3
  ASSERT -v ENTANDO_OPT_IMAGE_REGISTRY_CREDENTIALS "$(grep "$ENTANDO_OPT_IMAGE_REGISTRY_CREDENTIALS" . -r  2>/dev/null | wc -l)" = 1
  
  true
}
