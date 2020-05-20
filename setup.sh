#!/bin/bash
cd $NODEAPPDIR
if [ -z "$CERT_DOMAINS" ]; && [ -z "$CERT_EMAIL"]; then
  certbot -n certonly --no-self-upgrade --agree-tos --standalone -m $CERT_EMAIL -d $(echo $CERT_DOMAINS | sed 's/,/ -d /')
  ln -s /etc/letsencrypt/live/$(hostname -f) /etc/letsencrypt/certs
  service apache2 restart
fi