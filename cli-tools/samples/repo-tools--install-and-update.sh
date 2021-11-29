#!/bin/bash

[ -z "$WORK_DIR" ] && WORK_DIR="../tmp/workdir"
[ -f "$WORK_DIR/_env" ] && . "$WORK_DIR/_env" "$(basename "$0")" "%@"

#BRANCH=..
#TARGET=..
#DEBUG_LEVEL=..
#GIT_USER=..
#GIT_EMAIL=..

# ~~~~~~~~~~~~~~~~~~~~
# INSTALL PIPELINES

./repo-tools install-pipeline \
  --batch "$TARGET" \
  --base develop  \
  --work-dir "$WORK_DIR" \
  --branch "$BRANCH"  \
  --reuse \
  --force-new-branch \
  ${MESSAGE:+--msg "$MESSAGE"} \
  ${GIT_USER:+--git-user-name "$GIT_USER"} \
  ${GIT_EMAIL:+--git-user-email "$GIT_EMAIL"} \
  --log-level "$DEBUG_LEVEL" \
;

[ "$?" ] || exit 99

echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""

# ~~~~~~~~~~~~~~~~~~~~
# UPDATE MAINLINE

VERSION="7.0.0"
./repo-tools update-mainline \
  --batch "$TARGET" \
  --base develop  \
  --work-dir "$WORK_DIR" \
  --branch "$BRANCH"  \
  --reuse \
  ${MESSAGE2:+--msg "$MESSAGE2"} \
  ${GIT_USER:+--git-user-name "$GIT_USER"} \
  ${GIT_EMAIL:+--git-user-email "$GIT_EMAIL"} \
  --log-level "$DEBUG_LEVEL" \
  --version "$VERSION" \
;
