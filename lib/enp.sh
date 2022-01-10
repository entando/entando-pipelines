#!/bin/bash

_enp_get() {
  local VAR_NAME VAR_VALUE
  _enp_get_prop_var_name VAR_NAME "$2"
  VAR_VALUE="$(_enp_load; echo "${!VAR_NAME}")"
  _set_var "$1" "${VAR_VALUE}"
}

_enp_set() {
  local VAR_NAME
  _enp_determine_project_file_name
  _enp_get_prop_var_name VAR_NAME "$1"
  sed -i -e "s/$VAR_NAME=.*/$VAR_NAME=$2/g" "$ENTANDO_PRJ_FILE"
}

##

_enp_get_prop_var_name() {
  case "$2" in
    "name") _set_var "$1" "ENTANDO_PRJ_NAME";;
    "version") _set_var "$1" "ENTANDO_PRJ_VERSION";;
    *) _FATAL "Unknown property \"$2\"";;
  esac
}

_enp_determine_project_file_name() {
  [ -f "./ent/ent-prj" ] && ENTANDO_PRJ_FILE="./ent/ent-prj"
  [ -f "entando-project" ] && ENTANDO_PRJ_FILE="entando-project"
}

_enp_load() {
  _enp_determine_project_file_name
  [ -n "$ENTANDO_PRJ_FILE" ] && {
    _ppl_load_settings --var-sep $'\n' --stdin < "$ENTANDO_PRJ_FILE"
    # shellcheck disable=SC2034
    ENTANDO_PRJ_LOADED=true
  }
}

