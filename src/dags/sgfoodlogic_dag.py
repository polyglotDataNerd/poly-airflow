#!/usr/bin/env python3
# -*- coding: utf-8 -*-
__author__ = 'gbartolome'

import importlib
from datetime import datetime

from airflow import DAG
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
# airflow repo
from custom.operators import slack_error
from sg_foodlogiq_loader.sgfoodlogic_get import sgFoodLogic

loadincidents = sgFoodLogic()

dag = DAG('fooglogic-Loader',
          description='Calls the food logic API to get incident data and put into s3',
          schedule_interval='30 07 * * *',
          start_date=datetime(2018, 6, 18),
          catchup=False,
          default_args=slack_error.get_default_args())

t1 = DummyOperator(task_id='fooglogic-Loader-start',
                   dag=dag)
t2 = DummyOperator(task_id='fooglogic-Loader-end',
                   dag=dag)

t3 = PythonOperator(
    task_id='pull_foodlogic',
    dag=dag,
    python_callable=loadincidents.pull_foodlogic)
t3.set_upstream(t1)
t3.set_downstream(t2)
