#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/misc.sh"
  . "$PROJECT_DIR/lib/semver.sh"
}

#TEST:lib
test_semver() {
  test_semver_parse
  test_semver_set_tag
  test_semver_add

  true
}

test_semver_parse() {
  print_current_function_name "RUNNING TEST> "  ".."
 
  local maj min ptc tag
  _semver_parse maj min ptc tag "1.2.3"
  ASSERT -v RES "$maj.$min.$ptc-$tag" = "1.2.3-"
  _semver_parse maj min ptc tag "1.2.3-SNAPSHOT"
  ASSERT -v RES "$maj.$min.$ptc-$tag" = "1.2.3-SNAPSHOT"
  _semver_parse maj min ptc tag "1"
  ASSERT -v RES "$maj.$min.$ptc-$tag" = "1..-"
  _semver_parse maj min ptc tag ""
  ASSERT -v RES "$maj.$min.$ptc-$tag" = "..-"
  _semver_parse maj "" ptc "" "1.2.3-4"
  ASSERT -v RES "$maj.$min.$ptc-$tag" = "1..3-"
  _semver_parse maj min ptc tag "v1.2.3"
  ASSERT -v RES "$maj.$min.$ptc-$tag" = "1.2.3-"
  _semver_parse maj min ptc tag "v.2.3"
  ASSERT -v RES "$maj.$min.$ptc-$tag" = ".2.3-"
  _semver_parse maj min ptc tag "1.2.3-SNAPSHOT"
  ASSERT -v RES "$maj.$min.$ptc-$tag" = "1.2.3-SNAPSHOT"
}

test_semver_set_tag() {
  print_current_function_name "RUNNING TEST> "  ".."
  
  _semver_set_tag RES "1.2.3" "SNAPSHOT"
  ASSERT RES = "1.2.3-SNAPSHOT"
  _semver_set_tag RES "1.2.3-SNAPSHOT" "PREVIEW-01"
  ASSERT RES = "1.2.3-PREVIEW-01"
  _semver_set_tag RES "1.2.3-PREVIEW-01" "PREVIEW-02"
  ASSERT RES = "1.2.3-PREVIEW-02"
}

test_semver_add() {
   print_current_function_name "RUNNING TEST> "  ".."

  _semver_add RES "1.2.3" 0 0 1
  ASSERT RES = "1.2.4"
  _semver_add RES "1.2.3" 1 2 3
  ASSERT RES = "2.4.6"
  _semver_add RES "1.2.3-SNAPSHOT" 1 2 3
  ASSERT RES = "2.4.6-SNAPSHOT"
  _semver_add RES "v1.2.3-SNAPSHOT" 1 2 3
  ASSERT RES = "v2.4.6-SNAPSHOT"
}

true
