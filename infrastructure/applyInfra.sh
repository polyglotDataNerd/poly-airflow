#!/usr/bin/env bash
#sampe call
# source ~/poly-network-infrastructure/infrastructure/data_network_apply.sh 'production'

AWS_ACCESS_KEY_ID=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/AccessKey --query Parameters[0].Value --with-decryption --output text)
AWS_SECRET_ACCESS_KEY=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/SecretKey --query Parameters[0].Value --with-decryption --output text)
#shell parameter for env.
environment=$1

#copy tfstate files into dir
aws s3 cp s3://bigdata-utility/terraform/airflow/infra/$environment/$CURRENTDATE ~/solutions/poly-airflow/infrastructure/serviceinfra  --recursive --sse --quiet --include "*"

export TF_VAR_awsaccess=$AWS_ACCESS_KEY_ID
export TF_VAR_awssecret=$AWS_SECRET_ACCESS_KEY
export TF_VAR_environment=$environment
export TF_VAR_image=""
export TF_VAR_airflowpw=""
cd ~/solutions/poly-airflow/infrastructure/serviceinfra
terraform init
terraform get
terraform validate -json
terraform plan
terraform apply -auto-approve

#copy tfstate files to s3
aws s3 cp ~/solutions/poly-airflow/infrastructure/serviceinfra/ s3://bigdata-utility/terraform/airflow/infra/$environment/$CURRENTDATE/  --recursive --sse --quiet --exclude "*" --include "*terraform.tfstate*"

cd ~/solutions/poly-airflow/
