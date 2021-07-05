#!/bin/bash

# shellcheck disable=SC1090
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

# EXECUTES THE RELEASE OF AN APP-ENGINE MODULE
# Params:
# $1: the current reference
# $2: the url of the BOM
# -
# Expected ENV:
# - GIT_USER_NAME, GIT_USER_EMAIL, GIT_TOKEN
#
ppl--release-app-engine-module() {
  set +e

  local CURRENT_GIT_REF="$1"
  local ENTANDO_OPT_REPO_BOM_URL="$2"

  _log_i "RELEASE-APP-ENGINE-MODULE"
  _NONNULL GIT_TOKEN GIT_USER_EMAIL GIT_USER_NAME ENTANDO_OPT_REPO_BOM_URL
  _pkg_get "xmlstarlet" -c xmlstarlet

  # ~
  # ~ GATERING INFO
  # ~
  local tagValue
  local artifactId
  local artifactVersionInBom

  # current tagValue
  _git_ref_to_tag tagValue "${CURRENT_GIT_REF}"
  _log_i DEBUG "Currently on tag: \"$tagValue\""

  # BOM get the current artifact version
  _pom_get_artifact_id artifactId "pom.xml"

  # clone entando-core-bom
  mkdir "bom-tmp" && cd "bom-tmp" \
     && _git_full_clone "$ENTANDO_OPT_REPO_BOM_URL" "$GIT_TOKEN"

  # get the current artifact version in the entando-core-bom pom.xml file
  _pom_get_artifact_version artifactVersionInBom "pom.xml" "$artifactId"
  [ -z "$artifactVersionInBom" ] && _EXIT "Dependency into the entando-core-bom not found"

  _log_i "UPDATING entando-core-bom pom.xml file..."

  # TODO check if new version is newer?

  # update the version of the current project in the entando-core-bom pom.xml file
  _pom_set_artifact_version "pom.xml" "$artifactId"

  # commit
  _git_auto_setup_commit_config
  git add pom.xml
  git commit -m "Bumped $artifactId to $tagValue"
  git push
}
