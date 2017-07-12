FROM node:6
MAINTAINER Richard Bateman <taxilian@gmail.com>

# Propert permissions
ENV CONTAINER_USER logio
ENV CONTAINER_UID 2000
ENV CONTAINER_GROUP logio
ENV CONTAINER_GID 2000

RUN /usr/sbin/groupadd --gid $CONTAINER_GID logio && \
    /usr/sbin/useradd --uid $CONTAINER_UID --gid $CONTAINER_GID --create-home --shell /bin/bash logio

# install dev tools
ENV VOLUME_DIRECTORY=/opt/server
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y wget openssl build-essential \
    && mkdir -p ${VOLUME_DIRECTORY}/keys \
    && chown -R $CONTAINER_UID:$CONTAINER_GID ${VOLUME_DIRECTORY}/keys \
    && npm install -g log.io pm2 --user 'root' \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists \
    && rm -rf /tmp/*

COPY configGen /opt/configGen
RUN cd /opt/configGen && npm i

ENV DELAYED_START=
ENV LOGIO_ADMIN_USER=
ENV LOGIO_ADMIN_PASSWORD=
ENV LOGIO_CERTIFICATE_DNAME=
ENV LOGIO_HARVESTER_MASTER_HOST=
ENV LOGIO_HARVESTER_MASTER_PORT=
ENV LOGIO_HARVESTER_NODENAME=
ENV LOGIO_HARVESTER_STREAMNAME=
ENV LOGIO_HARVESTER_LOGFILES=
ENV LOGS_DIRECTORIES=
ENV LOG_FILE_PATTERN=

VOLUME ["${VOLUME_DIRECTORY}"]
EXPOSE 28778 28777

USER $CONTAINER_UID
COPY imagescripts/*.sh /opt/logio/

ENTRYPOINT ["/opt/logio/docker-entrypoint.sh"]
CMD ["logio"]
