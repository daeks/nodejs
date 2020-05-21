#!/bin/bash
if [ ! -z "$DOMAIN" ] && [ ! -z "$EMAIL" ]; then
  if [ ! -f $CERTBOT_CONF_DIR/live/$DOMAIN/cert.pem ]; then    
    sudo certbot certonly --no-self-upgrade --agree-tos --noninteractive --standalone \
      --work-dir $CERTBOT_WORK_DIR --config-dir $CERTBOT_CONF_DIR --logs-dir $CERTBOT_LOG_DIR \
      -m $EMAIL -d $DOMAIN --pre-hook "sudo apache2ctl stop"
    
    if [ -f $CERTBOT_CONF_DIR/live/$DOMAIN/cert.pem ]; then
      sudo a2dissite 000-custom-default
      sudo rm -f $APACHE_CONF_DIR/sites-available/000-custom-default.conf
    
      sudo a2enmod rewrite && a2enmod ssl
      sudo a2enmod proxy && a2enmod proxy_html && a2enmod proxy_http && a2enmod lbmethod_byrequests && a2enmod headers
      
      sudo a2dissite default-ssl
      sudo rm -f $APACHE_CONF_DIR/sites-available/default-ssl.conf
      
      sudo a2ensite 000-custom-default-redirect
      sudo a2ensite 000-custom-default-ssl
    else
      sudo a2enmod proxy && a2enmod proxy_html && a2enmod proxy_http && a2enmod lbmethod_byrequests && a2enmod headers
      sudo a2ensite 000-custom-default
    fi
  else
    flags=""
    if [ ! -z $FORCE_RENEWAL ]; then
      flags="$flags --force-renewal"
    fi
  
    sudo certbot renew --no-random-sleep-on-renew --standalone --no-self-upgrade \
      --work-dir $CERTBOT_WORK_DIR --config-dir $CERTBOT_CONF_DIR --logs-dir $CERTBOT_LOG_DIR \
      --pre-hook "sudo apache2ctl stop" --post-hook "sudo apache2ctl start" $flags
  fi
else
  sudo a2enmod proxy && a2enmod proxy_html && a2enmod proxy_http && a2enmod lbmethod_byrequests && a2enmod headers
  sudo a2ensite 000-custom-default
fi

sudo apache2ctl restart

