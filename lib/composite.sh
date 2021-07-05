#!/bin/bash

# *..sh the artifactId from a pom
#
# Params:
# $1: dest var
# $2: bom repo URL
#
_ppl_query_latest_bom_version() {
  local TMPDIR
  TMPDIR="$(mktemp -d)"
  local TMP
  _git_full_clone --shallow "$2" "$TMPDIR"
  __cd "$TMPDIR"
  _git_determine_latest_version TMP
  __cd -
  rm -rf "$TMPDIR"
  [ -n "$TMP" ] && _set_var "$1" "$TMP"
}

# Determines the name of the release branch for the given reference version
#
# Params:
# $1: the receiver var of the designated release branch
# $2: the reference version
#
# The business rule is simple:
# - Versions X.Y.Z are released under the branch "release/X.Y.0"
#
_ppl_determine_release_branch() {
  local _referenceVersion_="$2"
  local _releaseBranch_
  _semver_parse maj min ptc "" "$_referenceVersion_"
  # shellcheck disable=SC2154
  _releaseBranch_="release/$maj.$min.0"
  _set_var "$1" "$_releaseBranch_"
}
