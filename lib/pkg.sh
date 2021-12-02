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
    TAR_INSTALL_URL=""
    if [ "$1" == "--tar-install" ]; then
      TAR_INSTALL_URL="$2"
      shift 2
    fi

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
    
    if [ -n "$TAR_INSTALL_URL" ]; then
      _pkg_tar_install "$TAR_INSTALL_URL" "${chk:-$P}"
    else
      _pkg_apt_install "$P"
    fi
    
    [ "$?" != "0" ] && FATAL "Installation of packet \"$P\" failed"
    
    if [ -n "$chk" ]; then
      if ! command -v "$chk" >/dev/null; then
        _FATAL "Installation of packet \"$P\" failed"
      fi
    fi
    _log_d "Packet \"$P\" installed"
  done
  
  return 0
}

# Installs a package given its apt package name
#
_pkg_apt_install() {
  ${ENTANDO_OPT_SUDO:+"$ENTANDO_OPT_SUDO"} apt-get install -y "$P" 1> /dev/null
}

# Installs a package given a link to a tarboall
#
_pkg_tar_install() {
  local url opt1 opt2 opt3
  # shellcheck disable=SC2162
  IFS=';' read url opt1 opt2 opt3 <<< "$1"
  (
    # NOTE: this form autodetects compressed tars
    tar xf <(
      curl -s ${opt1:+"$opt1"} ${opt2:+"$opt2"} ${opt3:+"$opt3"} "$url"
    )
    ${ENTANDO_OPT_SUDO:+"$ENTANDO_OPT_SUDO"} mv "$2" "/usr/local/bin/$2"
    chmod +x "/usr/local/bin/$2"
  )
}

# Ensura a mandatory command is avaliable
#
# Params:
# $1:   command
# [$2]: optional description of the command
#
require_mandatory_command() {
  local desc=${2:-$1}
  if command -v "$1" >/dev/null; then
    _log_d "Mandatory command \"$desc\" is available"
  else
    _FATAL "Mandatory command \"$desc\" is not avaliable"
  fi
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
