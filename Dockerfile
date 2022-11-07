FROM python:3.8-slim-bullseye

ARG SQL_ALCHEMY_CONN
ENV AIRFLOW__CORE__SQL_ALCHEMY_CONN=$SQL_ALCHEMY_CONN
ENV AWS_DEFAULT_REGION=us-west-2

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -q -y python3-pip libsnappy-dev libssl-dev default-libmysqlclient-dev libsasl2-dev libpq-dev libicu-dev && \
  apt-get install -q -y git wget && \
  pip3 install --upgrade pip && \
  apt-get install -qy curl && \
  apt-get install -qy unixodbc unixodbc-dev libsasl2-modules-gssapi-mit && \
  apt-get install -qy jq

# Set environment variables.
ENV AIRFLOW_HOME=/usr/local/airflow
ENV PYTHONPATH=/usr/local/airflow
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV HOST='0.0.0.0'

# Install requirements.
COPY ./requirements.txt /tmp/
RUN pip3 install -r /tmp/requirements.txt

# Copy source and tests.
COPY src/ $AIRFLOW_HOME/
WORKDIR $AIRFLOW_HOME

