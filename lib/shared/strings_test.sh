#/bin/bash

_require "$PROJECT_DIR/lib/shared/strings.sh"

#TEST:unit,lib,strings
_strings.test.all() {
  
  ( _IT "should get the last index of an element in a comma separed list"
    _ASSERT -v "last pos of simple value" "$(_strings.list.last_index_of ",10,11,12,11,13" "11")" = 4
    _ASSERT -v "last pos of special char" "$(_strings.list.last_index_of ",10,11,12,*,13" "*")" = 4
  )
  
  ( _IT "should properly get the last char of a string"
    _ASSERT -v "last char of simple string" "$(_strings.last_char_of "123")" = "3"
    _ASSERT -v "last char of one-char string" "$(_strings.last_char_of "1")" = "1"
    _ASSERT -v "last char of empty string" "$(_strings.last_char_of "")" = ""
  )
  
  ( _IT "should properly chop a string"
    _ASSERT -v "unconditional chop of a simple string" "$(_strings.chop "123")" = "12"
    _ASSERT -v "unconditional chop one-char string" "$(_strings.chop "1")" = ""
    _ASSERT -v "unconditional chop of empty string" "$(_strings.chop "")" = ""
    _ASSERT -v "conditional chop of simple string (satisfied)" "$(_strings.chop "123" "3")" = "12"
    _ASSERT -v "conditional chop of simple string (not satisfied)" "$(_strings.chop "123" "X")" = "123"
  )
  
  ( _IT "should properly lower a string"
    _ASSERT -v "lowered string" "$(_strings.lower "ABC123 A X aX \$X\$")" = "abc123 a x ax \$x\$"
    _ASSERT -v "lowered string" "$(_strings.lower "")" = ""
  )
}
