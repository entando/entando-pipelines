#/bin/bash



# Pretty prints of variables
#
# Params:
# [-d]       prints to the debug tty
# [-t title] also print a title
# - all params are optional and accept ""
#
# Params:
# $@  a list of variable names to pretty print (so without dereference operator "$")
#
_sys.pp() {
  if [ "$1" == "-t" ]; then
    local TITLE=" [$2]"
    shift 2
  fi
  echo "▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁"
  echo "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒$TITLE"
  for var_name in "$@"; do
    echo "▕- $var_name: ${!var_name}"
  done
  echo "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒"
  echo "▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔"
}


# Drops a shell that inherits the caller environment
#
_sys.shell() {
  QUIET=false;[ "$1" = "--quiet" ] && { QUIET=true; shift; }
  CUSTOM=false;[ "$1" = "--customize" ] && { CUSTOM=true; shift; }
  SKIP=0;[ "$1" = "-S" ] && { SKIP="$2"; shift 2; }
  (
    $IN_TTY && {
     _log_w "Refusing to drop shell because this is not an interactive tty session"
     exit 0
    }

    ! $QUIET && {
      _log_i 'DROPPING THE DEBUG SHELL FROM:' 1>&2
      _sys.print_callstack "$SKIP" 5 "" "" "$@" 1>&2
    
      (
        read -r ln fn fl < <(caller "$SKIP")
        sed -n "$((ln-4))"',$p' "$fl" | head -5
      )
      
      echo -e "\n▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔"
    }
    
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
    TEST__WORK_RCFILE="$TEST__WORK_DIR/.bashrc"
    if [ -f "$HOME/.profile" ]; then
      cp "$HOME/.profile" "$TEST__WORK_RCFILE"
    else
      [ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$TEST__WORK_RCFILE"
    fi

    {
      ! $QUIET && {
        echo -e "\n#\n#\n#\n"
        COMMENT="";[ -n "$1" ] && COMMENT=" with comment: \"$1\""
        # shellcheck disable=SC2028
        echo "echo -e '\033[43m\033[1;30m> DEBUG SHELL STARTED$COMMENT\033[0;39m\n' 1>&2"
      }
      echo -e "true"
    } >> "$TEST__WORK_RCFILE"
    
    echo "export ENTANDO_OPT_STOP_ON_EXIT=true" >> "$TEST__WORK_RCFILE"
    
    $CUSTOM && DBGSHELL_CUSTOMIZE "$TEST__WORK_DIR" "$TEST__WORK_RCFILE"

    # Run the shell
    bash --rcfile "$TEST__WORK_RCFILE" < /dev/tty > /dev/tty

  ) || {
    [ "$?" = "77" ] && _FATAL "Execution Interrupted: Debug Shell terminated with fatal error" >/dev/tty
  }
}

# Validates for non-null a list of mandatory variables
# Fatals if a violation is found
#
_sys.nn() {
  for var_name in "$@"; do
    local var_value="${!var_name}"
    [ -z "$var_value" ] && _sys.fatal -S 1 "${FUNCNAME[1]}> Variable \"$var_name\" should not be null"
  done
  return 0
}
