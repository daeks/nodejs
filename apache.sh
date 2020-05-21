#!/bin/bash
if [ ! -z "$DOMAIN" ] && [ ! -z "$EMAIL" ]; then
  if [ ! -f $CERTBOT_CONF_DIR/live/$DOMAIN/cert.pem ]; then
    certbot certonly --no-self-upgrade --agree-tos --noninteractive --standalone \
      --work-dir $CERTBOT_WORK_DIR --config-dir $CERTBOT_CONF_DIR --logs-dir $CERTBOT_LOG_DIR \
      -m $EMAIL -d $DOMAIN --pre-hook "apache2ctl stop"
    
    if [ -f $CERTBOT_CONF_DIR/live/$DOMAIN/cert.pem ]; then
      a2dissite 000-custom-default
      rm -f $APACHE_CONF_DIR/sites-available/000-custom-default.conf
    
      a2enmod rewrite && a2enmod ssl
      a2enmod proxy && a2enmod proxy_html && a2enmod proxy_http && a2enmod lbmethod_byrequests && a2enmod headers
      
      a2dissite default-ssl
      rm -f $APACHE_CONF_DIR/sites-available/default-ssl.conf
      
      a2ensite 000-custom-default-redirect
      a2ensite 000-custom-default-ssl
    else
      a2enmod proxy && a2enmod proxy_html && a2enmod proxy_http && a2enmod lbmethod_byrequests && a2enmod headers
      a2ensite 000-custom-default
    fi
  else
    flags=""
    if [ ! -z $FORCE_RENEWAL ]; then
      flags="$flags --force-renewal"
    fi
  
    certbot renew --no-random-sleep-on-renew --standalone --no-self-upgrade \
      --work-dir $CERTBOT_WORK_DIR --config-dir $CERTBOT_CONF_DIR --logs-dir $CERTBOT_LOG_DIR \
      --pre-hook "apache2ctl stop" --post-hook "apache2ctl start" $flags
  fi
else
  a2enmod proxy && a2enmod proxy_html && a2enmod proxy_http && a2enmod lbmethod_byrequests && a2enmod headers
  a2ensite 000-custom-default
fi

apache2ctl restart

