#!/bin/bash

_require "macro/agnostic/prj.sh"

#TEST:unit,macro,prj,x
ppl.prj.test.run() {
  
  mkdir "local-clone"
  __cd "local-clone"
  touch "pom.xml"
  __cd -
  
  macro.mvn.full-build() {
    exit 101
  }

  ( _IT "shoud enter the local-clone and determine the project type and run the macro function"
    
    (macro.prj.run FULL-BUILD --lcd "local-clone"; exit 0)
    _ASSERT_RC 101
  )
  
}
