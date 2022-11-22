#/bin/bash

_sys.require "lib/shared/cli.sh"

#TEST:unit,lib,cli,x
_cli.test.parse_args() {

  
  _cli.parse_args "-g -h -i" pos1 -n 101 --opt1=OPT1 pos2 pos3 --opt2 OPT2 -g -h pos4 -- --pos5 pos6 -p
  
  ( _IT "should properly handle positional arguments"
    
    _cli.get_arg RES 1 || _FAIL; _ASSERT RES = pos1
    _cli.get_arg RES 2 || _FAIL; _ASSERT RES = pos2
    _cli.get_arg RES 3 || _FAIL; _ASSERT RES = pos3
    _cli.get_arg RES 4 || _FAIL; _ASSERT RES = pos4
    _cli.get_arg RES 5 || _FAIL; _ASSERT RES = --pos5
    _cli.get_arg RES 6 || _FAIL; _ASSERT RES = pos6
    _cli.get_arg RES 7 || _FAIL; _ASSERT RES = -p
    _cli.get_arg RES 8 && _FAIL; _ASSERT RES = ""
    _cli.get_arg RES 8 FB  || _FAIL; _ASSERT RES = FB
  )
  
  ( _IT "should support the shift of the positional arguments"
    
    _cli.shift_positional_args 1
    _cli.get_arg RES 1 || _FAIL; _ASSERT RES = pos2
    _cli.get_arg RES 7 && _FAIL; _ASSERT RES = ""
  )
  
  ( _IT "should properly handle long optional arguments"
    
    _cli.get_arg RES --opt1 || _FAIL; _ASSERT RES = OPT1
    _cli.get_arg RES --opt2 || _FAIL; _ASSERT RES = OPT2
    _cli.get_arg RES --opt3 && _FAIL; _ASSERT RES = ""
    _cli.get_arg RES --opt3 FB || _FAIL; _ASSERT RES = FB
  )
  
  ( _IT "should properly handle short optional arguments"
    
    _cli.get_arg RES -n || _FAIL; _ASSERT RES = 101
  )

  ( _IT "should properly handle flags"
    
    _cli.get_arg RES -g || _FAIL; _ASSERT RES = true
    _cli.get_arg RES -h || _FAIL; _ASSERT RES = true
    _cli.get_arg RES -i || _FAIL; _ASSERT RES = false
  )

}