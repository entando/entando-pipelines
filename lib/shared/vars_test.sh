#/bin/bash

. "$PROJECT_DIR/lib/shared/vars.sh"

#TEST:unit,lib,vars
_vars.test.set_var() {
  
  ( _IT "should set the var as expected"
  
    _vars.set_var VAR "VALUE"
    _ASSERT VAR = VALUE
  )

  ( _IT "should fatal if empty var name is provided" SUPPRESS-ERRORS
  
    (_vars.set_var "" "VALUE"; exit 0) && _FAIL "was expected to fatal"
  )
  
  ( _IT "should fatal is illegal var name is provided" SUPPRESS-ERRORS
  
    (_vars.set_var ILLEGAL-VAR-NAME "VALUE") && _FAIL "was expected to fatal"
  )
}

#TEST:unit,lib,vars
_vars.test.is_valid_var_name() {
  
  ( _IT "should not fatal is var name is legal"
  
    _vars.is_valid_var_name "avar"; _ASSERT_RC "0"
    _vars.is_valid_var_name "a_var"; _ASSERT_RC "0"
    _vars.is_valid_var_name "a_var9"; _ASSERT_RC "0"
  )
  
  ( _IT "should fatal is var name is illegal" SUPPRESS-ERRORS
  
    _vars.is_valid_var_name ""; _ASSERT_RC "1"
    _vars.is_valid_var_name "a.var"; _ASSERT_RC "1"
    _vars.is_valid_var_name "a var"; _ASSERT_RC "1"
    _vars.is_valid_var_name "a-var"; _ASSERT_RC "1"
    _vars.is_valid_var_name ".avar"; _ASSERT_RC "1"
    _vars.is_valid_var_name "avar?"; _ASSERT_RC "1"
  )

}
