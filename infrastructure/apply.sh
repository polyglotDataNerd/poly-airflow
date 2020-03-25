#!/usr/bin/env bash
#sampe call
# source ~/zib-network-infrastructure/infrastructure/data_network_apply.sh 'production'

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
export AIRFLOW__CORE__EXECUTOR=LocalExecutor
export AIRFLOW__CORE__SQL_ALCHEMY_CONN="postgresql+psycopg2://airflow:airflow@postgres:5432/airflow"

##copy tfstate files into dir
#aws s3 cp s3://bigdata-utility/terraform/networking/$environment/$CURRENTDATE ~/solutions/zib-network-infrastructure/infrastructure/networking  --recursive --sse --quiet --include "*"
#
#export TF_VAR_awsaccess=$AWS_ACCESS_KEY_ID
#export TF_VAR_awssecret=$AWS_SECRET_ACCESS_KEY
#export TF_VAR_environment=$environment
#cd ~/solutions/zib-network-infrastructure/infrastructure/networking
#terraform init
#terraform get
#terraform plan
#terraform apply -auto-approve
#
##copy tfstate files to s3
#aws s3 cp ~/solutions/zib-network-infrastructure/infrastructure/networking/ s3://bigdata-utility/terraform/networking/$environment/$CURRENTDATE/  --recursive --sse --quiet --exclude "*" --include "*terraform.tfstate*"

# DOCKER BUILD
cd ~/solutions/zib-airflow/infrastructure/build
#docker build -f Dockerfile \
#  -t airflow-$environment:$EpochTag -t zib-airflow-$environment:$EpochTag \
#  --build-arg AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
#  --build-arg AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
#  --build-arg GitToken=$GitToken \
#  --force-rm \
#  --no-cache .
#echo $DockerToken | docker login --username polyglotdatanerd --password-stdin
#docker tag $image "polyglotdatanerd/development"
#eval "$(aws ecr get-login --region us-west-2 --no-include-email)"
#docker push $image
#docker push polyglotdatanerd/development

# compose will only build webserver since postgres image already exists
docker-compose up -d

#docker-compose up postgres
#docker-compose up webserver

cd ~/solutions/zib-airflow/
