#!/usr/bin/env bash
AWS_ACCESS_KEY_ID=$(aws ssm get-parameters --names /s3/sweetgreen/admin/AccessKey --query Parameters[0].Value --with-decryption --output text)
AWS_SECRET_ACCESS_KEY=$(aws ssm get-parameters --names /s3/sweetgreen/admin/SecretKey --query Parameters[0].Value --with-decryption --output text)
Proxy_KEY=$(aws ssm get-parameters --names /s3/sweetgreen/admin/bastion --query Parameters[0].Value --with-decryption --output text)
CURRENTDATE="$(date  +%Y)"
#shell parameter for env.
environment=$1

#copy tfstate files into dir
aws s3 cp s3://bigdata-utility/terraform/networking/$environment/$CURRENTDATE ~/solutions/zib-network-infrastructure/infrastructure/networking  --recursive --sse --quiet --include "*"

export TF_VAR_awsaccess=$AWS_ACCESS_KEY_ID
export TF_VAR_awssecret=$AWS_SECRET_ACCESS_KEY
export TF_VAR_environment=$environment
cd ~/solutions/zib-network-infrastructure/infrastructure/networking
terraform init
terraform get
terraform plan
terraform destroy -auto-approve

#copy tfstate files to s3
aws s3 cp ~/solutions/zib-network-infrastructure/infrastructure/networking/ s3://bigdata-utility/terraform/networking/$environment/$CURRENTDATE/  --recursive --sse --quiet --exclude "*" --include "*terraform.tfstate*"





