#!/bin/bash

# shellcheck disable=SC1090 disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/../../lib/all.sh"

ppl--tests() {
  ~/.entando/ppl/entando-pipelines/prj/run-tests.sh "$@"
}
