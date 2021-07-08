#!/bin/bash

# Extacts the artifactId from a pom
#
# Params:
# $1: dest var
# $2: pom file pathname
#
_pom_get_project_artifact_id() {
  _pom_get "$1" "$2" "/pom:project" "./pom:artifactId"
}

# Extacts the version of a artifactId from a pom
#
# Params:
# $1: dest var
# $2: pom file pathname
#
_pom_get_project_version() {
  _pom_get "$1" "$2" "/pom:project" "./pom:version"
}


# Sets the version of a artifactId from a pom
#
# Params:
# $1: new version
# $2: pom file pathname
#
_pom_set_project_version() {
  _pom_set "$1" "$2" "/pom:project" "./pom:version"
}

# Extacts a property from a pom
#
# Params:
# $1: dest var
# $2: pom file pathname
# $3: property name
#
_pom_get_project_property() {
  _pom_get "$1" "$2" "/pom:project/pom:properties" "./pom:$3"
}

# Sets a property from a pom
#
# Params:
# $1: new value
# $2: pom file pathname
# $3: property name
#
_pom_set_project_property() {
  _pom_set "$1" "$2" "/pom:project/pom:properties" "./pom:$3"
}

# Extacts the version of an artifact dependency of the dependency management section
#
# Params:
# $1: dest var
# $2: pom file pathname
# $3: the artifact id
#
_pom_get_depman_artifact_version() {
  _pom_get "$1" "$2" \
    "/pom:project/pom:dependencyManagement/pom:dependencies/pom:dependency[pom:artifactId='$3']" \
    "./pom:version"
}

# Sets a pom property
#
# Params:
# $1 the receiver var
# $2 the pom file
# $3 the XML path of the property to set
# $4 the property name
#
_pom_get() {
  local _tmp_
  _tmp_="$(xmlstarlet sel -N pom="http://maven.apache.org/POM/4.0.0" -t -m "$3" -v "$4" "$2")"
  _log_t "> POM: $3/$4 => \"$_tmp_\""
  _set_var "$1" "$_tmp_"
}

# Sets a pom property
#
# Params:
# $1 the value to set
# $2 the pom file
# $3 the XML path of the property to set
# $4 the property name
#
_pom_set() {
  xmlstarlet ed --inplace -P -N pom="http://maven.apache.org/POM/4.0.0" \
    --update "$3/$4" \
    -v "$1" "$2"
  _log_t "> POM: $3/$4 <= \"$1\""
}

# Extracts artifact id and artifact version from the pom.xml of the received dir and sets 2 relative vars
#
# Params:
# $1 the directory containing the pom.xml file
# $2 the name of the variable in which set the artifact id
# $3 the name of the variable in which set the artifact version
#
_extract_project_information_from_pom() {
  __cd "$1"
  __exist -f "pom.xml"
  _pom_get_project_artifact_id "$2" "pom.xml"
  _pom_get_project_version "$3" "pom.xml"
}
