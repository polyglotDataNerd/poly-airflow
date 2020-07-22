#!/usr/bin/env bash
#sampe call
# source ~/poly-network-infrastructure/infrastructure/data_network_apply.sh 'production'
# https://github.com/nicor88/aws-ecs-airflow

AWS_ACCESS_KEY_ID=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/AccessKey --query Parameters[0].Value --with-decryption --output text)
AWS_SECRET_ACCESS_KEY=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/SecretKey --query Parameters[0].Value --with-decryption --output text)
GitToken=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/GitToken --query Parameters[0].Value --with-decryption --output text)
DockerToken=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/DockerToken --query Parameters[0].Value --with-decryption --output text)
AirflowDBConn=$(aws ssm get-parameters --names /airflow/polyglotDataNerd/db/host --query Parameters[0].Value --with-decryption --output text)
EpochTag="$(date +%s)"
#shell parameter for env.
environment=$1
image="712639424220.dkr.ecr.us-west-2.amazonaws.com/airflow-$environment:$EpochTag"
#image="712639424220.dkr.ecr.us-west-2.amazonaws.com/airflow-$environment:1585408909"
BastionIP="$(curl ifconfig.me)"
#image="airflow-$environment:$EpochTag"
AIRFLOW__CORE__REMOTE_LOGGING=True
AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER=s3://bigdata-log/airflow
# https://stackoverflow.com/questions/44780736/setting-up-s3-for-logs-in-airflow/47947127#comment100117368_47947127
AIRFLOW__CORE__REMOTE_LOG_CONN_ID=s3://$AWS_ACCESS:$AWS_SECRET@bigdata-log/airflow
AIRFLOW__CORE__ENCRYPT_S3_LOGS=True
AIRFLOW__CORE__EXECUTOR=LocalExecutor
AIRFLOW__CORE__SQL_ALCHEMY_CONN=$AirflowDBConn

# DOCKER BUILD
cd ~/solutions/poly-airflow/infrastructure/build
docker build -f Dockerfile \
  -t $image -t "polyglotdatanerd/airflow:$EpochTag" \
  --build-arg AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  --build-arg AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  --build-arg GitToken=$GitToken \
  --build-arg AIRFLOW__CORE__REMOTE_LOGGING=$AIRFLOW__CORE__REMOTE_LOGGING \
  --build-arg AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER=$AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER \
  --build-arg AIRFLOW__CORE__REMOTE_LOG_CONN_ID=$AIRFLOW__CORE__REMOTE_LOG_CONN_ID \
  --build-arg AIRFLOW__CORE__ENCRYPT_S3_LOGS=$AIRFLOW__CORE__ENCRYPT_S3_LOGS \
  --build-arg AIRFLOW__CORE__EXECUTOR=$AIRFLOW__CORE__EXECUTOR \
  --build-arg AIRFLOW__CORE__SQL_ALCHEMY_CONN=$AIRFLOW__CORE__SQL_ALCHEMY_CONN \
  --force-rm \
  --no-cache .
#echo $DockerToken | docker login --username polyglotdatanerd --password-stdin
eval "$(aws ecr get-login --region us-west-2 --no-include-email)"
docker push $image
#docker push "polyglotdatanerd/airflow:$EpochTag"

#copy tfstate files into dir
aws s3 cp s3://bigdata-utility/terraform/airflow/service/$environment/$CURRENTDATE ~/solutions/poly-airflow/infrastructure/service --recursive --sse --quiet --include "*"

export TF_VAR_awsaccess=$AWS_ACCESS_KEY_ID
export TF_VAR_awssecret=$AWS_SECRET_ACCESS_KEY
export TF_VAR_environment=$environment
export TF_VAR_image=$image
export TF_VAR_airflowpw=""
export TF_VAR_bastionip=$BastionIP
cd ~/solutions/poly-airflow/infrastructure/service
terraform init
terraform get
terraform validate
terraform plan
terraform apply -auto-approve

#copy tfstate files to s3
aws s3 cp ~/solutions/poly-airflow/infrastructure/service/ s3://bigdata-utility/terraform/airflow/service/$environment/$CURRENTDATE/ --recursive --sse --quiet --exclude "*" --include "*terraform.tfstate*"

cd ~/solutions/poly-airflow/
