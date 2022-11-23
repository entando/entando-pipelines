#/bin/bash 

_require "lib/shared/filesystem.sh"

ppl.enter_local_clone_dir() {
  [ -z "$PPL_LOCAL_CLONE_DIR" ] && return 0
  __cd "$PPL_LOCAL_CLONE_DIR"
}
