#!/usr/bin/env bash
AWS_ACCESS_KEY_ID=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/AccessKey --query Parameters[0].Value --with-decryption --output text)
AWS_SECRET_ACCESS_KEY=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/SecretKey --query Parameters[0].Value --with-decryption --output text)
GitToken=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/GitToken --query Parameters[0].Value --with-decryption --output text)
DockerToken=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/DockerToken --query Parameters[0].Value --with-decryption --output text)
EpochTag="$(date +%s)"
#shell parameter for env.
environment=$1
#image="712639424220.dkr.ecr.us-west-2.amazonaws.com/airflowr-$environment:$EpochTag"
image="airflow-$environment:$EpochTag"

#copy tfstate files into dir
aws s3 cp s3://bigdata-utility/terraform/airflow/$environment/$CURRENTDATE ~/solutions/zib-airflow/infrastructure/service  --recursive --sse --quiet --include "*"

export TF_VAR_awsaccess=$AWS_ACCESS_KEY_ID
export TF_VAR_awssecret=$AWS_SECRET_ACCESS_KEY
export TF_VAR_environment=$environment
export TF_VAR_image=$image
export TF_VAR_airflowpw=$AirflowDBPW
cd ~/solutions/zib-airflow/infrastructure/service
terraform init
terraform get
terraform plan
terraform destroy -auto-approve

#copy tfstate files to s3
aws s3 cp ~/solutions/zib-airflow/infrastructure/service/ s3://bigdata-utility/terraform/airflow/$environment/$CURRENTDATE/  --recursive --sse --quiet --exclude "*" --include "*terraform.tfstate*"





