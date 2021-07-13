#!/bin/bash

# Install a packet
#
# Params:
# $1: name of the packet
#
# Options:
# -c command: installation check based on command presence
#
_pkg_get() {
  local chk
  local P="-"
  
  while true; do
    P="$1"
    [ -z "$P" ] && break
    shift
    
    if [ "$1" = "-c" ]; then
      local chk="$2"
      shift 2
      
      _pkg_is_command_available "$chk" && {
        _log_t "Package \"$P\" available"
        continue
      }
    fi
    
    _log_t "Installing packet \"$P\".."
    
    if ${ENTANDO_OPT_SUDO:+"$ENTANDO_OPT_SUDO"} apt-get install -y "$P" 1> /dev/null; then
      if [ -n "$chk" ]; then
        if ! command -v "$chk" >/dev/null; then
          _FATAL "Installation of packet \"$P\" failed"
        fi
      fi
      _log_d "Packet \"$P\" installed"
    else
      FATAL "Installation of packet \"$P\" failed"
    fi
  done
  
  return 0
}

#  Checks for the presence of a command
#
# Params:
# $1: the command
#
# Options:
# [-m] if provided failing finding the command is fatal
#
_pkg_is_command_available() {
  local MANDATORY=false;[ "$1" = "-m" ] && { MANDATORY=true; shift; }
  command -v "$1" >/dev/null || { "$MANDATORY" && _FATAL "Unable to find required command \"$1\""; }
}
