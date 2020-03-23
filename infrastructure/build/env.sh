#!/bin/bash

export AWS_ACCESS=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/AccessKey --query Parameters[0].Value --with-decryption --output text)
export AWS_SECRET=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/SecretKey --query Parameters[0].Value --with-decryption --output text)
export GitToken=$(aws ssm get-parameters --names /s3/polyglotDataNerd/admin/GitToken --query Parameters[0].Value --with-decryption --output text)