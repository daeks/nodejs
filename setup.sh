#!/bin/bash
if [ ! -z "$DOMAIN" ]; then
  a2enmod rewrite
  a2ensite 000-custom-default
  a2dissite 000-custom-default-backup

  certbot certonly --no-self-upgrade --agree-tos --standalone -d $DOMAIN #$(echo $CERT_DOMAINS | sed 's/,/ -d /')
  ln -s /etc/letsencrypt/live/$DOMAIN /etc/letsencrypt/certs
  
  a2enmod rewrite
  a2ensite 000-custom-default
  
  a2enmod ssl
  a2enmod proxy && a2enmod proxy_html && a2enmod proxy_http && a2enmod lbmethod_byrequests && a2enmod headers
  a2ensite 000-custom-default-ssl
  
  apache2ctl start
else
  a2enmod proxy && a2enmod proxy_html && a2enmod proxy_http && a2enmod lbmethod_byrequests && a2enmod headers
  a2ensite 000-custom-default-backup
  apache2ctl
fi