#!/bin/bash

# shellcheck disable=SC1091,SC1090
. "$PROJECT_DIR/test/_test-base.sh"

# shellcheck disable=SC2034
#TEST:macro
test_operator_provisioning() {
  print_current_function_name "RUNNING TEST> "  ".."
  (
    TEST.mock.kube.oc
    
    ENTANDO_OPT_TEST_OPERATOR_GIT_REPO_URL="file://$TEST__WORK_DIR/repo-mocks/entando-k8s-controller-coordinator-mock"
    ENTANDO_OPT_TEST_OPERATOR_VERSION="v0.0.1-MOCK"
    
    ENTANDO_OPT_DOCKER_ORG="b7fb0cd3-859f-43eb-acac-d13de40b1bf2"
    ENTANDO_OPT_IMAGE_REGISTRY_OVERRIDE="b3fa1fcd-0b40-48e1-936a-1036adfdb80e"
    ENTANDO_OPT_IMAGE_REGISTRY_CREDENTIALS="ffb4d60a-3ad1-41ff-b178-105a5c370ad8"

    (
      ppl--mvn.post-deloyment.install-operator
    ) || _SOE
    
    __cd "$HOME/.entando/ppl/operator-clone/charts"

    # shellcheck disable=SC2034
    local count="$(grep -F "{{ENTANDO_" . -r  2>/dev/null | wc -l)"
    ASSERT count = 0
    
    ASSERT -v CHECK_DOCKER_ORG "$(grep "$ENTANDO_OPT_DOCKER_ORG" . -r 2>/dev/null | wc -l)" = 2
    ASSERT -v CHECK_PROJECT_VER "$(grep "$ENTANDO_OPT_TEST_OPERATOR_VERSION" . -r  2>/dev/null | wc -l)" = 6
    ASSERT -v CHECK_IMAGE_REGISTRY_OVERRIDE "$(grep "$ENTANDO_OPT_IMAGE_REGISTRY_OVERRIDE" . -r  2>/dev/null | wc -l)" = 3
    ASSERT -v ENTANDO_OPT_IMAGE_REGISTRY_CREDENTIALS "$(grep "$ENTANDO_OPT_IMAGE_REGISTRY_CREDENTIALS" . -r  2>/dev/null | wc -l)" = 1
    
    true
  )
}
