#/bin/bash

# Successfully changes dir or fatals
#
_fs.must.cd() {
  local L="$1"
  [ "${L:0:7}" = "file://" ] && L="${L:7}"
  [ -z "$L" ] && _FATAL -S 1 "Null directory name provided"
  [[ "$L" = "-" || "$L" = "." ]] && _FATAL -S 1 "Illegal directory name \"$L\" provided"
  cd "$L" 1>/dev/null 2>/dev/null || _FATAL -S 1 "Unable to enter directory \"$1\""
  _log.t "Entered directory \"$L\"" 1>&2
  return 0
}

# File/dir existsor fatals
#
# Params:
# $1  mode (-f: fiile, -d: dir)
# $2  file/dir
#
_fs.must.exist() {
  local where="";[[ "${2:0:1}" != "/" && "${2:0:1}" != "~" ]] && where=" under directory \"$PWD\""
  case "$1" in
    "-f") [ ! -f "$2" ] && _FATAL -S 1 "Unable to find the file \"$2\" $where";;
    "-d") [ ! -d "$2" ] && _FATAL -S 1 "Unable to find the dir \"$2\" $where";;
    *) _FATAL "Invalid mode \"$1\"";;
  esac
  return 0
}
