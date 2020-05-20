#!/bin/bash
if [ ! -z "$CERT_DOMAIN" ] && [ ! -z "$CERT_EMAIL" ]; then
  a2enmod rewrite
  a2ensite 000-custom-default

  certbot certonly --no-self-upgrade --agree-tos --standalone -m $CERT_EMAIL -d $CERT_DOMAIN #$(echo $CERT_DOMAINS | sed 's/,/ -d /')
  ln -s /etc/letsencrypt/live/$CERT_DOMAIN /etc/letsencrypt/certs
  
  a2enmod rewrite
  a2ensite 000-custom-default
  
  a2enmod ssl && a2enmod headers
  a2enmod proxy && a2enmod proxy_html && a2enmod proxy_http && a2enmod lbmethod_byrequests
  a2ensite 000-custom-default-ssl
  
  service apache2 start
fi