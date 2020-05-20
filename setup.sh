#!/bin/bash
if [ ! -z "$DOMAIN" ] && [ ! -z "$EMAIL" ]; then
  a2dissite 000-custom-default
  rm $APACHE_CONF_DIR/sites-available/000-custom-default.conf
  
  certbot certonly --no-self-upgrade --agree-tos --noninteractive --standalone -m $EMAIL -d $DOMAIN --pre-hook "apache2ctl stop"
  ln -s /etc/letsencrypt/live/$DOMAIN /etc/letsencrypt/certs
  
  a2enmod rewrite && a2enmod ssl
  
  a2ensite 000-custom-default-redirect
  a2ensite 000-custom-default-ssl
else
  a2ensite 000-custom-default
fi

a2enmod proxy && a2enmod proxy_html && a2enmod proxy_http && a2enmod lbmethod_byrequests && a2enmod headers
apache2ctl start