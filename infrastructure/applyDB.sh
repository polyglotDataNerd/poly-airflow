#!/usr/bin/env bash
#sampe call
# source ~/zib-network-infrastructure/infrastructure/data_network_apply.sh 'production'

AWS_ACCESS_KEY_ID=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/AccessKey --query Parameters[0].Value --with-decryption --output text)
AWS_SECRET_ACCESS_KEY=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/SecretKey --query Parameters[0].Value --with-decryption --output text)
AirflowDBPW=$(aws ssm get-parameters --names /airflow/polyglotDataNerd/db/pw --query Parameters[0].Value --with-decryption --output text)
#shell parameter for env.
environment=$1


#copy tfstate files into dir
aws s3 cp s3://bigdata-utility/terraform/airflow/db/$environment/$CURRENTDATE ~/solutions/zib-airflow/infrastructure/servicedb  --recursive --sse --quiet --include "*"

export TF_VAR_awsaccess=$AWS_ACCESS_KEY_ID
export TF_VAR_awssecret=$AWS_SECRET_ACCESS_KEY
export TF_VAR_environment=$environment
export TF_VAR_image=""
export TF_VAR_airflowpw=$AirflowDBPW
cd ~/solutions/zib-airflow/infrastructure/servicedb
terraform init
terraform get
terraform validate -json
terraform plan
terraform apply -auto-approve

#copy tfstate files to s3
aws s3 cp ~/solutions/zib-airflow/infrastructure/servicedb/ s3://bigdata-utility/terraform/airflow/db/$environment/$CURRENTDATE/  --recursive --sse --quiet --exclude "*" --include "*terraform.tfstate*"

cd ~/solutions/zib-airflow/
