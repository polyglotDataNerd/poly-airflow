#!/bin/bash

#TRY_LOOP="10"
#
#apt-get install -y netcat
#
#j=0
#while ! nc -z db 5432; do
#  j=$((j + 1))
#  if [ $j -ge $TRY_LOOP ]; then
#    echo "$(date) - postgres still not reachable."
#    break
#  fi
#  echo "$(date) - Waiting for postgres... $j/$TRY_LOOP"
#  sleep 2
#done
airflow db init &&
sleep 30
airflow webserver & airflow scheduler
sleep 60
airflow users create -u airflow -p airflow -r Admin -f airflow -l airflow -e airflow@airflow.com
