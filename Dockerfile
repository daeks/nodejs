FROM debian:buster-slim
LABEL maintainer="github.com/daeks"

ENV GIT OFF
ENV GIT_TOKEN <token>
ENV GIT_URL https://$GIT_TOKEN@github.com/<user>/<repo>.git

ADD . $GIT

ENV PORT 8000

ENV USERNAME nodejs
ARG USERID=1000

ENV NODEHOMEDIR /home/$USERNAME
ENV NODEAPPDIR $NODEHOMEDIR/app
ENV NODECONFIGDIR $NODEHOMEDIR/config
ENV NODETMPDIR $NODEAPPDIR/cache

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data

ENV APACHE_WWW_DIR /var/www
ENV APACHE_CONF_DIR=/etc/apache2
ENV APACHE_CONFDIR $APACHE_CONF_DIR
ENV APACHE_ENVVARS $APACHE_CONF_DIR/envvars

ENV APACHE_RUN_DIR /var/run
ENV APACHE_WORK_DIR /var/lib/apache2
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE $APACHE_RUN_DIR/apache2.pid
ENV LANG C

ENV CERTBOT_CONF_DIR /etc/letsencrypt

ENV CERTBOT_WORK_DIR /var/lib/letsencrypt
ENV CERTBOT_LOG_DIR /var/log/letsencrypt

ENV DEBIAN_FRONTEND noninteractive

RUN set -x &&\
  apt-get update && apt-get upgrade -y &&\
  apt-get install -y --no-install-recommends --no-install-suggests \
    sudo procps locales rsyslog cron ca-certificates curl git nodejs npm nano certbot python-certbot-apache apache2 &&\
  mkdir -p $APACHE_RUN_DIR $APACHE_LOCK_DIR $APACHE_LOG_DIR
    
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8

ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN set -x &&\
  useradd -m -u $USERID -G sudo $USERNAME &&\
  sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' &&\
  sed -i /etc/sudoers -re 's/^#includedir.*/## **Removed the include directive** ##"/g' &&\
  su $USERNAME -c "mkdir -p ${NODEAPPDIR} && mkdir -p ${NODECONFIGDIR} && chmod -R 766 $NODEAPPDIR"

RUN set -x &&\
  rm $APACHE_CONF_DIR/sites-available/000-default.conf $APACHE_CONF_DIR/sites-enabled/000-default.conf &&\
  rm $APACHE_CONF_DIR/sites-available/default-ssl.conf &&\
  rm -r $APACHE_WWW_DIR/html &&\
  mkdir -p $APACHE_CONF_DIR/custom &&\
  ln -sf /dev/stdout $APACHE_LOG_DIR/access.log &&\
  ln -sf /dev/stderr $APACHE_LOG_DIR/error.log
  
COPY ./configs/apache2.conf $APACHE_CONF_DIR/apache2.conf
COPY ./configs/custom-default.conf $APACHE_CONF_DIR/sites-available/000-custom-default.conf
COPY ./configs/custom-default-redirect.conf $APACHE_CONF_DIR/sites-available/000-custom-default-redirect.conf
COPY ./configs/custom-default-ssl.conf $APACHE_CONF_DIR/sites-available/000-custom-default-ssl.conf
COPY ./configs/custom/ $APACHE_CONF_DIR/custom
RUN apache2ctl stop

COPY ./apache.sh $NODEHOMEDIR/apache.sh
RUN chmod +x $NODEHOMEDIR/apache.sh

COPY ./nodejs.sh $NODEHOMEDIR/nodejs.sh
RUN chmod +x $NODEHOMEDIR/nodejs.sh

COPY ./status.sh $NODEHOMEDIR/status.sh
RUN chmod +x $NODEHOMEDIR/status.sh

COPY ./configs/crontab /etc/cron/crontab
RUN crontab /etc/cron/crontab
RUN service rsyslog start && service cron start

RUN set -x &&\
  apt-get clean autoclean &&\
  apt-get autoremove -y &&\
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*^

HEALTHCHECK CMD $NODEHOMEDIR/status.sh

USER $USERNAME
WORKDIR $NODEAPPDIR
VOLUME $NODEAPPDIR

ENTRYPOINT sudo $NODEHOMEDIR/apache.sh && $NODEHOMEDIR/nodejs.sh

EXPOSE $PORT 80 443