#!/bin/bash

# shellcheck disable=SC1091,SC1090
#. "$PROJECT_DIR/lib/base.sh"
. "$PROJECT_DIR/macro/github/get-preview-name.sh"

test_get-preview-name() {
  _set_var EE_PR_TITLE "ENG-0001/ENG-0002 Hi there"
  _set_var EE_PR_NUM "38"
  RES=$(ppl--get-preview-name)
  ASSERT RES="pENG-0002-PR38"

  true
}

true
