FROM debian:buster-slim
LABEL maintainer="github.com/daeks"

ENV GIT OFF
ENV GIT_TOKEN <token>
ENV GIT_URL https://$GIT_TOKEN:x-oauth-basic@github.com/<user>/<repo>.git

ENV PORT 8000

ENV USERNAME=nodejs
ARG USERID=1000

ENV NODEAPPDIR /home/$USERNAME/app
ENV NODECONFIGDIR /home/$USERNAME/config

ENV DEBIAN_FRONTEND noninteractive

RUN set -x &&\
  apt-get update && apt-get upgrade -y &&\
  apt-get install -y --no-install-recommends --no-install-suggests \
    procps locales ca-certificates curl git nodejs npm nano
    
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8

RUN set -x &&\
  useradd -m -u $USERID $USERNAME &&\
  su $USERNAME -c "mkdir -p ${NODEAPPDIR} && mkdir -p ${NODECONFIGDIR}"

RUN if [ "$GIT" != "OFF" ]; then git clone $GIT_URL $NODEAPPDIR/ &&\
  chmod -R 777 $NODEAPPDIR/cache; fi
RUN chown -R $USERNAME:$USERNAME $NODEAPPDIR/

RUN set -x &&\
  apt-get clean autoclean &&\
  apt-get autoremove -y &&\
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*^
  
HEALTHCHECK CMD curl -f http://localhost:$PORT/ || exit 1

USER $USERNAME
WORKDIR $NODEAPPDIR
VOLUME $NODEAPPDIR

ENTRYPOINT npm install && node $NODEAPPDIR/index.js $NODECONFIGDIR/config.js

EXPOSE $PORT