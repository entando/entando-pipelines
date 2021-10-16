#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/base.sh"
  . "$PROJECT_DIR/lib/pkg.sh"
  . "$PROJECT_DIR/macro/agnostic/features.sh"
}

#TEST:lib
test_setup-features-flags() {
  print_current_function_name "RUNNING TEST> "  ".."
  (
    TEST.mock.context "github-context-sample-01.json"
    
    TEST__APPLY_OVERRIDES() {
      _itmlst_from_string PPL_PR_LABELS \
        "ENABLE-FEA-A,DISABLE-FEA-B,ENABLE-FEA-X,DISABLE-FEA-X2,DISABLE-FEA-Z,ENABLE-FEA-Z,SKIP-FEA-S"
      # shellcheck disable=SC2034
      ENTANDO_OPT_FEATURES="ENABLE-FEA-C,DISABLE-FEA-D,DISABLE-FEA-X,ENABLE-FEA-X2,SKIP-FEA-S2"
      ENTANDO_OPT_GLOBAL_FEATURES="ENABLE-FEA-G"
    }

    # shellcheck disable=SC2034
    local RES="$(
      ppl--setup-feature-flags "FEA-A" "FEA-B" "FEA-C" "FEA-D" "FEA-X" "FEA-X2" "FEA-Z" "FEA-S" "FEA-S2" "FEA-G"
    )"
    
    ASSERT RES =~ "::set-output name=FEA-A::true"
    ASSERT RES =~ "::set-output name=FEA-B::false"
    ASSERT RES =~ "::set-output name=FEA-C::true"
    ASSERT RES =~ "::set-output name=FEA-D::false"
    ASSERT RES =~ "::set-output name=FEA-X::true"
    ASSERT RES =~ "::set-output name=FEA-X2::false"
    ASSERT RES =~ "::set-output name=FEA-Z::false"
    ASSERT RES =~ "::set-output name=FEA-S::false"
    ASSERT RES =~ "::set-output name=FEA-G::true"
    ASSERT RES =~ "SKIP-FEA-S2.*not allowed in"
    ASSERT -v QUERY_HISTORY "$(cat "$TEST__TECHNICAL_LOG_FILE")" =~ "DELETE.*SKIP-FEA-S"

    true
  )
}

#TEST:lib
test_setup-feature-list() {
  print_current_function_name "RUNNING TEST> "  ".."
  (
    TEST.mock.context "github-context-sample-01.json"
    
    TEST__APPLY_OVERRIDES() {
      _itmlst_from_string PPL_PR_LABELS \
        "ENABLE-FEA-A,DISABLE-FEA-B"
      # shellcheck disable=SC2034
      {
        ENTANDO_OPT_FEATURES="ENABLE-FEA-C,DISABLE-FEA-D"
        ENTANDO_OPT_GLOBAL_FEATURES="ENABLE-FEA-G"
      }
    }
    
    # shellcheck disable=SC2034
    local RES="$(
      ppl--setup-features-list "FEATURE_LIST" false "FEA-A" "FEA-B" "FEA-C" "FEA-D" "FEA-X" "FEA-G"
    )"
    
    ASSERT RES =~ "::set-output name=FEATURE_LIST::\['FEA-A','FEA-C','FEA-G'\]"

    TEST__APPLY_OVERRIDES() { :; }

    # shellcheck disable=SC2034
    local RES="$(
      ppl--setup-features-list "FEATURE_LIST" false "FEA-A" "FEA-B" "FEA-C" "FEA-D" "FEA-X" "FEA-G"
    )"
    
    ASSERT RES !=~ "::set-output"

    true
  )
}

true
