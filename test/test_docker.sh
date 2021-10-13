#!/bin/bash

# shellcheck disable=SC1091,SC1090
{
  . "$PROJECT_DIR/test/_test-base.sh"
  . "$PROJECT_DIR/lib/base.sh"
  . "$PROJECT_DIR/lib/docker.sh"
  . "$PROJECT_DIR/macro/agnostic/docker.sh"
}

#TEST:lib
test.docker.parse_image_address() {
  print_current_function_name "RUNNING TEST> "  ".."

  local org name tag
  _docker_parse_image_address org name tag "example/some-image:v1.2"
  ASSERT -v RES "$org|$name|$tag" = "example|some-image|v1.2"
  _docker_parse_image_address org name tag "some-image:v1.2"
  ASSERT -v RES "$org|$name|$tag" = "|some-image|v1.2"
  _docker_parse_image_address org name tag "/some-image:v1.2"
  ASSERT -v RES "$org|$name|$tag" = "|some-image|v1.2"
  _docker_parse_image_address org name tag "example/some-image:"
  ASSERT -v RES "$org|$name|$tag" = "example|some-image|"
  _docker_parse_image_address org name tag "/some-image"
  ASSERT -v RES "$org|$name|$tag" = "|some-image|"
  _docker_parse_image_address org name tag "example/some-image"
  ASSERT -v RES "$org|$name|$tag" = "example|some-image|"
  _docker_parse_image_address org name tag "example/:v1.2"
  ASSERT -v RES "$org|$name|$tag" = "example||v1.2"
  _docker_parse_image_address org name tag ""
  ASSERT -v RES "$org|$name|$tag" = "||"
}


#TEST:macro
test.docker.publish.LOGIN() {
  print_current_function_name "RUNNING TEST> " ".."

  # shellcheck disable=SC2034
  {
    ENTANDO_OPT_DOCKER_USERNAME="the-user"
    ENTANDO_OPT_DOCKER_PASSWORD="the-pass"    
  }
  ppl--docker.publish.LOGIN
  TEST.GET_TLOG_COMMAND TMP -1
  ASSERT TMP =~ "\[DOK\] docker login -u the-user --password-stdin" 
}

#TEST:macro
test.docker.publish.BUILD_AND_PUSH() {
  print_current_function_name "RUNNING TEST> " ".."

  # shellcheck disable=SC2034
  {
    ENTANDO_OPT_DOCKER_ORG="${ENTANDO_OPT_DOCKER_ORG:-entando}"
  }

  ppl--docker.publish.BUILD_AND_PUSH_ALL "Dockerfile" "entando-de-app" "6.3.2"
  
  TEST.GET_TLOG_COMMAND TMP -3
  ASSERT TMP = "[DOK] docker build . -t entando/entando-de-app:6.3.2 -f Dockerfile"
  TEST.GET_TLOG_COMMAND TMP -2
  ASSERT TMP = "[DOK] docker image inspect entando/entando-de-app:6.3.2"
  TEST.GET_TLOG_COMMAND TMP -1
  ASSERT TMP = "[DOK] docker push entando/entando-de-app:6.3.2"
}

#TEST:macro
test.docker.ppl--docker-skipped-due-to-no-dockerfile() {  
  print_current_function_name "RUNNING TEST> " ".."

  TEST.RESET_TLOG
  # shellcheck disable=SC2034
  ppl--docker publish "" --id "TEST" --lcd "local-checkout" || _SOE
  TEST.GET_TLOG_COMMAND TMP -1
  ASSERT TMP =~ "\[REM\] STARTED AT .*"
}

#TEST:macro
test.docker.ppl--docker() {
 print_current_function_name "RUNNING TEST> " ".."

  # shellcheck disable=SC2034
  {
    ENTANDO_OPT_DOCKER_ORG="${ENTANDO_OPT_DOCKER_ORG:-entando}"
    ENTANDO_OPT_DOCKER_USERNAME="the-user"
    ENTANDO_OPT_DOCKER_PASSWORD="the-pass"    
  }
  
  rm -rf local-checkout
  ppl--checkout-branch pr --id "PR-CHECKOUT" --lcd "local-checkout" || _SOE
 
  #~ CASE #1 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Simulate docker build commands for two dockerfiles
  ppl--docker publish "Dockerfile.mode1,Dockerfile.mode2" \
    --id "TEST" --lcd "local-checkout" || _SOE
  
  #~ expectations

  TEST.GET_TLOG_COMMAND TMP -7
  ASSERT TMP =~ "\[DOK\] docker login -u the-user --password-stdin"
  
  local EXPECTED_VERSION_TAG="10.9.8.0-SNAPSHOT"
  TEST.GET_TLOG_COMMAND TMP -6
  ASSERT TMP =~ "\[DOK\] docker build . -t entando/entando-test-repo-base-mode1:$EXPECTED_VERSION_TAG -f Dockerfile.mode1"
  TEST.GET_TLOG_COMMAND TMP -5
  ASSERT TMP =~ "\[DOK\] docker image inspect entando/entando-test-repo-base-mode1:$EXPECTED_VERSION_TAG"
  TEST.GET_TLOG_COMMAND TMP -4
  ASSERT TMP =~ "\[DOK\] docker push entando/entando-test-repo-base-mode1:$EXPECTED_VERSION_TAG"
  
  TEST.GET_TLOG_COMMAND TMP -3
  ASSERT TMP =~ "\[DOK\] docker build . -t entando/entando-test-repo-base-mode2:$EXPECTED_VERSION_TAG -f Dockerfile.mode2"
  TEST.GET_TLOG_COMMAND TMP -2
  ASSERT TMP =~ "\[DOK\] docker image inspect entando/entando-test-repo-base-mode2:$EXPECTED_VERSION_TAG"
  TEST.GET_TLOG_COMMAND TMP -1
  ASSERT TMP =~ "\[DOK\] docker push entando/entando-test-repo-base-mode2:$EXPECTED_VERSION_TAG"

  #~ CASE #2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # shellcheck disable=SC2034
  ENTANDO_OPT_DOCKER_BUILD_QUALIFIER_POSITION="after-tag"
  ppl--docker publish "Dockerfile.mode1,Dockerfile.mode2" \
      --id "TEST" --lcd "local-checkout" || _SOE
      
  TEST.GET_TLOG_COMMAND TMP -1
  ASSERT TMP =~ "\[DOK\] docker push entando/entando-test-repo-base:$EXPECTED_VERSION_TAG-mode2"
}

true
