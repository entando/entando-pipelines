#!/bin/bash

#TEST:unit,lib,sys,ess
_sys.test.fatal() {
  ( _IT "should be able to find pattern string in function output"
  
    _ASSERT -v "FATAL-MESSAGE" "$(_FATAL "FATAL-ERROR-TEST" 2>&1)" contains "FATAL-ERROR-TEST"
  )
}

#TEST:unit,lib,sys,ess
_sys.test._exit() {
  ( _IT "should exit with the correct exit code"
  
    (_exit 101; exit 33)
    _ASSERT_RC "101"
  )
}

#TEST:unit,lib,sys,ess
_sys.test.require() {

  VAR=0
  mkdir lib
  echo "((VAR++))" > lib/mod1.sh
  echo "((VAR+=10))" > lib/mod10.sh
  echo "((VAR+=100))" > lib/mod100.sh
  _ASSERT VAR = 0
  
  ( _IT "should support pwd-relative path loading"
  
    cd lib
    _sys.require "mod1.sh"
    _ASSERT VAR = 1
    _sys.require "mod10.sh"
    _ASSERT VAR = 11
    _sys.require "mod100.sh"
    _ASSERT VAR = 111
  )
  
  ( _IT "should absolute path loading"
  
    _sys.require "$PWD/lib/mod1.sh"
    _ASSERT VAR = 1
    _sys.require "$PWD/lib/mod10.sh"
    _ASSERT VAR = 11
    _sys.require "$PWD/lib/mod100.sh"
    _ASSERT VAR = 111
  )
  
  ( _IT "should prevent double loading"
    _sys.require "lib/mod1.sh"
    _ASSERT VAR = 1
    _sys.require "lib/mod1.sh"
    _ASSERT VAR = 1
  )
  

}

