#!/bin/bash

_require "macro/agnostic/do.sh"

#TEST:unit,macro,do
ppl.do.test.run() {
  
  mkdir "local-clone"
  __cd "local-clone"
  touch "pom.xml"
  __cd -
  
  macro.mvn.full-build() {
    exit 101
  }

  ( _IT "shoud enter the local-clone and determine the project type and run the macro function"
    
    (macro.do.run FULL-BUILD --lcd "local-clone"; exit 0)
    _ASSERT_RC 101
  )
  
}

#TEST:unit,macro,do
macro.do.test.safe-dynamic-invokation() {

  macro.mvn.full-build() {
    exit 101
  }
  
  macro.mvn.full-build-ext() {
    exit 101
  }
  
  local AUTH=( "macro.mvn.full-build" )

  ( _IT "shoud run an allowed invocation"
    
    (macro.do.safe-dynamic-invokation AUTH "MVN" FULL-BUILD; exit 0)
    _ASSERT_RC 101
  )

  ( _IT "shoud not run a not allowed invocation" SUPPRESS-ERRORS
    
    (macro.do.safe-dynamic-invokation AUTH "MVN" FULL-BUILD-EXT; exit 0)
    _ASSERT_RC 77
  )
}
