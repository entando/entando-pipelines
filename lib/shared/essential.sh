#/bin/bash

#~##########################################~#
# WARNING:                                   #
# ESSENTIAL MUST NEVER INCLUDE OTHER MODULES # 
#~##########################################~#

# Stops the execution of the program
# In normal conditions is just equivalent to exit
# but if XDEV_STOP_ON_EXIT is true it uses a SIGING
#
_sys.exit() {
  if [ "$XDEV_STOP_ON_EXIT" == "true" ]; then
    kill -INT $$
  else
    exit "$@"
  fi
}

# Stops the execution with a fatal error
# and prints the callstack
#
# Options
# [-s]  simple: omits the stacktrace
# [-S n] skips n levels of the call stack
# [-99] uses 99 as exit code, which indicates test assertion
#
# Params:
# $1  error message
#
_sys.fatal() {
  set +x
  local rv=77
  
  if [ "$_ESS_SILENCE_ERRORS" != "true" ]; then
    {
      # shellcheck disable=SC2076
      if [[ -n "$TEST__EXPECTED_ERROR" && "$*" =~ "$TEST__EXPECTED_ERROR" ]]; then
        LOGGER() { _ess.log "DEBUG" "==== EXPECTED ERROR DETECTED ====: $*" 1>&2; }
      else
        LOGGER() { _ess.log "ERROR" "$*" 1>&2; }
      fi

      if [ "$1" != "-s" ]; then
        local SKIP=1;[ "$1" = "-S" ] && { SKIP="$((SKIP+1))"; shift 2; }
        [ "$1" = "-99" ] && shift && rv=99
        _sys.print_callstack "$SKIP" 5 "" LOGGER "$@"  1>&2
      else
        shift
        [ "$1" = "-99" ] && shift && rv=99
        LOGGER "$@"
      fi
    }
  fi

  _exit "$rv"
}


# Prints the current callstack
#
# Options
# [-d] to debug tty
# [-n] doesn't print the decoration frame
#
# Params:
# $1  start from this element of the start
# $2  number of start
# $3  title
# $4  print command to use
#
_sys.print_callstack() {
  if [[ "$1" == "-d" && -n "$ENTANDO_DEBUG_TTY" ]]; then
    shift
    _sys.print_callstack "$@" >"$ENTANDO_DEBUG_TTY"
  fi
  local NOFRAME=false
  [ "$1" = "-n" ] && {
    NOFRAME=true
    shift
  }

  local start=0
  local steps=999
  local title=""
  [ -n "$1" ] && start="$1"
  [ -n "$2" ] && steps="$2"
  [ -n "$3" ] && title=" $3 "
  ((start++))

  local frame=0 fn ln fl
  if [ -n "$4" ]; then
    ! $NOFRAME && {
      echo ""
      [ -n "$title" ] && echo " ▕ $title ▏"
      echo "▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔"
    }
    cmd="$4"
    shift 4
    "$cmd" "$@"
  else
    ! $NOFRAME && {
      echo -e "▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁"
      [ -n "$title" ] && echo " ▕ $title ▏"
    }
  fi
  ! $NOFRAME && echo "▁"
  while read -r ln fn fl < <(caller "$frame"); do
    ((frame++))
    [ "$frame" -lt "$start" ] && continue
    printf "▒- %s in %s on line %s\n" "${fn}" "${fl}" "${ln}" 2>&1
    ((steps--))
    [ "$steps" -eq 0 ] && break
  done
  echo "▔"
  ! $NOFRAME && {
    echo "▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔"
  }
}

_ess.low_level_fatal() {
  local SKIP=1;[ "$1" = "-S" ] && { SKIP="$((SKIP+$2))"; shift 2; }
  
  [ "$_ESS_SILENCE_ERRORS" !=  "true" ] && {
    if [[ -n "$TEST__EXPECTED_ERROR" && "$*" =~ $TEST__EXPECTED_ERROR ]]; then
      _ess.logger_fn() { _ess.log "DEBUG" "==== EXPECTED ERROR DETECTED ====: $*"; }
    else
      _ess.logger_fn() { _ess.log "ERROR" "$*"; }
    fi
    _ess.logger_fn "$*"
    _ess.simple_print_callstack "$SKIP" 5 "" _ess.logger_fn "$@" 1>&2
  }
  _exit 66
}

_ess.log() {
  printf "➤ %-5s | %s | %s\n" "$1" "$(date +'%Y-%m-%d %H-%M-%S')" "$*" 1>&2
  return 0
}

_ess.simple_print_callstack() {
  local frame=0 fn ln fl start=0
  
  while read -r ln fn fl < <(caller "$frame"); do
    ((frame++))
    [ "$frame" -lt "$start" ] && continue
    printf "▒- %s in %s on line %s\n" "${fn}" "${fl}" "${ln}" 2>&1
    ((steps--))
    [ "$steps" -eq 0 ] && break
  done
}


# Reads a configuration value from an enp configuration file.
#
# An ENP configuration is a multiline sequence of rows.
# Multiline values are not supported.
#
# Row Format: 
# - key: identifier
# - sep: the leftmost symbol "="
# - val: a sequence of any char except for the linefeed
#
_xdev.get-config() {
  local res="$(grep "^$1=" ".xdev" | sed 's/[^=]*=//')"
  echo "${res:-$2}";
}
