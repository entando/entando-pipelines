#!/bin/bash

_require "lib/local/git_test.sh"

XDEV_TEST.BEFORE_FILE() {
  _LOAD_TEST_FILE --global PPL_CONTEXT "github/pull-sync-context.json"
  export PPL_CONTEXT
  
  _IMPORT_TEST_RESOURCE --global --untar "entando-engine.tar.gz"
  export MOCK_PPL_CLONE_URL="file://$PWD/resource/entando-engine"
  ppl.apply_context_overrides() {
    export PPL_CLONE_URL="$MOCK_PPL_CLONE_URL"
  }
  export -f ppl.apply_context_overrides
  
  _LOAD_TEST_FILE PPL_ENVIRONMENT "ppl-run/sample-plan.mvn.full-build.env"
  _vars.load --section 'TEST' --stdin <<< "$PPL_ENVIRONMENT"
  export ENTANDO_OPT_FULL_BUILD_PLAN
  
  #git.test.prepare-test-repo "test-repo" || _SOE
  #export PPL_CLONE_URL="file://$PWD/test-repo"
  #export PPL_CLONE_URL="https://github.com/entando/entando-engine"
  
  export GITHUB_ACTIONS=1
  export ENTANDO_PPL_HOME="$PROJECT_DIR"
  export ENTANDO_OPT_GIT_USER_NAME="test-user"
  export ENTANDO_OPT_GIT_USER_EMAIL="test-user@example.com"
  PPL_RUN="$ENTANDO_PPL_HOME/macro/ppl-run.sh"
}

XDEV_TEST.BEFORE_TEST() {
  rm -rf "local-clone"
}

#TEST:system,macro,ppl-run,ppl-run-init
ppl-run.test.init.run() {
  # macro.init.run
  _ppl-run.test.job.checkout
}

#TEST:system,macro,ppl-run,ppl-run-build,x
ppl-run.test.build.run() {
  # macro.init.run
  _ppl-run.test.job.checkout
  
  # macro\..*\.build
  "$PPL_RUN" prj full-build \
    --lcd="local-clone" \
    --checkout-with-token="TEST-TOKEN" \
  ;
}


#-----------------------------------------------------------------------------------------------------------------------
# SUBORDINATE FUNCTIONS

_ppl-run.test.job.checkout() {
  (
    "$PPL_RUN" init \
      --type=MVN \
      --lcd="local-clone" \
      --checkout-with-token="TEST-TOKEN" \
    ;
  ) || _SOE
}
