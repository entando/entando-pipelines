#!/bin/bash

# shellcheck disable=2034
{
  GIT_USER_NAME="CiCd Bot"
  GIT_USER_EMAIL="cicd@example.com"
  ENTANDO_OPT_SUDO="${ENTANDO_OPT_SUDO:-"sudo"}"
  ENTANDO_OPT_LOG_LEVEL="${ENTANDO_OPT_LOG_LEVEL:-DEBUG}"
  ENTANDO_OPT_REPO_BOM_URL="${ENTANDO_OPT_REPO_BOM_URL:-"https://github.com/entando/entando-core-bom.git"}"
}

FAILED() {
  [ "$?" -eq 99 ] && exit "$?"
  local ln fn fl
  read -r ln fn fl < <(caller "0")
  _FATAL -99 "Test failed in $fl on line $ln ($fn)${1:+ [COMMENT: $1]}"
}

ASSERT() {
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
    *) O="??"; _FATAL "Unknown operator \"$O\"";;
  esac

  if [ $? != 0 ]; then
    local ln fn fl
    read -r ln fn fl < <(caller "0")
    
    echo ""
    _log_e "Assertion failed in $fl on line $ln ($fn)"
    
    if ! $CENSOR; then
      _pp_adjust_var E 250
      _pp_adjust_var V 250

      if [ "${#E}" -gt 30 ] || [ "${#V}" -gt 30 ]; then
        MSG="\nTEST> Asserted:\n> EXPECTED:  $N"
        MSG+="\n> TO BE:     $O\n> $OD      $V\n\n> BUT WAS FOUND: $E\n" 1>&2
        echo -e "$MSG"
      else
        echo -e "\nTEST> Expected $N $O \"$V\" but instead I've found \"$E\"\n" 1>&2
      fi
    else
        local B='\033[44m\033[1;37m'
        local A='\033[0;39m'
        echo -e "\nTEST> Expected $N $O ${B}[[CENSORED]]${A} but instead I've found ${B}[[CENSORED]]${A}\n" 1>&2
    fi
    _FATAL -99 "TEST FAILED."
  fi
}

# Creates a test git repository
#
# Params:
# $1: the destination dir
# $2: the option topic branch name to create
# $3: the tag to apply to the test commit
#
_create-test-git-repo() {
  local dst_dir="$1"
  local branch="$2"
  local tag="$3"
  
  (
    set -e
    rm -rf "$dst_dir" && mkdir "$dst_dir"

    __cd "$dst_dir"

    git init
    _git_set_commit_config "the-user-name" "the-user-email@example.com"
    [ "$(git config "user.name")" = "the-user-name" ] || _FATAL "Test git repo preparation failed"
    [ "$(git config "user.email")" = "the-user-email@example.com" ] || _FATAL "Test git repo preparation failed"

    git checkout -q -b master
    echo "the-file-body" > "the-file"
    git add .
    git commit -m "TheCommit"

    git checkout -q -b develop
    echo "an-addition" >> "the-file"
    git add .
    git commit -m "TheCommit#2"
    
    if [ -n "$branch" ]; then
      git checkout -q -b "$branch"
      echo "another-addition" >> "the-file"
      git add .
      git commit -m "TheCommit#3"
    fi
    
    if [ -n "$tag" ]; then
      git tag "$tag"
    fi
  ) 1>/dev/null || _FATAL "Test git repo preparation failed"
}

LATEST_TEST_TLOG_COMMAND() {
  _set_var "$1" "$(tail -n 1 "$TEST_TECHNICAL_LOG_FILE")"
}

DBGSHELL() {
  (
    [ ! -t 0 ] && {
      _log_w "Refusing to drop shell because this is not an interactive tty session"
      exit 0
    }
    
    _log_i 'DROPPING THE DEBUG SHELL FROM:' 1>&2
    _print_callstack 1 5 "" "" "$@" 1>&2
    
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
      cp "$HOME/.profile" "$TEST_WORK_DIR/.bashrc"
    else
      [ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$TEST_WORK_DIR/.bashrc"
    fi

    {
      echo -e "\n#\n#\n#\n"
      COMMENT="";[ -n "$1" ] && COMMENT=" with comment: \"$1\""
      # shellcheck disable=SC2028
      echo "echo -e '\033[43m\033[1;30m> DEBUG SHELL STARTED$COMMENT\033[0;39m\n' 1>&2"
      echo -e "true"
    } >> "$TEST_WORK_DIR/.bashrc"
    
    # Run the shell
    bash --rcfile "$TEST_WORK_DIR/.bashrc" < /dev/stdin > /dev/tty

  ) || { 
    [ "$?" = "77" ] && _FATAL "Execution Interrupted: Debug Shell terminated with fatal error" >/dev/tty 
  }
}
