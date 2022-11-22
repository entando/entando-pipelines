#!/bin/bash

_sys.require "macro/agnostic/do.sh"

#TEST:unit,macro,do,x
ppl--do.test() {
  
  mkdir "local_clone"
  __cd "local_clone"
  touch "package.json"
  __cd -
  
  macro.npm.full-build() {
    exit 101
  }

  
  ( _IT "shoud enter the local_clone and decode determine the project type"
    
    (ppl--do FULL-BUILD --lcd "local_clone")
    _ASSERT_RC 101
  )
  
}

#TEST:unit,macro,do
ppl--do.test.safe-dynamic-invokation() {

  macro.npm.full-build() {
    exit 101
  }
  
  macro.npm.full-build-ext() {
    exit 101
  }

  ( _IT "shoud run an allowed invocation"
    
    (ppl--do.safe-dynamic-invokation "NPM" FULL-BUILD; exit 0)
    _ASSERT_RC 101
  )

  ( _IT "shoud not run a not allowed invocation" SUPPRESS-ERRORS
    
    (ppl--do.safe-dynamic-invokation "NPM" FULL-BUILD-EXT; exit 0)
    _ASSERT_RC 77
  )
}
