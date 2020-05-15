#!/bin/bash
cd $NODEAPPDIR
if [ "$GIT" != "OFF" ]; then
  if [ -f "$NODEAPPDIR/.git" ]; then
    git fetch origin
    git pull origin master
  else
    git clone $GIT_URL $NODEAPPDIR/
    chown -R $USERNAME:$USERNAME $NODEAPPDIR/
    chmod -R 744 $NODEAPPDIR && chmod -R 766 $NODETMPDIR
  fi;
fi

if [ -f "$NODEAPPDIR/index.js" ] && [ -f "$NODECONFIGDIR/config.js" ]; then
  node $NODEAPPDIR/index.js $NODECONFIGDIR/config.js
fi