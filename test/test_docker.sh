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

#TEST:lib
test.docker.publish.BUILD_AND_PUSH() {
  print_current_function_name "RUNNING TEST> " ".."

  # shellcheck disable=SC2034
  {
    ENTANDO_OPT_DOCKER_ORG="${ENTANDO_OPT_DOCKER_ORG:-entando}"
  }

  local dockerFile imageAddress
  
  (
    __docker() {
      _log_d "Running docker $1.."
      echo "[DOK] docker $*" >> "$TEST__TECHNICAL_LOG_FILE"
      [ "$1 $2" != "manifest inspect" ]
    }

    ppl--docker.publish.DETERMINE_BUILD_INFO dockerFile imageAddress "Dockerfile=>[simple]" "entando-de-app" "6.3.2"
    ppl--docker.publish.BUILD_AND_PUSH "$dockerFile" "$imageAddress"
    
    TEST.GET_TLOG_COMMAND TMP -4
    ASSERT TMP = "[DOK] docker manifest inspect entando/entando-de-app:6.3.2"
    TEST.GET_TLOG_COMMAND TMP -3
    ASSERT TMP = "[DOK] docker build . -t entando/entando-de-app:6.3.2 -f Dockerfile"
    TEST.GET_TLOG_COMMAND TMP -2
    ASSERT TMP = "[DOK] docker image inspect entando/entando-de-app:6.3.2"
    TEST.GET_TLOG_COMMAND TMP -1
    ASSERT TMP = "[DOK] docker push entando/entando-de-app:6.3.2"
  ) || _SEO
}

#TEST:macro
test.docker.ppl--docker-skipped-due-to-no-dockerfile() {  
  print_current_function_name "RUNNING TEST> " ".."

  _git_full_clone --as-work-area "file://$TEST__WORK_DIR/repo-mocks/app-builder" "local-checkout"
  __cd ..

  TEST.RESET_TLOG
  # shellcheck disable=SC2034
  ppl--docker publish "" --id "TEST" --lcd "local-checkout" || _SOE
  TEST.GET_TLOG_COMMAND TMP -1
  ASSERT TMP =~ "\[REM\] STARTED AT .*"
}

#TEST:x
test.docker.ppl--docker() {
 print_current_function_name "RUNNING TEST> " ".."

  # shellcheck disable=SC2034
  TEST__APPLY_OVERRIDES() {
    ENTANDO_OPT_DOCKER_ORG="${ENTANDO_OPT_DOCKER_ORG:-entando}"
    ENTANDO_OPT_DOCKER_USERNAME="the-user"
    ENTANDO_OPT_DOCKER_PASSWORD="the-pass"    
    ENTANDO_OPT_DOCKER_BUILDS="Dockerfile.mode1,Dockerfile.mode2"
  }
  
  rm -rf local-checkout
  ppl--checkout-branch --id "PR-CHECKOUT" --lcd "local-checkout" || _SOE

  (
    __cd "local-checkout"
    echo "FROM SCRATCH" > Dockerfile.mode1
    echo "FROM SCRATCH" > Dockerfile.mode2
  )
 
  #~ CASE #1 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Simulate docker build commands for two dockerfiles
  ppl--docker publish \
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

#TEST:lib
TEST.ppl--docker.is_release_version_number() {
  print_current_function_name "RUNNING TEST> "  ".."

  ppl--docker.is_release_version_number "myimage:1.2.3"
  ASSERT -v RES $? = 0
  ppl--docker.is_release_version_number "myimage:1.2.3-SNAPSHOT"
  ASSERT -v RES $? != 0

  ppl--docker.is_release_version_number "my-registry.io/myimage:1.2.3"
  ASSERT -v RES $? = 0
  ppl--docker.is_release_version_number "my-registry.io/myimage:1.2.3-SNAPSHOT"
  ASSERT -v RES $? != 0
  
  # Tag patterns are more thoroughly tested by _ppl_is_release_version_number's tests,
  # on which this function depends
}

true
