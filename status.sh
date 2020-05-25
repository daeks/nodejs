#!/bin/bash
if [ ! -z "$DOMAIN" ] && [ ! -z "$EMAIL" ]; then
    if [ ! -f $CERTBOT_CONF_DIR/live/$DOMAIN/cert.pem ]; then
      curl -f http://localhost:$PORT/ && curl -f http://$DOMAIN/ || exit 1
    else
      curl -f http://localhost:$PORT/ && curl -f http://$DOMAIN/ && curl -f https://$DOMAIN/ || exit 1
    fi
else
    curl -f http://localhost:$PORT/ || exit 1
fi