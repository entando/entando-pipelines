#!/bin/bash

#TEST:unit,lib,ess
_sys.test._exit() {
  ( _IT "should exit with the correct exit code"
  
    (_exit 101; exit 33)
    _ASSERT_RC "101"
  )
}
