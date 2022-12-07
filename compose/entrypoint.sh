#!/bin/bash

TRY_LOOP="20"

apt-get install -y netcat

j=0
while ! nc -z postgres 5432; do
  j=$((j + 1))
  if [ $j -ge $TRY_LOOP ]; then
    echo "$(date) - postgres still not reachable."
    break
  fi
  echo "$(date) - Waiting for postgres... $j/$TRY_LOOP"
  sleep 1
done

airflow airflow db init
airflow scheduler &
airflow webserver
