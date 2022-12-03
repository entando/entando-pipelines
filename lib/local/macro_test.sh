#/bin/bash 

_require "$PROJECT_DIR/lib/local/macro.sh"
 
#TEST:unit,lib,local,ppl
ppl.test.enter_local_clone_dir() {

  ( _IT "should properly enter if the dir exists"

    PPL_LOCAL_CLONE_DIR="local_clone"
    mkdir "$PPL_LOCAL_CLONE_DIR"
    ppl.enter_local_clone_dir
    _ASSERT PWD ends-with "local_clone" 
  )

  ( _IT "should fatal if the dir doesn't exist" SILENCE-ERRORS

    (PPL_LOCAL_CLONE_DIR="unexisting_dir" ppl.enter_local_clone_dir) && _FAIL
  )
}


#TEST:unit,macro.ppl
ppl.test.safe-dynamic-invokation() {

  macro.mvn.full-build() {
    exit 101
  }
  
  macro.mvn.full-build-ext() {
    exit 101
  }
  
  local AUTH=( "macro.mvn.full-build" )

  ( _IT "shoud run an allowed invocation"
    
    ppl.safe-dynamic-invokation AUTH "mvn" full-build
    _ASSERT_RC 101
  )

  ( _IT "shoud not run a not allowed invocation" SILENCE-ERRORS
    
    ppl.safe-dynamic-invokation AUTH "mvn" full-build-ext
    _ASSERT_RC 77
  )
}
