#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. >/dev/null 2>&1 && pwd)"

# shellcheck disable=SC1090
{
  # Base
  . "$SCRIPT_DIR/lib/base.sh"
  BASE.init_default_vars
  . "$SCRIPT_DIR/lib/debug.sh"
  . "$SCRIPT_DIR/lib/misc.sh"
  . "$SCRIPT_DIR/lib/config.sh"
  . "$SCRIPT_DIR/lib/semver.sh"
  
  # Domain Specific Tools
  . "$SCRIPT_DIR/lib/git.sh"
  . "$SCRIPT_DIR/lib/pkg.sh"
  . "$SCRIPT_DIR/lib/pom.sh"
  . "$SCRIPT_DIR/lib/mvn.sh"
  . "$SCRIPT_DIR/lib/kube.sh"
  . "$SCRIPT_DIR/lib/docker.sh"
  . "$SCRIPT_DIR/lib/npm.sh"
  . "$SCRIPT_DIR/lib/enp.sh"
  . "$SCRIPT_DIR/lib/project.sh"
  . "$SCRIPT_DIR/lib/aws.sh"
  
  # Composite
  . "$SCRIPT_DIR/lib/composite.sh"

  # Specific of the Pipeline Implementation
  if [ -n "$GITHUB_ACTIONS" ]; then
    . "$SCRIPT_DIR/lib/github/github_tools.sh"
  else
    if ! ${ENTANDO_AGNOSTIC:-false}; then
      _FATAL "Unsupported Pipeline implementation"
    fi
  fi
}
