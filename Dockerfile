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
RUN curl --silent --location https://rpm.nodesource.com/setup | bash - && \
    yum install -y \
    curl \
    nodejs \
    wget \
    gcc-c++ \
    make && \
    yum clean all && rm -rf /var/cache/yum/* && \
    npm install -g log.io --user 'root'

VOLUME ["/opt/database"]
EXPOSE 28778 28777

USER $CONTAINER_UID
COPY imagescripts/docker-entrypoint.sh /opt/logio/docker-entrypoint.sh
ENTRYPOINT ["/opt/logio/docker-entrypoint.sh"]
CMD ["logio"]
