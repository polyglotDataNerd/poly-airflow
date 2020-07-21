#!/usr/bin/env python3
# -*- coding: utf-8 -*-
__author__ = 'gbartolome'

from datetime import datetime
import os
from airflow import DAG
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.bash_operator import BashOperator

# base DAG
baseDAG = DAG('-DAG',
              description='runs when DAG is deployed',
              schedule_interval='30 07 * * *',
              start_date=datetime(2020, 3, 23),
              catchup=False)

start = DummyOperator(task_id='yelp-Loader-start',
                      dag=baseDAG)
end = DummyOperator(task_id='yelp-Loader-end',
                    dag=baseDAG)

create_command = "./usr/local/airflow/bash/yelp_ecs_ETL.sh"
if os.path.exists(create_command):
    command = BashOperator(
        task_id='yelp',
        bash_command=create_command,
        dag=baseDAG,
    )
else:
    raise Exception("Cannot loacate{}".format(create_command))

start >> command >> end
