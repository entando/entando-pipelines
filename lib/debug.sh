#!/bin/bash

_log_t() { _log TRACE "$@"; }
_log_d() { _log DEBUG "$@"; }
_log_i() { _log INFO "$@"; }
_log_w() { _log WARN "$@"; }
_log_e() { _log ERROR "$@"; }

_log_on_level() {
  SY=$1; shift
  _to_nll RNLL "$ENTANDO_OPT_LOG_LEVEL"
  _to_nll INLL "$SY"
  if [ "$INLL" -lt "$RNLL" ]; then
    return 1
  else
    return 0
  fi
}

_log() {
  SY=$1; shift

  _to_nll RNLL "$ENTANDO_OPT_LOG_LEVEL"
  _to_nll INLL "$SY"
  [ "$INLL" -lt "$RNLL" ] && return 0     # I've considered returning "1" but it has too many consequences

  local B A
  "${ENTANDO_OPT_NO_COL:-true}" && _to_col B A "$SY"

  printf "➤ $B%-5s | %s | %s$A\n" "$SY" "$(date +'%Y-%m-%d %H-%M-%S')" "$*"
  return 0
}

_to_nll() {
  local _tmp_
  case "$2" in
    TRACE) _tmp_=1;;
    DEBUG) _tmp_=2;;
    INFO) _tmp_=3;;
    WARN) _tmp_=4;;
    ERROR) _tmp_=5;;
    *) _tmp_=3;
  esac
  _set_var "$1" "$_tmp_"
}

_to_col() {
  case "$3" in
    ERROR)
      #_set_var "$1" '\033[41m\033[1;37m'
      _set_var "$1" '\033[41m\033[1;97m'
      _set_var "$2" '\033[0;39m'
    ;;
    WARN)
      _set_var "$1" '\033[43m\033[1;37m'
      _set_var "$2" '\033[0;39m'
    ;;
  esac
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
_print_callstack() {
  if [[ "$1" == "-d" && -n "$ENTANDO_DEBUG_TTY" ]]; then
    shuft
    _print_callstack "$@" >"$ENTANDO_DEBUG_TTY"
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

# Prints the current function name with decorations
#
# Params:
# $1  prefix decoration
# $2  suffix decoration
#
print_current_function_name() {
  _log_i "${1}${FUNCNAME[1]}${2}"
}

# Pretty debug prints of variables
#
# Params:
# [-d]       prints to the debug tty
# [-t title] also print a title
# - all params are optional and accept ""
#
# Params:
# $@  a list of variable names to pretty print (so without dereference operator "$")
#
_pp() {
  if [[ "$1" == "-d" && -n "$ENTANDO_DEBUG_TTY" ]]; then
    shuft
    _pp "$@" >"$ENTANDO_DEBUG_TTY"
  fi

  if [ "$1" == "-t" ]; then
    local TITLE=" [$2]"
    shift 2
  fi
  echo "▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁"
  echo "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒$TITLE"
  for var_name in "$@"; do
    (echo "▕- $var_name: ${!var_name}")
  done
  echo "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"
  echo "▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔"
}

# Adjust a variable for pretty printing
#
# Params:
# $1: the variable to cut
# $2: the max len
#
_pp_adjust_var() {
  local _tmp_="${!1}"

    local B='\033[44m\033[1;37m'
    local A='\033[0;39m'

  if [ ${#_tmp_} -gt "$2" ]; then
    _tmp_="${_tmp_:0:$2}${B}[[CUTTED]]${A}"
  fi
  _set_var "$1" "$_tmp_"
}

# Validates for non-null a list of mandatory variables
# Fatals if a violation is found
#
_NONNULL() {
  for var_name in "$@"; do
    local var_value="${!var_name}"
    [ -z "$var_value" ] && _FATAL -S 1 "${FUNCNAME[1]}> Variable \"$var_name\" should not be null"
  done
}

# Verifies a condition
#
# Expects a value to match an expected value according with an operator.
# If the verification fails an error and a callstack are printed.
# The function assumes to be wrapped so it skips 2 levels of the callstack.
#
# Syntax1 - Params:
# $1: The error messages prefix
# $2: Name of the variable containing the value to test
# $3: Operator
# $4: expected value
#
# Syntax2 - Params:
# $1: The error messages prefix
# $2: -v
# $3: A description of value
# $4: A value to test
# $5: Operator
# $6: expected value
#
__VERIFY_EXPRESSION() {
  local PREFIX="${1:+"$1>" }"; shift
  local A B
  local CENSOR=false;[ "$1" = "--censor" ] && { CENSOR=true; shift; }
  if [ "$1" = "-v" ]; then
    shift
    N="$1"; E="$2"; O=$3; V=$4
    shift 4
  else
    N="$1";
    (E="${!N}") || _FATAL -S 2 "Invalid variable name"
    E="${!N}"; O=$2; V=$3
    shift 4
  fi

  case "$O" in
    -eq) O="==";OD="TO:  ";  [[ "$E" -eq "$V" ]];;
    -ne) O="!=";OD="TO:  ";  [[ "$E" -ne "$V" ]];;
    -gt) O=">";OD="THAN:";   [[ "$E" -gt "$V" ]];;
    -ge) O=">=";OD="THAN:";  [[ "$E" -ge "$V" ]];;
    -lt) O="<";OD="THAN:";   [[ "$E" -lt "$V" ]];;
    -le) O="<=";OD="THAN:";  [[ "$E" -le "$V" ]];;
    =|==) O="=";OD="TO:  ";  [[ "$E" = "$V" ]];;
    !=) O="!=";OD="TO:  ";  [[ "$E" != "$V" ]];;
    =~) O="=~";OD="TO:  ";   [[ "$E" =~ $V ]];;
    starts-with) O="=";OD="TO:  ";  [[ "$E" = "$V"* ]];;
    *) _FATAL "Unknown operator \"$O\"";;
  esac

  if [ $? != 0 ]; then
    #local ln fn fl
    #read -r ln fn fl < <(caller "1")

    echo ""

    local MSG MSG2

    if ! $CENSOR; then
      _pp_adjust_var E 250
      _pp_adjust_var V 250

      if [ "${#E}" -gt 30 ] || [ "${#V}" -gt 30 ]; then
        MSG="Validation Failed"
        MSG2="\n${PREFIX}Validation Failed in:\n> EXPECTED:  $N"
        MSG2+="\n> TO BE:     $O\n> $OD      $V\n\n> BUT WAS FOUND: $E"
      else
        MSG="Validation Failed"
        MSG2="\n${PREFIX}Expected $N $O \"$V\" but instead I've found \"$E\""
      fi
    else
        local B='\033[44m\033[1;37m'
        local A='\033[0;39m'
        MSG="Validation Failed"
        MSG2="\n${PREFIX}Expected $N $O ${B}[[CENSORED]]${A} but instead I've found ${B}[[CENSORED]]${A}"
    fi

    [ -n "$MSG2" ] && echo -e "$MSG2" 1>&2
    _FATAL -S 2 -99 "$MSG" 1>&2
  fi
}

# See __VERIFY_EXPRESSION
#
__VERIFY() {
  __VERIFY_EXPRESSION "" "$@"
}

# A defensive verify is a shield against dangerous bugs and conditions.
#
# Developers should never remove a defensive check just because the
# condition tested can't fail according to the (current) code.
#
# For the syntax see __VERIFY_EXPRESSION
#
__DEFENSIVE_VERIFY() {
  __VERIFY_EXPRESSION "DEFENSIVE-CHECK>" "$@"
}

# Drops a shell that inherits the caller environment
#
DBGSHELL() {
  SKIP=0;[ "$1" = "-S" ] && { SKIP="$2"; shift 2; }
  (
    $IN_TTY && {
     _log_w "Refusing to drop shell because this is not an interactive tty session"
     exit 0
    }

    _log_i 'DROPPING THE DEBUG SHELL FROM:' 1>&2
    _print_callstack "$SKIP" 5 "" "" "$@" 1>&2
    
    (
      read -r ln fn fl < <(caller "$SKIP")
      sed -n "$((ln-4))"',$p' "$fl" | head -5
    )
    echo -e "\n▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔"
    
    # Export the current vars and functions
    {
      local fn var

      while read -r fn; do
        # shellcheck disable=SC2163
        export -f "$fn"
      done < <(compgen -A function)
      while read -r var; do
        [ "$var" = "SHELLOPTS" ] && continue
        # shellcheck disable=SC2163
        export "$var"
      done < <(compgen -v)
    } &> /dev/null

    # Create copy of the bashrc
    if [ -f "$HOME/.profile" ]; then
      cp "$HOME/.profile" "$TEST__WORK_DIR/.bashrc"
    else
      [ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$TEST__WORK_DIR/.bashrc"
    fi

    {
      echo -e "\n#\n#\n#\n"
      COMMENT="";[ -n "$1" ] && COMMENT=" with comment: \"$1\""
      # shellcheck disable=SC2028
      echo "echo -e '\033[43m\033[1;30m> DEBUG SHELL STARTED$COMMENT\033[0;39m\n' 1>&2"
      echo -e "true"
    } >> "$TEST__WORK_DIR/.bashrc"

    # Run the shell
    bash --rcfile "$TEST__WORK_DIR/.bashrc" < /dev/tty > /dev/tty

  ) || {
    [ "$?" = "77" ] && _FATAL "Execution Interrupted: Debug Shell terminated with fatal error" >/dev/tty
  }
}
