#!/bin/bash

# Install a packet
# Options
# Params:
# $1: name of the packet
# $2: optional installation check (ok if command present)
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
      if command -v "$chk" >/dev/null; then
          _log_t "Package \"$P\" available"
          continue
      fi
    fi
    
    _log_t "Installing packet \"$P\".."
    
    if ${ENTANDO_OPT_SUDO:+"$ENTANDO_OPT_SUDO"} apt-get install -y "$P" 1> /dev/null; then
      if [ -n "$chk" ]; then
        if ! command -v "$chk" >/dev/null; then
          FATAL "Installation of packet \"$P\" failed"
        fi
      fi
      _log_d "Packet \"$P\" installed"
    else
      FATAL "Installation of packet \"$P\" failed"
    fi
  done
}
