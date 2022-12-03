#!/bin/bash

_require "$PROJECT_DIR/lib/shared/sys.sh"

[ "$_SYS_TEST_ENABLE" == "true" ] && {
  ((VAR++))
}

#TEST:unit,lib,sys
_sys.test.must.nn() {
  local A=1 B=""
  ( _IT "should accept non null value"; _sys.must.nn A)
  ( _IT "shout fatal for a null/empty value" SILENCE-ERRORS; _sys.must.nn B 2>/dev/null)
  ( _IT "shout fatal for at least one null/empty value" SILENCE-ERRORS; _sys.must.nn A B 2>/dev/null)
}

#TEST:unit,lib,sys
_sys.test.soe() {
  
  ( _IT "should stop on error" SILENCE-ERRORS
    
    (false; _sys.soe) && _FAIL
  )
  
  ( _IT "should not stop if no error"
    
    (true; _sys.soe) || _FAIL
  )
  
  ( _IT "should stop on error in checked pipe segment" SILENCE-ERRORS

    # FALSE|FALSE
    (false | false; _sys.soe) && _FAIL
    (false | false; _sys.soe --pipe 0) && _FAIL
    (false | false; _sys.soe --pipe 1) && _FAIL

    # FALSE|TRUE
    (false | true; _sys.soe --pipe 0) && _FAIL

    # TRUE|FALSE
    (true | false; _sys.soe) && _FAIL
    (true | false; _sys.soe --pipe 1) && _FAIL
  )
  
  ( _IT "should not stop if error is not in checked pipe segment"

    # TRUE|TRUE
    (true | true; _sys.soe) || _FAIL
    (true | true; _sys.soe --pipe 0) || _FAIL
    (true | true; _sys.soe --pipe 1) || _FAIL

    # FALSE|TRUE
    (false | true; _sys.soe) || _FAIL
    (false | true; _sys.soe --pipe 1) || _FAIL

    # TRUE|FALSE
    (true | false; _sys.soe --pipe 0) || _FAIL
  )
}
