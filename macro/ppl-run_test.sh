#!/bin/bash

#TEST:system,macro,ppl-run
ppl-run.test() {
  export GITHUB_ACTIONS=1
  export ENTANDO_PPL_HOME="$PROJECT_DIR"
  
  R="$ENTANDO_PPL_HOME/macro/ppl-run.sh"
  
  mkdir "local-clone"
  __cd "local-clone"
  touch "pom.xml"
  __cd -
  
  "$R" init \
    --lcd="local-clone" \
    --type=mvn \
    --checkout-with-token "TEST-TOKEN"
}
