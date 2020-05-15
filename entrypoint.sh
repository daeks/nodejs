#!/bin/bash
cd $NODEAPPDIR
if [ "$GIT" != "OFF" ]; then
  if [ -d "$NODEAPPDIR/.git" ]; then
    git fetch origin
    git pull origin master
  else
    git clone $GIT_URL $NODEAPPDIR/
    chown -R $USERNAME:$USERNAME $NODEAPPDIR/
    chmod -R 744 $NODEAPPDIR
    if [ -d "$NODETMPDIR" ]; then
      chmod -R 766 $NODETMPDIR
    fi
  fi
fi

if [ -f "$NODEAPPDIR/index.js" ] && [ -f "$NODECONFIGDIR/config.js" ]; then
  npm install && node $NODEAPPDIR/index.js $NODECONFIGDIR/config.js
fi