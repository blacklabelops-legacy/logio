FROM blacklabelops/centos
MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

# Propert permissions
ENV CONTAINER_USER logio
ENV CONTAINER_UID 1000
ENV CONTAINER_GROUP logio
ENV CONTAINER_GID 1000

RUN /usr/sbin/groupadd --gid $CONTAINER_GID logio && \
    /usr/sbin/useradd --uid $CONTAINER_UID --gid $CONTAINER_GID --create-home --shell /bin/bash logio

# install dev tools
ENV VOLUME_DIRECTORY=/opt/server
RUN curl --silent --location https://rpm.nodesource.com/setup | bash - && \
    yum install -y \
    curl \
    nodejs \
    wget \
    gcc-c++ \
    openssl \
    make && \
    yum clean all && rm -rf /var/cache/yum/* && \
    mkdir -p ${VOLUME_DIRECTORY}/keys && \
    chown -R $CONTAINER_UID:$CONTAINER_GID ${VOLUME_DIRECTORY}/keys && \
    npm install -g log.io --user 'root'

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
