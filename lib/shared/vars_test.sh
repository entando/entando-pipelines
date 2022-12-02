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


#TEST:unit,lib,vars
_vars.test.load() {
  
  ( _IT "should load single-line settings from file"
    # shellcheck disable=SC2034
    local Z="_Z" K="_K"
    _vars.load "X=XX;Y=YY;Z=ZZ;W=W\;W"
    RES="$(bash -c 'echo "$X/$Y/$Z/$K/$W"')"
    _ASSERT RES = "XX/YY/ZZ//W;W"
  )
  
  ( _IT "should load multi-line settings from stdin"
    # shellcheck disable=SC2034
    local TESTENV="X=1"$'\n'$'\n'"Y=2"
    _vars.load --var-sep $'\n' --stdin <<< "$TESTENV"
    RES="$(bash -c 'echo "$X/$Y"')"
    _ASSERT RES = "1/2"
  )
  
  ( _IT "should load multi-line settings with sections from stdin"
    # shellcheck disable=SC2034
    { X=0;Y=0;LF=$'\n'; }
    local TESTENV="[SECT 1.0]${LF}X=1${LF}Y=2"${LF}
    TESTENV+="[SECT 1.1]${LF}X=11${LF}Y=22"${LF}
    _vars.load --section "SECT 1.1" --stdin <<< "$TESTENV"
    _ASSERT X = "11"
    _ASSERT Y = "22"
    
    _vars.load --section "SECT 1.0" --stdin <<< "$TESTENV"
    _ASSERT X = "1"
    _ASSERT Y = "2"
    TESTENV+="[SECT X]${LF}X=111"${LF}
    
    _vars.load --section "SECT 1.0" --stdin <<< "$TESTENV"
    _vars.load --section "SECT X" --stdin <<< "$TESTENV"
    _ASSERT X = "111"
    _ASSERT Y = "2"
    
    TESTENV+="[SECT Y]${LF}[a]X=1"${LF}
    _vars.load --section "SECT Y" --stdin <<< "$TESTENV"
    _ASSERT X = "111,1"
    _ASSERT Y = "2"
    
    TESTENV+="[SECT Z]${LF}[p]X=0"${LF}
    _vars.load --section "SECT Z" --stdin <<< "$TESTENV"
    _ASSERT X = "111,1"
    _ASSERT Y = "2"
  )
}

#TEST:unit,lib,vars
_vars.test.str.last_pos() {
  local RES
  _vars.str.last_pos RES ",10,11,12,11,13" "11"
  _ASSERT RES = 4
  _vars.str.last_pos RES ",10,11,12,*,13" "*"
  _ASSERT RES = 4
}
