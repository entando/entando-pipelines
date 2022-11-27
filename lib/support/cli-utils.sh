#!/bin/bash

__jq() {
  jq "$@" || _FATAL "Error parsing the json input"
}
