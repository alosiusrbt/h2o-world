#!/bin/sh

#
# This script needs to be scheduled via crontab.
#

set -e

S3_BUCKET=h2oworld.h2o.ai
GIT_REPO=$HOME/deploy/prod/h2oworld.h2o.ai

# The 'git.push' file is created by tools/signal/server.coffee
#   when github calls http://signal.0xdata.com/api/deploy on post-push.
#   Abort if this file is not present.
if [ -f $HOME/git.push ]; then
  repo_name=$(grep "full_name" $HOME/git.push | sed -e "s/.*h2oai\///" -e "s/[,\"]//g")
  echo "$HOME/git.push reports $repo_name"
  if [ "$S3_BUCKET" != "$repo_name" ]; then
    exit 0
  fi
else
  exit 0
fi

# Remove our git.push marker
rm $HOME/git.push

echo "Building $GIT_REPO at $(date)"
echo "==========================="

cd $GIT_REPO
git pull
npm install
make build
/usr/local/bin/s3cmd sync --delete-removed --acl-public --exclude '.git/*' build/ s3://$S3_BUCKET/

# Remove the 'git.push' file so that we don't run the next time 
#   around unless someone has pushed.

#mail -s "0xdata.com deployed" prithvi@0xdata.com < $HOME/git.push

#rm $HOME/git.push
