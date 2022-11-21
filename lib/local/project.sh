#/bin/bash
 
prj.curremt.determine_type() {
  local _tmp_
  
  if [[ -f ".ent/ent-prj" || -f "entando-project" ]]; then
    _tmp_="ENP"
  elif [ -f "pom.xml" ]; then
    _tmp_="MVN"
  elif [ -f "package.json" ]; then
    _tmp_="NPM"
  else
    _FATAL "Unable to determine the project type"
  fi

  if [ "$1" == "--print" ]; then
    echo "$_tmp_"
  elif [ "$1" == "--check" ]; then
    true
  else
    _set_var "$1" "$_tmp_"
  fi
}
