#!/bin/bash

# Setups the enviroment for a macro execution
#
# Params:
# $1 macro name
# $2 pipeline context to parse
# 
# shellcheck disable=SC2034
START_MACRO() {
  
  set +e
  
  ${ENTANDO_OPT_STEP_DEBUG:-false} && {
    set -x
  }

  NO_SKIP=false;[ "$1" = "--no-skip" ] && { NO_SKIP=true; shift; }

  EE_CURRENT_MACRO="$1"

  if [ "${EE_CURRENT_MACRO:0:1}" = "@" ]; then
    EE_CURRENT_MACRO_PREFIX="@"
    EE_CURRENT_MACRO="${EE_CURRENT_MACRO:1}"
    local comment="user macro "
  fi

  if _log_on_level DEBUG; then
    echo -e "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~~ ${comment}${EE_CURRENT_MACRO} invoked on $(date +'%Y-%m-%d %H-%M-%S')"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  else
    _log_i "~~ ${comment}${EE_CURRENT_MACRO} invoked"
  fi
  
  TEST_EXECUTION="${TEST_EXECUTION:-false}"
  ENTANDO_OPT_SUDO="${ENTANDO_OPT_SUDO:-"sudo"}"
  ENTANDO_OPT_LOG_LEVEL="${ENTANDO_OPT_LOG_LEVEL:-INFO}"
  ENTANDO_OPT_REPO_BOM_URL="${ENTANDO_OPT_REPO_BOM_URL}"
  
  _ppl-load-context "$2"
  
  #_pp EE_CLONE_URL ENTANDO_OPT_REPO_BOM_URL EE_HEAD_REF
  _ppl-pr-has-label "skip-${1,,}" && {
    if "$NO_SKIP"; then
      return 99
    else
      _EXIT "$1 skipped due to skip-label: \"skip-${1,,}\""
    fi
  }
}

# Sets a variable
#
# Params:
# - $1: variable to set
# - $2: value
_set_var() {
  [ -z "$1" ] && _FATAL "null var_name provided"
  if [ -z "$2" ]; then
    read -r -d '' "$1" <<< ""
  else
    read -r -d '' "$1" <<< "$2"
  fi
  return 0
}

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
      echo "▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁"
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

# Stops the execution with a fatal error
# and optionally prints the callstack
#
# Options
# [-s]  simple: omits the stacktrace
# [-S n] skips n levels of the call stack
# [-99] uses 99 as exit code, which indicates test assertion
#
# Params:
# $1  error message
#
_FATAL() {
  local rv=77
  if [ "$1" != "-s" ]; then
    SKIP=1;[ "$1" = "-S" ] && { SKIP="$2"; shift 2; }
    [ "$1" = "-99" ] && shift && rv=99
    LOGGER() { _log_e "$*" 1>&2; }
    _print_callstack "$SKIP" 5 "" LOGGER "$@" 1>&2
  else
    shift
    [ "$1" = "-99" ] && shift && rv=99
    _log_e "$@" 1>&2
  fi

  exit "$rv"
}

# Stops the execution with success result and a message
#
# Params:
# $1  message
#
_EXIT() {
  _log_i "$@"
  exit 0
}

# Validates for non-null a list of mandatory variables
# Fatals if a violation is found
#
_NONNULL() {
  for var_name in "$@"; do
    local var_value="${!var_name}"
    [ -z "$var_value" ] && _FATAL "${FUNCNAME[1]}> Variable \"$var_name\" should not be null"
  done
}

# Adds a token or replaces a tocken to/in a URL
#
# Params:
# $1  destination var
# $2  url
# $3  token
#
_url_add_token() {
  local _tmp_="$2"
  local token="$3"
  if [ -n "$token" ]; then
    _tmp_="${_tmp_/:\/\/*@/:\/\/}"
    _tmp_="${_tmp_/:\/\//:\/\/$token@}"
  fi
  _set_var "$1" "$_tmp_"
}

# Successfully changes dir or fatals
#
__cd() {
  local L="$1"
  [ "${L:0:7}" = "file://" ] && L="${L:7}"
  [ -z "$L" ] && _FATAL "Null directory provided"
  cd "$L" 1>/dev/null || _FATAL "Unable to enter directory $1"
  _log_t "Entered directory \"$L\""
}

# File/dir existsor fatals
#
# Params:
# $1  mode (-f: fiile, -d: dir)
# $2  file/dir
#
__exist() {
  case "$1" in
    "-f") [ ! -f "$2" ] && _FATAL "Unable to find the file \"$2\"";;
    "-d") [ ! -d "$2" ] && _FATAL "Unable to find the dir \"$2\"";;
    *) _FATAL "Invalid mode \"$1\"";;
  esac
}

# Sets a variable on a template string
# The variable placeholder should respect one of these form:
# - Form #1: {var}
# - Form #2: {/var}
#
# Params:
# $1  the destination var
# $2  the var name
# $3  the var value
# $.. params $2,$3 repeated at will
#
_tpl_set_var() {
  local _var_="$1"; shift
  local _tmp_="$1"; shift
  
  while true; do
    K=$1
    [ -z "$K" ] && break
    shift; V=$1; shift
    _tmp_="${_tmp_//\{${K}\}/${V}}"
    _tmp_="${_tmp_//\{\/${K}\}/\/${V}}"
  done
  _set_var "$_var_" "$_tmp_"
}


# Parses a semver into its complonent digits
# - "v" prefix is suppored and stripped
# - all params are optional and accept ""
#
# Params:
# $1  major version receiver var
# $2  minor version receiver var
# $3  patch version receiver var
# $4  update version receiver var
# $5  semver to parse
#
_semver_parse() {
  local _tmp1_ _tmp2_ _tmp3_ _tmp4_ _tmp5_

  _tmp5_="${5/-*/}"  # Removes the version tag

  IFS='.' read -r _tmp1_ _tmp2_ _tmp3_ _tmp4_ <<< "$_tmp5_"
  [ "${_tmp1_:0:1}" = "v" ] && _tmp1_="${_tmp1_:1}"
  [ "${_tmp1_:0:1}" = "p" ] && _tmp1_="${_tmp1_:1}"
  [ -n "$1" ] && _set_var "$1" "$_tmp1_"
  [ -n "$2" ] && _set_var "$2" "$_tmp2_"
  [ -n "$3" ] && _set_var "$3" "$_tmp3_"
  [ -n "$4" ] && _set_var "$4" "$_tmp4_"
}

# Updates or add a tag to a version string
#
# Params:
# $1 the destination var
# $2 the source version
# $3 the new tag to set
#
_semver_set_tag() {
  if [[ "$2" = *"-"* ]]; then
    _set_var "$1" "${2//-*/-$3}"
  else
    _set_var "$1" "$2-$3"
  fi
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

# Fills a itmlst (list of items) with the given list of entrie
#
# Note that a itmlst is defined as:
# - Comma-delimitest list started amd terminated bu a comma (eg: ",red,blue,")
#
# Params:
# $1  the label list
# $.. the entries to add
#
_itmlst_fill() {
  local _var_name_="$1"; shift
  local _tmp_
  for _tmp_L_ in "$@"; do
    _tmp_+=",$_tmp_L_"
  done
  _set_var "$_var_name_" "${_tmp_},"
}

# Checks if a given entry is present in a itmlst (list of items)
#
# @see _itmlst_fill for the definition of "lsblsst"
#
# Params:
# $1 the label list
# $2 the entry
#
_itmlst_contains() {
  if [[ "$1" = *",$2,"* ]]; then
    return 0
  else
    return 1
  fi
}

# Checks if a given itmlst is empty
#
# @see _itmlst_fill for the definition of "lsblsst"
#
# Params:
# $1 the label list
#
_itmlst_empty() {
  [ "$EXECUTION_LABELS" = "," ] || [ "$EXECUTION_LABELS" = "" ]
}

# Gets the prefix of the PR title
#
# Params:
# $1 destination var
# $2 the PR title
#
_extract_pr_title_prefix() {
  local _tmp_="$2"
  _tmp_="${_tmp_//: */}"
  _tmp_="${_tmp_// */}"
  _set_var "$1" "$_tmp_"
}


# STOP ON ERROR
#
_SOE() {
  local R="$?"
  [ -n "$1" ] && _log_e "$1 didn't complete properly"
  [ "$R" != 0 ] && exit "$?"
}

__jq() {
  jq "$@" || _FATAL "Error parsing the json input"
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
  local A B C
  local CENSOR=false;[ "$1" = "--censor" ] && { CENSOR=true; shift; }
  if [ "$1" = "-v" ]; then
    shift
    N="$1"; E="$2"; O=$3; V=$4
    shift 4
  else
    N="$1"; 
    (E="${!N}") || _FATAL "Invalid variable name"
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
    _FATAL -S 3 -99 "$MSG" 1>&2
  fi
}
