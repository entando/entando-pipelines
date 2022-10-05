#!/bin/bash

BRANCH="ENG-2704-start-version-7-0"
TARGET="all-app"

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""

# ~~~~~~~~~~~~~~~~~~~~
# UPDATES THE MAIN APP

./app-version-tools generate \
  --batch bom \
  --work-dir ../tmp/repos/tt \
  --main-repo "https://github.com/entando-k8s/entando-de-app" \
  --filter ENG-2704 \
  --reuse --fetch \
  --git-user-name my-git-user-name \
  --git-user-email my-git-user-email \
  --best-effort \
  --main-topic-branch "ENT-2704-new-version" \
  --fallback "bom" \
  --branch "develop" \
  --log-level DEBUG \
;
