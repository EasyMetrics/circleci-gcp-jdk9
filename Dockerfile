FROM openjdk:9

MAINTAINER EasyMetrics <joshuaw@easymetrics.com>

ENV GRADLE_VERSION=4.8.1
ENV CLOUD_SDK_VERSION 206.0.0

USER root

# ...
# Configure Install Environment
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install and Configure Google Cloud SDK - docker build -f Dockerfile -t circleci-gcp-jdk9 .
# ...

RUN apt-get -qqy update && apt-get -qqy upgrade && apt-get install -qqy \
        curl \
        gcc \
        python-dev \
        python-setuptools \
        python-pip \
        apt-transport-https \
        lsb-release \
        openssh-client \
        git

RUN apt-get -qqy update && apt-get -qqy upgrade && \
    pip install -U crcmod && \
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb https://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update && \
    apt-get install -y google-cloud-sdk=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-app-engine-python=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-app-engine-python-extras=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-app-engine-java=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-app-engine-go=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-datalab=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-datastore-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-pubsub-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-bigtable-emulator=${CLOUD_SDK_VERSION}-0 \
        google-cloud-sdk-cbt=${CLOUD_SDK_VERSION}-0 \
        kubectl && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
gcloud config set metrics/environment github_docker_image

# Install Gradle Version: $GRADLE_VERSION
RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/gradle.zip \
    https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
  && unzip -d /opt /tmp/gradle.zip \
  && rm /tmp/gradle.zip \
  && ln -s /opt/gradle-* /opt/gradle \
  && /opt/gradle/bin/gradle -version

# Update PATH for Java tools
RUN export PATH=$PATH:/opt/gradle/bin
ENV PATH="/opt/gradle/bin:$PATH"

# Install and Configure Docker Tooling
# ...

RUN echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/90circleci \
  && echo 'APT::Get::force-Yes "true";' >> /etc/apt/apt.conf.d/90circleci \
  && echo 'DPkg::Options "--force-confnew";' >> /etc/apt/apt.conf.d/90circleci

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y  -q --no-install-recommends \
    git mercurial xvfb \
    locales sudo openssh-client ca-certificates tar gzip parallel \
    net-tools netcat unzip zip bzip2 apt-transport-https build-essential libssl-dev \
    curl g++ gcc git make wget && rm -rf /var/lib/apt/lists/* && apt-get -y autoclean

# Set timezone to UTC by default
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

# Use unicode
RUN locale-gen C.UTF-8 || true
ENV LANG=C.UTF-8

# install jq
RUN JQ_URL=$(curl --location --fail --retry 3 https://api.github.com/repos/stedolan/jq/releases/latest  | grep browser_download_url | grep '/jq-linux64"' | grep -o -e 'https.*jq-linux64') \
  && curl --silent --show-error --location --fail --retry 3 --output /usr/bin/jq $JQ_URL \
  && chmod +x /usr/bin/jq

# Install Docker

# https://download.docker.com/linux/static/stable/x86_64/ returns the URL of the latest binary when you hit the directory
# We curl this URL and `grep` the version out.

RUN set -ex \
  && export DOCKER_VERSION=$(curl --silent --fail --retry 3 https://download.docker.com/linux/static/stable/x86_64/  | grep -P -o 'docker-\d+\.\d+\.\d+-ce\.tgz' | head -n 1) \
  && DOCKER_URL="https://download.docker.com/linux/static/stable/x86_64/${DOCKER_VERSION}" \
  && echo Docker URL: $DOCKER_URL \
  && curl --silent --show-error --location --fail --retry 3 --output /tmp/docker.tgz "${DOCKER_URL}" \
  && ls -lha /tmp/docker.tgz \
  && tar -xz -C /tmp -f /tmp/docker.tgz \
  && mv /tmp/docker/* /usr/bin \
  && rm -rf /tmp/docker /tmp/docker.tgz

# docker compose
RUN COMPOSE_URL=$(curl --location --fail --retry 3 https://api.github.com/repos/docker/compose/releases/latest | jq -r '.assets[] | select(.name == "docker-compose-Linux-x86_64") | .browser_download_url') \
  && curl --silent --show-error --location --fail --retry 3 --output /usr/bin/docker-compose $COMPOSE_URL \
  && chmod +x /usr/bin/docker-compose

# install dockerize
RUN DOCKERIZE_URL=$(curl --location --fail --retry 3 https://api.github.com/repos/jwilder/dockerize/releases/latest | jq -r '.assets[] | select(.name | startswith("dockerize-linux-amd64")) | .browser_download_url') \
  && curl --silent --show-error --location --fail --retry 3 --output /tmp/dockerize-linux-amd64.tar.gz $DOCKERIZE_URL \
  && tar -C /usr/local/bin -xzvf /tmp/dockerize-linux-amd64.tar.gz \
  && rm -rf /tmp/dockerize-linux-amd64.tar.gz

RUN groupadd --gid 3434 circleci \
  && useradd --uid 3434 --gid circleci --shell /bin/bash --create-home circleci \
  && echo 'circleci ALL=NOPASSWD: ALL' >> /etc/sudoers.d/50-circleci \
  && echo 'Defaults    env_keep += "DEBIAN_FRONTEND"' >> /etc/sudoers.d/env_keep

USER circleci

CMD ["/bin/sh"]