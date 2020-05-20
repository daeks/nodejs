#!/bin/bash
cd $NODEAPPDIR
if [ -z "$CERT_DOMAINS" ]; && [ -z "$CERT_EMAIL"]; then
  a2ensite 000-custom-default
  service apache2 start

  certbot -n certonly --no-self-upgrade --agree-tos --standalone -m $CERT_EMAIL -d $(echo $CERT_DOMAINS | sed 's/,/ -d /')
  ln -s /etc/letsencrypt/live/$(hostname -f) /etc/letsencrypt/certs
  
  a2enmod ssl
  a2enmod proxy && a2enmod proxy_html && a2enmod proxy_http && a2enmod lbmethod_byrequests
  a2ensite 000-custom-default-ssl
  
  service apache2 restart
fi