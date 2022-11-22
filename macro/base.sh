#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
. "$BASE_DIR/lib/shared/essential.sh"

_require() {
  _sys.require -S 1 "$BASE_DIR/$1"
}

_require "lib/local/shorts.sh"
