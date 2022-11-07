from airflow.models import DagRun
import psycopg2
from airflow.models import Variable


def get_task_status(dag_id, task_id):
    """ Returns the status of the last dag run for the given dag_id
    1. The code is very similar to the above function, I use it as the foundation for many similar problems/solutions
    2. The key difference is that in the return statement, we can directly access the .get_task_instance passing our desired task_id and its state


    Args:
        dag_id (str): The dag_id to check
        task_id (str): The task_id to check
    Returns:
        List - The status of the last dag run for the given dag_id
    """
    last_dag_run = DagRun.find(dag_id=dag_id)
    last_dag_run.sort(key=lambda x: x.execution_date, reverse=True)
    return last_dag_run[0].get_task_instance(task_id).state

""" Production database """
def execute_query_with_psycopg(query):
    conn_args = dict(
        host=Variable.get("TS_PROD_HOST"),
        user=Variable.get("TS_PROD_UID"),
        password=Variable.get("TS_PROD_PASSWORD"),
        dbname='tsdb',
        port=36759)
    conn = psycopg2.connect(**conn_args)
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute(query)

""" Main database """
def execute_query_with_psycopg_main(query):
    conn_args = dict(
        host=Variable.get("TS_MAIN_HOST"),
        user=Variable.get("TS_MAIN_UID"),
        password=Variable.get("TS_MAIN_PASSWORD"),
        dbname='tsdb',
        port=30086)
    conn = psycopg2.connect(**conn_args)
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute(query)