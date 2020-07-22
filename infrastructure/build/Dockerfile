# VERSION 1.10.9
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM python:3.7-slim-buster
LABEL maintainer="Puckel_"

# Never prompt the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# AWS
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_REGION=us-west-2
ARG GitToken

# Airflow
ARG AIRFLOW_VERSION=1.10.9
ARG AIRFLOW_USER_HOME=/usr/local/airflow
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
ARG AIRFLOW__CORE__REMOTE_LOGGING
ARG AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER
ARG AIRFLOW__CORE__REMOTE_LOG_CONN_ID
ARG AIRFLOW__CORE__ENCRYPT_S3_LOGS
ARG AIRFLOW__CORE__EXECUTOR
ARG AIRFLOW__CORE__SQL_ALCHEMY_CONN
ENV AIRFLOW_HOME=${AIRFLOW_USER_HOME}

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

# Disable noisy "Handling signal" log messages:
# ENV GUNICORN_CMD_ARGS --log-level WARNING
COPY requirements.txt .

# Check env varibles passed by docker-compose
RUN echo $AIRFLOW__CORE__REMOTE_LOGGING \
    && echo $AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER \
    && echo $AIRFLOW__CORE__REMOTE_LOG_CONN_ID \
    && echo $AIRFLOW__CORE__ENCRYPT_S3_LOGS
#    && echo $AIRFLOW__CORE__EXECUTOR \
#    && echo $AIRFLOW__CORE__SQL_ALCHEMY_CONN

RUN set -ex \
    && buildDeps=' \
      freetds-dev \
      libkrb5-dev \
      libsasl2-dev \
      libssl-dev \
      libffi-dev \
      libpq-dev \
      git \
    ' \
    && apt-get update && apt-get install -y git  && git --version \
    && git config --global url."https://${GitToken}:@github.com/".insteadOf "https://github.com/" \
    && git clone -b master https://github.com/polyglotDataNerd/poly-airflow.git ${AIRFLOW_USER_HOME}/poly-airflow \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
      $buildDeps \
      freetds-bin \
      build-essential \
      default-libmysqlclient-dev \
      apt-utils \
      curl \
      rsync \
      netcat \
      locales \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_USER_HOME} airflow \
    # install AWS CLI
    && pip install awscli \
    && pip install -U pip setuptools wheel \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install apache-airflow[crypto,celery,postgres,hive,jdbc,mysql,ssh${AIRFLOW_DEPS:+,}${AIRFLOW_DEPS}]==${AIRFLOW_VERSION} \
    && pip install apache-airflow[s3] \
    && pip install 'redis==3.2' \
    && pip install --user psycopg2-binary \
    && if [ -n "${PYTHON_DEPS}" ]; then pip install ${PYTHON_DEPS}; fi \
    && pip install -r requirements.txt \
    && curl -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest \
    && chmod +x /usr/local/bin/ecs-cli \
    && apt-get -y install vim \
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
      /var/lib/apt/lists/* \
      /tmp/* \
      /var/tmp/* \
      /usr/share/man \
      /usr/share/doc \
      /usr/share/doc-base
#   &&  cp ~/poly-airflow/src/dags/test_dag.py ${AIRFLOW_USER_HOME}/dags

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x entrypoint.sh
COPY . ${AIRFLOW_USER_HOME}
RUN chown -R airflow: ${AIRFLOW_USER_HOME}

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_USER_HOME}
ENTRYPOINT ["/entrypoint.sh"]
# configure AWS Creds after entrypoint
RUN aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID} \
        && aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY} \
        && aws configure set default.region ${AWS_REGION}
# Airflow Logging Overrides
ENV AIRFLOW__CORE__REMOTE_LOGGING=${AIRFLOW__CORE__REMOTE_LOGGING}
ENV AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER=${AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER}
ENV AIRFLOW__CORE__REMOTE_LOG_CONN_ID=${AIRFLOW__CORE__REMOTE_LOG_CONN_ID}
ENV AIRFLOW__CORE__ENCRYPT_S3_LOGS=${AIRFLOW__CORE__ENCRYPT_S3_LOGS}
ENV AIRFLOW__CORE__EXECUTOR=${AIRFLOW__CORE__EXECUTOR}
ENV AIRFLOW__CORE__SQL_ALCHEMY_CONN=${AIRFLOW__CORE__SQL_ALCHEMY_CONN}
CMD ["webserver"]
