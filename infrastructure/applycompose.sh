#!/usr/bin/env bash
#sampe call
# source ~/poly-network-infrastructure/infrastructure/data_network_apply.sh 'production'

export AWS_ACCESS=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/AccessKey --query Parameters[0].Value --with-decryption --output text)
export AWS_SECRET=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/SecretKey --query Parameters[0].Value --with-decryption --output text)
export GitToken=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/GitToken --query Parameters[0].Value --with-decryption --output text)
DockerToken=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/DockerToken --query Parameters[0].Value --with-decryption --output text)
EpochTag="$(date +%s)"
CURRENTDATE="$(date +%Y)"
#shell parameter for env.
environment=$1
#image="712639424220.dkr.ecr.us-west-2.amazonaws.com/airflowr-$environment:$EpochTag"
export image="airflow-$environment:$EpochTag"
export AIRFLOW__CORE__REMOTE_LOGGING=True
export AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER=s3://bigdata-log/airflow
# https://stackoverflow.com/questions/44780736/setting-up-s3-for-logs-in-airflow/47947127#comment100117368_47947127
export AIRFLOW__CORE__REMOTE_LOG_CONN_ID=s3://$AWS_ACCESS:$AWS_SECRET@bigdata-log/airflow
export AIRFLOW__CORE__ENCRYPT_S3_LOGS=True
export AIRFLOW__CORE__SQL_ALCHEMY_CONN="postgresql+psycopg2://airflow:airflow@postgres:5432/airflow"

# DOCKER BUILD
cd ~/solutions/poly-airflow/infrastructure/build
# compose will only build webserver since postgres image already exists
docker-compose up -d
#docker-compose up postgres
#docker-compose up webserver

cd ~/solutions/poly-airflow/
