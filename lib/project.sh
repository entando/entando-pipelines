#!/bin/bash

# Extacts the version of a artifactId from a pom
#
# Params:
# $1: dest var
# $3: project file pathname
#
_ppl_get_current_project_version() {
  case "$(_ppl_determine_current_project_type --print)" in
    "MVN") _pom_get "$1" "${2:-pom.xml}" "/pom:project" "./pom:version";;
    "NPM") _npm_get "$1" "${2:-package.json}" "version";;
    *) _FATAL  "Unable to detect the project type"
  esac
}

#!/bin/bash

# Extacts the version of a artifactId from a pom
#
# Params:
# $1:   the value to ser
# [$2]: the optional project file pathname
#
_ppl_set_current_project_version() {
  case "$(_ppl_determine_current_project_type --print)" in
    "MVN") _pom_set_project_property "$@";;
    "NPM") _npm_set "${2:-package.json}" "version" "$1";;
    *) _FATAL  "Unable to detect the project type"
  esac
}

# Extacts the version of a artifactId from a pom
#
# Params:
# $1: dest var
# [$2]: the optional project file pathname
#
_ppl_get_current_project_artifact_id() {
  case "$(_ppl_determine_current_project_type --print)" in
    "MVN") _pom_get "$1" "${2:-pom.xml}" "/pom:project" "./pom:artifactId";;
    "NPM") _npm_get "$1" "${2:-package.json}" "name";;
    *) _FATAL  "Unable to detect the project type"
  esac
}
