from datetime import datetime, timedelta
from airflow import DAG
from tools.slack_utils import slack_failed_task

# import using try/except to support both airflow 1 and 2
# liveness probe on the scheduler to check health
try:
    from airflow.operators.bash import BashOperator
except ModuleNotFoundError:
    from airflow.operators.bash import BashOperator

dag = DAG(
    dag_id="canary_dag",
    default_args={
        "owner": "airflow",
        "on_failure_callback": slack_failed_task,
    },
    schedule_interval=None,
    start_date=datetime(2022, 1, 1),
    dagrun_timeout=timedelta(minutes=5),
    is_paused_upon_creation=False,
    catchup=False,
)

# WARNING: while `DummyOperator` would use less resources, the check can't see those tasks
#          as they don't create LocalTaskJob instances
task = BashOperator(
    task_id="canary_task",
    bash_command="echo 'Hello World!'",
    dag=dag,
)
