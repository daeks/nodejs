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
ENV NODETMPDIR $NODEHOMEDIR/app/cache

ENV DEBIAN_FRONTEND noninteractive

RUN set -x &&\
  apt-get update && apt-get upgrade -y &&\
  apt-get install -y --no-install-recommends --no-install-suggests \
    procps locales ca-certificates curl git nodejs npm nano
    
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8

RUN set -x &&\
  useradd -m -u $USERID $USERNAME &&\
  su $USERNAME -c "mkdir -p ${NODEAPPDIR} && mkdir -p ${NODECONFIGDIR} && chmod -R 766 $NODEAPPDIR"

RUN set -x &&\
  apt-get clean autoclean &&\
  apt-get autoremove -y &&\
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*^

COPY ./entrypoint.sh $NODEHOMEDIR/entrypoint.sh
RUN chmod +x $NODEHOMEDIR/entrypoint.sh

HEALTHCHECK CMD curl -f http://localhost:$PORT/ || exit 1

USER $USERNAME
WORKDIR $NODEAPPDIR
VOLUME $NODEAPPDIR

ENTRYPOINT $NODEHOMEDIR/entrypoint.sh

EXPOSE $PORT