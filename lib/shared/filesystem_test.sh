#/bin/bash

_sys.require "$PROJECT_DIR/lib/shared/filesystem.sh"

#TEST:unit,lib,fs
_fs.test.must.cd() {

  ( _IT "must enter an existing dir"

    mkdir "my-dir"
    _fs.must.cd "my-dir"
    _ASSERT PWD ends-with "my-dir" 
  )

  ( _IT 'should support "-"'
    
    mkdir -p "my-dir/my-sub-dir"
    _fs.must.cd "my-dir"
    _fs.must.cd "my-sub-dir"
    _ASSERT PWD ends-with "my-sub-dir"
    _fs.must.cd -
    _ASSERT PWD ends-with "my-dir" 
  )

  ( _IT "should fatal if the dir doesn't exists" SUPPRESS-ERRORS
    
    (_fs.must.cd "not-my-dir") && _FAIL
  )
  
  ( _IT 'should fatal if the dir name is null, or "."' SUPPRESS-ERRORS
    
    (_fs.must.cd "";exit 0) && _FAIL "<null dir>"
    (_fs.must.cd ".";exit 0) && _FAIL "."
  )
}


#TEST:unit,lib,fs
_fs.test.must.exist() {

  ( _IT "must be successful if dir exists and it's looking for dirs"

    mkdir -p "my-dir"
    _fs.must.exist -d "my-dir"
  )
  
  ( _IT "must fatal if dir exists but it's looking for files" SUPPRESS-ERRORS

    mkdir -p "my-dir"
    (_fs.must.exist -f "my-dir";exit 0) && _FAIL "."
  )

  ( _IT "must be successful if file exists and it's looking for files"

    echo "my-file" > "my-file"
    _fs.must.exist -f "my-file"
  )
  
  ( _IT "must fatal if dir exists but it's looking for files" SUPPRESS-ERRORS

    echo "my-file" > "my-file"
    (_fs.must.exist -d "my-file";exit 0) && _FAIL "."
  )

}

