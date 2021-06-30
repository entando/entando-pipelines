#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck disable=SC2046
cd "$SCRIPT_DIR/.." || { echo "Unable to enter the script dir"; exit 99; }

# shellcheck disable=SC2046
shellcheck --exclude "SC2181,SC2155,SC2119" \
  $(find lib -maxdepth 5 -type f -name "*.sh") \
  $(find macro -maxdepth 5 -type f -name "*.sh") \
  $(find test -maxdepth 5 -type f -name "*.sh") \
  | sed -E "s/In (.*) line /##\1:/" \
  | while read i; do 
    if [ "${i:0:2}" = "##" ]; then
      echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      echo -e "$PWD/${i:2} \n"
    else
      echo "$i"
    fi
  done
