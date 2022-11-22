#/bin/bash

_sys.require "$PROJECT_DIR/lib/local/project.sh"
 
#TEST:unit,lib,local,prj
prj.test.current.determine_type() {

  ( _IT "should be able to determine the type of the project"

    touch "pom.xml" && _ASSERT -v "PROJECT TYPE" "$(prj.current.determine_type)" = "MVN"
    rm "pom.xml"

    touch "package.json" && _ASSERT -v "PROJECT TYPE" "$(prj.current.determine_type)" = "NPM"
    rm "package.json"  

    touch "entando-project" && _ASSERT -v "PROJECT TYPE" "$(prj.current.determine_type)" = "ENP"
    rm "entando-project"
  )
  
  ( _IT "should be able to determine the type of the project indirectly"

    echo "PROJECT_TYPE=npm" > "entando-project"
    _ASSERT -v "PROJECT TYPE" "$(prj.current.determine_type)" = "npm"
    rm "entando-project"
  )


  ( _IT "should fatal if project type can't be determined" SUPPRESS-ERRORS

    touch "entando-pipelines" "entando-project.json" "package" "package json" "pom" "pom.json" "pom_xml" "package.xml"
    (prj.current.determine_type) && _FAIL
  )
}


#TEST:unit,lib,local,prj
prj.test.get_config_value() {
  ( _IT "should be able to read simple and quoted config values"
  
    touch tmp
    echo 'VAR1=VALUE1' >> tmp
    echo 'VAR2="VALUE2"' >> tmp
    
    _ASSERT -v "CONFIG VALUE" \
      "$(prj.get_config_value tmp "VAR1")" = "VALUE1"
      
    _ASSERT -v "CONFIG VALUE" \
      "$(prj.get_config_value tmp "VAR2")" = "VALUE2"
  )
  
  ( _IT "should properly handle spaces"
  
    touch tmp
    echo 'VAR1= VALUE1 ' >> tmp
    echo 'VAR2=" VALUE2 "' >> tmp
    
    _ASSERT -v "CONFIG VALUE" \
      "$(prj.get_config_value tmp "VAR1")" = " VALUE1 "
      
    _ASSERT -v "CONFIG VALUE" \
      "$(prj.get_config_value tmp "VAR2")" = " VALUE2 "
  )

  ( _IT "should properly handle slashes"
  
    touch tmp
    echo 'VAR1= VA/LUE1 ' >> tmp
    echo 'VAR2=" VA/LUE2 "' >> tmp
    
    _ASSERT -v "CONFIG VALUE" \
      "$(prj.get_config_value tmp "VAR1")" = ' VA/LUE1 '
      
    _ASSERT -v "CONFIG VALUE" \
      "$(prj.get_config_value tmp "VAR2")" = ' VA/LUE2 '
  )
  
  ( _IT "should read the value of the last matching assignment in the file (in case of duplicates)"
  
    touch tmp
    echo 'VAR=VALUE1' >> tmp
    echo 'VAR="VALUE2"' >> tmp
    
    _ASSERT -v "CONFIG VALUE" \
      "$(prj.get_config_value tmp "VAR")" = "VALUE2"
  )
  
}
