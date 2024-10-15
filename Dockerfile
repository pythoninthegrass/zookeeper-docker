# syntax=docker/dockerfile:1.7.0

FROM ubuntu:trusty-20191217 AS base

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -qq update \
    && apt-get -qq install \
    --no-install-recommends -y \
        openjdk-7-jre-headless \
        openssh-server \
        supervisor \
        unzip \
        wget \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64/

FROM base AS builder

ARG ZOOKEEPER_VERSION=3.9.2
ENV ZOOKEEPER_VERSION=$ZOOKEEPER_VERSION

ARG JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
ENV JAVA_HOME=$JAVA_HOME

ARG ZK_HOME=/opt/apache-zookeeper-${ZOOKEEPER_VERSION}
ENV ZK_HOME=$ZK_HOME

RUN <<EOF
#!/usr/bin/env bash
wget -q http://mirror.vorboss.net/apache/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/apache-zookeeper-${ZOOKEEPER_VERSION}.tar.gz
wget -q https://www.apache.org/dist/zookeeper/KEYS
wget -q https://www.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/apache-zookeeper-${ZOOKEEPER_VERSION}.tar.gz.asc
wget -q https://www.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/apache-zookeeper-${ZOOKEEPER_VERSION}.tar.gz.sha512
EOF

RUN <<EOF
#!/usr/bin/env bash
sha512sum -c apache-zookeeper-${ZOOKEEPER_VERSION}.tar.gz.sha512
gpg --import KEYS
gpg --verify apache-zookeeper-${ZOOKEEPER_VERSION}.tar.gz.asc
EOF

RUN <<EOF
#!/usr/bin/env bash
tar -xzf "apache-zookeeper-${ZOOKEEPER_VERSION}.tar.gz" -C /opt
mv "${ZK_HOME}/conf/zoo_sample.cfg" "${ZK_HOME}/conf/zoo.cfg"
EOF

RUN sed  -i "s|/tmp/zookeeper|$ZK_HOME/data|g" $ZK_HOME/conf/zoo.cfg; mkdir $ZK_HOME/data

COPY start-zk.sh /usr/bin/start-zk.sh

# TODO: use `ubuntu:trusty-20191217` as runner
FROM builder AS runner

COPY --from=builder "${ZK_HOME}" "${ZK_HOME}"
COPY --from=builder /usr/bin/start-zk.sh /usr/bin/start-zk.sh

WORKDIR "${ZK_HOME}"

VOLUME ["${ZK_HOME}/conf", "${ZK_HOME}/data"]

EXPOSE 2181
EXPOSE 2888
EXPOSE 3888

# setup standard non-root user for use downstream
ENV USER_NAME=appuser
ENV USER_UID=1000
ENV USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USER_NAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USER_NAME

USER $USER_NAME

CMD ["/bin/bash", "-c", "/usr/bin/start-zk.sh"]

LABEL org.opencontainers.image.title="zookeeper"
