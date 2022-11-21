#!/bin/bash

#TEST:unit,lib,sys
_sys.test._FATAL() {
  ( _IT "should be able to find pattern string in function output"
  
    _ASSERT -v "FATAL-MESSAGE" "$(_FATAL "FATAL-ERROR-TEST" 2>&1)" contains "FATAL-ERROR-TEST"
  )
}

#TEST:unit,lib,sys
_sys.test._exit() {
  ( _IT "should exit with the correct exit code"
  
    (_exit 101; exit 33)
    _ASSERT_RC "101"
  )
}

#TEST:unit,lib,sys
_sys.test._NONNULL() {
  local A=1 B=""
  ( _IT "should accept non null value"; _NONNULL A)
  ( _IT "shout fatal for a null/empty value" SUPPRESS-ERRORS; _NONNULL B 2>/dev/null)
  ( _IT "shout fatal for at least one null/empty value" SUPPRESS-ERRORS; _NONNULL A B 2>/dev/null)
}
