#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/base.sh"
}

#TEST:lib
test_var_functions() {
  print_current_function_name "RUNNING TEST> "  ".."
  
  #~
  _is_valid_var_name a || FAILED
  _is_valid_var_name AB || FAILED
  _is_valid_var_name AB_C || FAILED
  _is_valid_var_name Ab9 || FAILED
  _is_valid_var_name aB9 || FAILED
  _is_valid_var_name Ab_9 || FAILED
  
  _is_valid_var_name AB.C && FAILED
  _is_valid_var_name 9AB.C && FAILED
  _is_valid_var_name .AB.C && FAILED
  _is_valid_var_name "AB.C " && FAILED
  _is_valid_var_name "" && FAILED
  _is_valid_var_name " " && FAILED

  #~
  _set_var RES "hey"
  [ "$RES" = "hey" ] || FAILED
  
  true
}

true
