#/bin/bash 

. "$PROJECT_DIR/lib/shared/filesystem.sh"
. "$PROJECT_DIR/lib/local/macro.sh"
 
#TEST:unit,lib,local,ppl
ppl.test.enter_local_clone_dir() {

  ( _IT "should properly enter if the dir exists"

    PPL_LOCAL_CLONE_DIR="local_clone"
    mkdir "$PPL_LOCAL_CLONE_DIR"
    ppl.enter_local_clone_dir
    _ASSERT PWD ends-with "local_clone" 
  )

  ( _IT "should fatal if the dir doesn't exist" SUPPRESS-ERRORS

    (PPL_LOCAL_CLONE_DIR="unexisting_dir" ppl.enter_local_clone_dir) && _FAIL
  )
}
