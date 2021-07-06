#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/base.sh"
}

#TEST:lib
test_set_var() {
  print_current_function_name "RUNNING TEST> "  ".."
  _set_var RES "hey"
  [ "$RES" = "hey" ] || FAILED
  
  true
}

true
