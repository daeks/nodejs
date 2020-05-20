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

ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

ENV DEBIAN_FRONTEND noninteractive

RUN set -x &&\
  apt-get update && apt-get upgrade -y &&\
  apt-get install -y --no-install-recommends --no-install-suggests \
    procps locales rsyslog cron ca-certificates curl git nodejs npm nano certbot python-certbot-apache apache2
    
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8

ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN set -x &&\
  useradd -m -u $USERID $USERNAME &&\
  su $USERNAME -c "mkdir -p ${NODEAPPDIR} && mkdir -p ${NODECONFIGDIR} && chmod -R 766 $NODEAPPDIR"

RUN set -x &&\
  rm ${APACHE_CONF_DIR}/sites-enabled/000-default.conf ${APACHE_CONF_DIR}/sites-available/000-default.conf &&\
  rm -r ${APACHE_WWW_DIR}/html &&\
  mkdir -p ${APACHE_CONF_DIR}/custom &&\
  ln -sf /dev/stdout /var/log/apache2/access.log &&\
  ln -sf /dev/stderr /var/log/apache2/error.log
  
COPY ./configs/apache2.conf ${APACHE_CONF_DIR}/apache2.conf
COPY ./configs/custom-default.conf ${APACHE_CONF_DIR}/sites-available/000-custom-default.conf
COPY ./configs/custom-default-ssl.conf ${APACHE_CONF_DIR}/sites-available/000-custom-default-ssl.conf
COPY ./custom/ ${APACHE_CONF_DIR}/custom
RUN service apache2 stop

COPY ./setup.sh $NODEHOMEDIR/setup.sh
RUN chmod +x $NODEHOMEDIR/setup.sh && $NODEHOMEDIR/setup.sh
#RUN rm $NODEHOMEDIR/setup.sh

COPY ./configs/crontab /etc/cron/crontab
RUN crontab /etc/cron/crontab
RUN service rsyslog start && service cron start

COPY ./entrypoint.sh $NODEHOMEDIR/entrypoint.sh
RUN chmod +x $NODEHOMEDIR/entrypoint.sh

RUN set -x &&\
  apt-get clean autoclean &&\
  apt-get autoremove -y &&\
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*^

HEALTHCHECK CMD curl -f http://localhost:$PORT/ && curl -f http://localhost/ && curl -f https://localhost/ || exit 1

USER $USERNAME
WORKDIR $NODEAPPDIR
VOLUME $NODEAPPDIR

ENTRYPOINT $NODEHOMEDIR/entrypoint.sh

EXPOSE $PORT 80 443