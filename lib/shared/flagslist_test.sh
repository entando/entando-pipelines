#/bin/bash

_require "$PROJECT_DIR/lib/shared/flagslist.sh"

#TEST:unit,lib,flagslist
flagslist.test.all() {
  local flagslist
  ( _IT "should find enabled flags that are present"
  
    _flagslist.build flagslist "red" "green" "blue"
    _flagslist.is_flag_enabled "$flagslist" "red"  || _FAIL "flag position start but found disabled"
    _flagslist.is_flag_enabled "$flagslist" "green" || _FAIL "flag position middle but found disabled"
    _flagslist.is_flag_enabled "$flagslist" "blue"  || _FAIL "flag position end but found disabled"
  )
  
  ( _IT "should find disabled flags that are not present" SILENCE-ERRORS
  
    _flagslist.build flagslist "red" "green" "blue"
    _flagslist.is_flag_enabled "$flagslist" "blu" && _FAIL "flag that is not present but found enabled"
  
    _flagslist.from_string flagslist ""
    _flagslist.is_flag_enabled "$flagslist" "red" && _FAIL "empty list but found enabled"
  )
  
  ( _IT "should find enabled flags present in list with mixed separators"
  
    _flagslist.from_string flagslist "red,green|blue"$'\n'"yellow"
    _flagslist.is_flag_enabled "$flagslist" "red" || _FAIL  "flag position start but found disabled"
    _flagslist.is_flag_enabled "$flagslist" "green" || _FAIL "flag position middle left but found disabled"
    _flagslist.is_flag_enabled "$flagslist" "blue" || _FAIL "flag position middle righ but found disabled"
    _flagslist.is_flag_enabled "$flagslist" "yellow" || _FAIL "flag position end but found disabled"
  )
  
  ( _IT "should find enabled flags in list with wildcards"
  
    _flagslist.from_string flagslist "*"
    _flagslist.is_flag_enabled "$flagslist" "red" || _FAIL "red"
  )

  ( _IT "should find enabled flags in list with wildcards but found also handle subtractions"

    _flagslist.from_string flagslist "*,-blue"
    _flagslist.is_flag_enabled "$flagslist" "red" || _FAIL "non substracted"
    _flagslist.is_flag_enabled "$flagslist" "blue" && _FAIL "substracted"
  
    _flagslist.from_string flagslist "red,green|blue"$'\n'"yellow|-*|blue"
    _flagslist.is_flag_enabled "$flagslist" "red" && _FAIL "before wildcard substraction but found enabled"
    _flagslist.is_flag_enabled "$flagslist" "green" && _FAIL "before wildcard substraction but found enabled"
    _flagslist.is_flag_enabled "$flagslist" "blue" || _FAIL "after wildcard substraction but found disabled"
    _flagslist.is_flag_enabled "$flagslist" "yellow" && _FAIL "before wildcard substraction but found enabled"
  )
}
