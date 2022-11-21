#!/bin/bash

_log.t() { _log TRACE "$@"; }
_log.d() { _log DEBUG "$@"; }
_log.i() { _log INFO "$@"; }
_log.w() { _log WARN "$@"; }
_log.e() { _log ERROR "$@"; }

_log.on_level() {
  SY=$1; shift
  RNLL="$(_log._to_nll "$ENTANDO_OPT_LOG_LEVEL")"
  INLL="$(_log._to_nll "$SY")"
  if [ "$INLL" -lt "$RNLL" ]; then
    return 1
  else
    return 0
  fi
}

_log() {
  [ "${ENTANDO_OPT_SILENT}" = "true" ] && return 0
  SY=$1; shift

  RNLL="$(_log._to_nll "$ENTANDO_OPT_LOG_LEVEL")"
  INLL="$(_log._to_nll "$SY")"
  [ "$INLL" -lt "$RNLL" ] && return 0     # I've considered returning "1" but it has too many consequences

  local B A
  "${ENTANDO_OPT_NO_COL:-true}" && {
    read -r A B < <(_log._to_col "$SY")
  }

  printf "➤ $B%-5s | %s | %s$A\n" "$SY" "$(date +'%Y-%m-%d %H-%M-%S')" "$*" 1>&2
  return 0
}

_log._to_nll() {
  local _tmp_
  case "$1" in
    TRACE) _tmp_=1;;
    DEBUG) _tmp_=2;;
    INFO) _tmp_=3;;
    WARN) _tmp_=4;;
    ERROR) _tmp_=5;;
    *) _tmp_=3;
  esac
  echo "$_tmp_"
}

_log._to_col() {
  local A B
  case "$1" in
    ERROR)
      if [ "$ENTANDO_OPT_COLORS" = "github" ]; then
        A='\e[1;30;41m'
      else
        A='\033[41m\033[1;97m'
      fi
      B='\033[0;39m'
    ;;
    WARN)
      if [ "$ENTANDO_OPT_COLORS" = "github" ]; then
        A='\e[1;30;43m'
      else
        A='\033[43m\033[1;37m'
      fi
      B='\033[0;39m'
    ;;
  esac
  
  echo "$A $B"
}
