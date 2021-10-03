#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/base.sh"
  . "$PROJECT_DIR/lib/pkg.sh"
  . "$PROJECT_DIR/macro/github/setup-task-enabling.sh"
}

#TEST:lib
test_setup-task-enabling() {
  print_current_function_name "RUNNING TEST> "  ".."
  (
    TEST__APPLY_OVERRIDES() {
      _itmlst_from_string PPL_PR_LABELS \
        "ENABLE-TASK-A,DISABLE-TASK-B,ENABLE-TASK-X,DISABLE-TASK-X2,DISABLE-TASK-Z,ENABLE-TASK-Z,SKIP-TASK-S"
      # shellcheck disable=SC2034
      PPL_FEATURES="ENABLE-TASK-C,DISABLE-TASK-D,DISABLE-TASK-X,ENABLE-TASK-X2,SKIP-TASK-S2"
      ENTANDO_OPT_GLOBAL_FEATURES="ENABLE-TASK-G"
    }
    # shellcheck disable=SC2034
    local RES="$(
      ppl--setup-task-enabling "TASK-A" "TASK-B" "TASK-C" "TASK-D" "TASK-X" "TASK-X2" "TASK-Z" "TASK-S" "TASK-S2"
    )"
    
    ASSERT RES =~ "::set-output name=TASK-A::true"
    ASSERT RES =~ "::set-output name=TASK-B::false"
    ASSERT RES =~ "::set-output name=TASK-C::true"
    ASSERT RES =~ "::set-output name=TASK-D::false"
    ASSERT RES =~ "::set-output name=TASK-X::true"
    ASSERT RES =~ "::set-output name=TASK-X2::false"
    ASSERT RES =~ "::set-output name=TASK-Z::false"
    ASSERT RES =~ "::set-output name=TASK-S::false"
    ASSERT RES =~ "::set-output name=TASK-G::true"
    ASSERT RES =~ "SKIP-TASK-S2.*not allowed in \"PPL_FEATURES\""
    ASSERT -v QUERY_HISTORY "$(cat "$TEST__TECHNICAL_LOG_FILE")" =~ "DELETE.*SKIP-TASK-S"

    true
  )
}

#TEST:lib
test_setup-task-list() {
  print_current_function_name "RUNNING TEST> "  ".."
  (
    TEST__APPLY_OVERRIDES() {
      _itmlst_from_string PPL_PR_LABELS \
        "ENABLE-TASK-A,DISABLE-TASK-B"
      # shellcheck disable=SC2034
      {
        ENTANDO_OPT_FEATURES="ENABLE-TASK-C,DISABLE-TASK-D"
        ENTANDO_OPT_GLOBAL_FEATURES="ENABLE-TASK-G"
      }
    }
    
    # shellcheck disable=SC2034
    local RES="$(
      ppl--setup-task-list "TASK_LIST" false "TASK-A" "TASK-B" "TASK-C" "TASK-D" "TASK-X" "TASK-G"
    )"
    
    ASSERT RES =~ "::set-output name=TASK_LIST::\['TASK-A','TASK-C','TASK-G'\]"

    TEST__APPLY_OVERRIDES() { :; }

    # shellcheck disable=SC2034
    local RES="$(
      ppl--setup-task-list "TASK_LIST" false "TASK-A" "TASK-B" "TASK-C" "TASK-D" "TASK-X" "TASK-G"
    )"
    
    ASSERT RES !=~ "::set-output"

    true
  )
}

true
