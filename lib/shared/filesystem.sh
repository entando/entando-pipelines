#/bin/bash

# Successfully changes dir or fatals
#
# Alias:
# __cd() { ... }
#
_fs.must.cd() {
  _fs.must._cd 1 "$@"
}

_fs.must._cd() {
  local SKIP="$(($1+1))"; shift
  local L="$1"
  [ "${L:0:7}" = "file://" ] && L="${L:7}"
  [ -z "$L" ] && [ "$BACK" == "false" ] && _sys.fatal  -S "$SKIP" "Null directory name provided"
  [[ "$L" = "." || "$L" = "" ]] && _sys.fatal  -S "$SKIP" "Illegal directory name \"$L\" provided"
  cd "$L" 1>/dev/null 2>/dev/null || _sys.fatal  -S "$SKIP" "Unable to enter directory \"$1\""
  _log.t "Entered directory \"$L\"" 1>&2
  return 0
}

# File/dir existsor fatals
#
# Params:
# $1  mode (-f: fiile, -d: dir)
# $2  file/dir
#
# Alias:
# __exist() { ... }
#
_fs.must.exist() {
  local SKIP=1;[ "$1" = "-S" ] && { ((SKIP+=$2)); shift 2; }
  local where="";[[ "${2:0:1}" != "/" && "${2:0:1}" != "~" ]] && where=" under directory \"$PWD\""
  case "$1" in
    "-f") [ ! -f "$2" ] && _sys.fatal -S "$SKIP" "Unable to find the file \"$2\" $where";;
    "-d") [ ! -d "$2" ] && _sys.fatal -S "$SKIP" "Unable to find the dir \"$2\" $where";;
    *) _sys.fatal -S "$SKIP" "Invalid mode \"$1\"";;
  esac
  return 0
}
