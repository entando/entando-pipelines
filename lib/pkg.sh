#!/bin/bash

# Installs a command given its package name
#
# Params:
# $1: name of the package
#
# Options:
# -c command          command to check if != package name
# --tar-install url   installation based on the url of the executable archive
#
_pkg_get() {
  local chk
  local P="-"
  
  # Args parse: Command presence check override
  if [ "$1" = "-c" ]; then
    local chk="$2"
    shift 2
  fi
  
  # Args parse: Installation mode override    
  TAR_INSTALL_URL=""
  if [ "$1" == "--tar-install" ]; then
    TAR_INSTALL_URL="$2"
    shift 2
  fi
  
  # Args parse: Package Name
  P="$1"
  [ -z "$chk" ] && chk="$P"
  
  # Command presence check
  if _pkg_is_command_available "$chk"; then
    _log_t "Command \"$chk\" available"
    return 0
  fi
  
  # Installation if required
  _log_t "Installing packet \"$P\".."
  
  if [ -n "$TAR_INSTALL_URL" ]; then
    _pkg_tar_install "$TAR_INSTALL_URL" "${chk:-$P}"
  else
    _pkg_apt_install "$P"
  fi
  
  [ "$?" != "0" ] && _FATAL "Installation of packet \"$P\" failed"
  
  if _pkg_is_command_available "$chk"; then
    _log_d "Packet \"$P\" installed"
  else
    _FATAL "Installation of packet \"$P\" failed"
  fi
  
  return 0
}

# Installs a package given its apt package name
#
_pkg_apt_install() {
  ${ENTANDO_OPT_SUDO:+"$ENTANDO_OPT_SUDO" -n} apt-get install -y "$1" 1> /dev/null
}

# Installs a package given a link to a tarball
#
# $1: semicolon-delimited list containing:
#     position #1     the url
#     position #2..4  3 additional args for the curl command
#
# this limited syntax was implemented mostly to allow specifying "--insecure"
# note that all the args are individually quoted
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
    ${ENTANDO_OPT_SUDO:+"$ENTANDO_OPT_SUDO" -n} mv "$2" "/usr/local/bin/$2"
    chmod +x "/usr/local/bin/$2"
  )
}

# Ensures that a mandatory command is avaliable
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

