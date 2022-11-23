#/bin/bash

_require "$PROJECT_DIR/lib/shared/vars.sh"

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
  
  ( _IT "should fatal if var name is illegal" SUPPRESS-ERRORS
  
    _vars.is_valid_var_name ""; _ASSERT_RC "1"
    _vars.is_valid_var_name "a.var"; _ASSERT_RC "1"
    _vars.is_valid_var_name "a var"; _ASSERT_RC "1"
    _vars.is_valid_var_name "a-var"; _ASSERT_RC "1"
    _vars.is_valid_var_name ".avar"; _ASSERT_RC "1"
    _vars.is_valid_var_name "avar?"; _ASSERT_RC "1"
  )

}

#TEST:unit,lib,vars,array
_vars.test.array.contains() {
  ( _IT "should return with success if element is present in array" 
    
    _vars.array.contains "elem1" "elem1" "elem2" "elem3" || _FAIL
    _vars.array.contains "elem2" "elem1" "elem2" "elem3" || _FAIL
    _vars.array.contains "elem3" "elem1" "elem2" "elem3" || _FAIL
    _vars.array.contains "e" "elem1" "elem2zz" "elem3" "e" || _FAIL
  )
  
  ( _IT "should return with error if element is not present in array" SUPPRESS-ERRORS
    
    _vars.array.contains "elem4" "elem1" "elem2" "elem3" && _FAIL
  )
  
  ( _IT "should not allow partial matches" SUPPRESS-ERRORS
    
    _vars.array.contains "e" "elem1" "elem2" "elem3" && _FAIL
    _vars.array.contains "elem1" "elem1 " "elem2" "elem3" && _FAIL
    _vars.array.contains "elem1" " elem1" "elem2" "elem3" && _FAIL
    _vars.array.contains "elem1" " elem1 " "elem2" "elem3" && _FAIL
  )
  
  ( _IT "should not allow wildcards" SUPPRESS-ERRORS
    
    _vars.array.contains "e*" "elem1" "elem2" "elem3" && _FAIL
    _vars.array.contains "elem1" "elem1*" "elem2" "elem3" && _FAIL
    _vars.array.contains "elem1" "*elem1" "elem2" "elem3" && _FAIL
    _vars.array.contains "elem1" "*elem1*" "elem2" "elem3" && _FAIL
  )
  
  ( _IT "should not allow regexp" SUPPRESS-ERRORS
    
    _vars.array.contains "e.*" "elem1" "elem2" "elem3" && _FAIL
    _vars.array.contains "elem1" "elem1.*" "elem2" "elem3" && _FAIL
    _vars.array.contains "elem1" ".*elem1" "elem2" "elem3" && _FAIL
    _vars.array.contains "elem1" ".*elem1.*" "elem2" "elem3" && _FAIL
  )
  
  ( _IT "should work in case of dup entries" SUPPRESS-ERRORS
    
    _vars.array.contains "elem1" "elem1" "elem2" "elem3" "elem1" || _FAIL
  )
}
