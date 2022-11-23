#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
PPL_BASE_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
. "$PPL_BASE_SCRIPTS_DIR/lib/shared/essential.sh"

_require() {
  local SKIP=1;[ "$1" = "-S" ] && { ((SKIP+=$2)); shift 2; }
  \_sys.require -S "$SKIP" --base "$PROJECT_DIR" "$1"
}

_require "lib/local/shorts.sh"
