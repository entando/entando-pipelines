#!/bin/bash

# ITERATES THE COMMAND LINE AND EXECUTE THE PIPELINE COMMANDS IN THE FORMAT:
#
#   {COMMAND} {PARAMS} --AND {COMMAND} {PARAMS} --AND {COMMAND} {PARAMS} etc
#
# If COMMAND if prefixed with "@" the command error is ignored.
#

# shellcheck disable=SC1090
if [ -n "$GITHUB_ACTIONS" ]; then
  # shellcheck disable=SC1090
  while read -r fn; do
    source "$fn"
  done < <(find "$HOME/.entando/ppl/entando-pipelines/macro" -mindepth 2 -type f -iname "*.sh")
  [ "$1" = "--activate" ] && return 0
else
  echo "Unsupported Pipeline implementation" 1>&2
  [ "$1" = "--activate" ] && return 77
  exit 77
fi

(
  CMD=()
  IE=false  # ignore command error
  ELEM="${1:-}"
  shift

  while [ -n "$ELEM" ]; do
    if [ "${#CMD[@]}" = 0 ]; then
      if [ "${ELEM:0:1}" = "@" ]; then
        IE=true
        ELEM="${ELEM:1}"
      else
        IE=false
      fi
      CMD+=("ppl--$ELEM")
    else
      CMD+=("$ELEM")
    fi
    
    ELEM="${1:-}"
    shift

    if [ "$ELEM" = "--AND" ] || [ -z "$ELEM" ]; then
      "${CMD[@]}" || $IE || exit $?
      CMD=()
      ELEM="${1:-}"
      IE=false
      shift
    fi
  done
  
  exit 0
)
