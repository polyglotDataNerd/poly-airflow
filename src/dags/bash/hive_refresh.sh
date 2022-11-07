#!/usr/bin/env bash

aws s3 cp s3://poly-data-utils/secrets/dataengineering-prod.pem /usr/local/airflow/dags/bash
aws emr ssh --cluster-id j-HMAMW2V4YNYA --key-pair-file /usr/local/airflow/dags/bash/dataengineering-prod.pem --command "hive -f s3://poly-data-utils/hive/hive_repair.hql"


