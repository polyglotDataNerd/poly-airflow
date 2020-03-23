#!/usr/bin/env python3
# -*- coding: utf-8 -*-
__author__ = 'gbartolome'

from datetime import datetime

from airflow import DAG
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.bash_operator import BashOperator

# base DAG
baseDAG = DAG('test-DAG',
              description='runs when DAG is deployed',
              schedule_interval='30 07 * * *',
              start_date=datetime(2020, 3, 23),
              catchup=False)

start = DummyOperator(task_id='test-Loader-start',
                      dag=baseDAG)
end = DummyOperator(task_id='test-Loader-end',
                    dag=baseDAG)

command = BashOperator(
    task_id='test',
    bash_command='echo HELLO WORLD',
    dag=baseDAG,
)

start >> command >> end
