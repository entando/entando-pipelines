#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# shellcheck disable=SC1090
{
  # Base
  . "$SCRIPT_DIR/../lib/base.sh"
  . "$SCRIPT_DIR/../lib/debug.sh"
  . "$SCRIPT_DIR/../lib/misc.sh"
  
  # Specialized
  . "$SCRIPT_DIR/../lib/git.sh"
  . "$SCRIPT_DIR/../lib/pkg.sh"
  . "$SCRIPT_DIR/../lib/pom.sh"
  . "$SCRIPT_DIR/../lib/mvn.sh"
  
  # Composite
  . "$SCRIPT_DIR/../lib/composite.sh"

  # Specific of the Pipeline Implementation
  if [ -n "$GITHUB_ACTIONS" ]; then
    . "$SCRIPT_DIR/../lib/github/github_tools.sh"
  else
    _FATAL "Unsupported Pipeline implementation"
  fi
}
