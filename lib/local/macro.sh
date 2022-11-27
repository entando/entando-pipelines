#/bin/bash 

_require "lib/shared/filesystem.sh"

ppl.enter_local_clone_dir() {
  [ -z "$1" ] && _FATAL -S 1 "Null local clone dir detected"
  cd "$1" || _FATAL -S 1 "Unable to enter local clone dir \"$1\""
}

ppl.start_macro() {
  _cli.parse_args "" "$@"
  _cli.get_arg action 1; shift
  _cli.get_arg PPL_LOCAL_CLONE_DIR --lcd 1
  ppl.enter_local_clone_dir

  project_type="$(prj.current.determine_type)"
  _NONNULL project_type
}
