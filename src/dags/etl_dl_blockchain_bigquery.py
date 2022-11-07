import sys

from airflow import DAG
from airflow.providers.amazon.aws.operators.emr import (
    EmrCreateJobFlowOperator, EmrAddStepsOperator, EmrTerminateJobFlowOperator
)
from airflow.operators.dummy import DummyOperator
from datetime import datetime, timedelta
import logging
from airflow.models import Variable
from airflow.providers.amazon.aws.sensors.emr import (EmrStepSensor)
from tools.slack_utils import slack_failed_task

Hivehost = Variable.get("jdbc_hive_host")
Hiveuid = Variable.get("hive_uid")
Hivepwd = Variable.get("hive_pwd")

logger = logging.getLogger(__name__)

default_args = {
    'owner': 'data-platform',
    'email': ['gerard@poly.tools'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 1,
    "on_failure_callback": slack_failed_task,
}

dag = DAG(
    dag_id='etl_dl_blockchain_bigquery_refresh',
    default_args=default_args,
    schedule_interval='30 00 * * *',
    max_active_runs=1,
    start_date=datetime(2019, 12, 8),
    catchup=False,
    params={'execution_sla': None},
    tags=["data-platform", "blockchain", "bigquery-public-data", "crypto_ethereum"]
)

start = DummyOperator(task_id='start',
                      dag=dag)
end = DummyOperator(task_id='end',
                    dag=dag)

endDate = datetime.today() - timedelta(days=1)

SPARK_STEPS = [
    {
        'Name': 'Bigquery Blockchain Load',
        'ActionOnFailure': 'TERMINATE_CLUSTER',
        'HadoopJarStep': {
            'Jar': 's3://us-west-2.elasticmapreduce/libs/script-runner/script-runner.jar',
            'Args': ['s3://poly-data-utils/scripts/bigquery/blockchain_historical_backfill.sh'],
        },
    }
]

JOB_FLOW_OVERRIDES = {
    "Name": "eth-bigquery",
    "ReleaseLabel": "emr-6.6.0",
    "Applications": [{"Name": "Hadoop"}, {"Name": "Spark"}, {"Name": "Hive"}],
    # We want our EMR cluster to have HDFS and Spark
    "Configurations": [{"Classification": "hive-site", "Properties": {"javax.jdo.option.ConnectionURL": Hivehost,
                                                                      "javax.jdo.option.ConnectionDriverName": "org.mariadb.jdbc.Driver",
                                                                      "javax.jdo.option.ConnectionUserName": Hiveuid,
                                                                      "javax.jdo.option.ConnectionPassword": Hivepwd,
                                                                      "hive.recursive-directories": "true",
                                                                      "hive.exec.scratchdir": "s3://poly-de/_temp/",
                                                                      "hive.vectorized.execution.enabled": "true",
                                                                      "metastore.storage.schema.reader.impl": "org.apache.hadoop.hive.metastore.SerDeStorageSchemaReader",
                                                                      "hive.support.concurrency": "true",
                                                                      "hive.txn.manager": "org.apache.hadoop.hive.ql.lockmgr.DbTxnManager",
                                                                      "hive.enforce.bucketing": "true",
                                                                      "hive.exec.dynamic.partition.mode": "nostrict",
                                                                      "hive.compactor.initiator.on": "true",
                                                                      "hive.compactor.worker.threads": "3",
                                                                      "hive.server2.session.check.interval": "1h",
                                                                      "hive.server2.idle.operation.timeout": "2h",
                                                                      "hive.server2.idle.session.check.operation": "true",
                                                                      "hive.server2.idle.session.timeout": "2h"}},
                       {"Classification": "spark", "Properties": {"maximizeResourceAllocation": "true"}},
                       {"Classification": "spark-defaults",
                        "Properties": {"spark.network.timeout": "1500", "spark.local.dir": "/mnt/tmp"}},
                       {"Classification": "hdfs-site", "Properties": {"dfs.replication": "2"}},
                       {"Classification": "livy-conf", "Properties": {"livy.server.session.timeout": "10h"}},
                       {"Classification": "emrfs-site",
                        "Properties": {"fs.s3.maxConnections": "100", "fs.s3.serverSideEncryptionAlgorithm": "AES256",
                                       "fs.s3.enableServerSideEncryption": "true"}},
                       {"Classification": "spark-env", "Properties": {}, "Configurations": [
                           {"Classification": "export", "Properties": {"SPARK_LOCAL_DIRS": "/mnt/tmp"}}]},
                       ],
    "Instances": {
        "InstanceGroups": [
            {
                "Name": "Master node",
                "Market": "ON_DEMAND",
                "InstanceRole": "MASTER",
                "InstanceType": "r6g.xlarge",
                "InstanceCount": 1,
            },
            {
                "Name": "Core - 2",
                "Market": "ON_DEMAND",  # Spot instances are a "use as available" instances
                "InstanceRole": "CORE",
                "InstanceType": "r6g.xlarge",
                "InstanceCount": 2,
            },
        ],
        "Ec2KeyName": "dataengineering-prod",
        "KeepJobFlowAliveWhenNoSteps": True,
        "TerminationProtected": False,
        "Ec2SubnetId": "subnet-0166aabd661f804e4",
        "AdditionalMasterSecurityGroups": ["sg-0ab9f7dc883b4453a", "sg-05ab22a50c7c11aa7"],
        "AdditionalSlaveSecurityGroups": ["sg-0ab9f7dc883b4453a", "sg-05ab22a50c7c11aa7"],
        'EmrManagedMasterSecurityGroup': 'sg-0f0513475394227b7',
        'EmrManagedSlaveSecurityGroup': 'sg-0af43755f3edf29b9',  # this lets us programmatically terminate the cluster
    },
    "JobFlowRole": "EMR_EC2_DefaultRole",
    "ServiceRole": "EMR_DefaultRole_V2",
    "LogUri": "s3://poly-data-utils/emr/",
    'BootstrapActions': [
        {
            'Name': 'Install BigQuery',
            'ScriptBootstrapAction': {
                'Path': 's3://poly-data-utils/scripts/shell/bigquery_jar.sh',
            }
        },
        {
            'Name': 'Set Spark Temp Dir',
            'ScriptBootstrapAction': {
                'Path': 's3://poly-data-utils/scripts/shell/set_spark_temp.sh',
            }
        },
    ],
    'Tags': [
        {
            'Key': 'Service',
            'Value': 'EMR'
        },
        {
            'Key': 'Type',
            'Value': 'Spark'
        },
        {
            'Key': 'Description',
            'Value': 'Bigquery Public Data Lake Nightly Load'
        },
        {
            'Key': 'Team',
            'Value': 'Data'
        },
    ],

}

# Create an EMR cluster
create_emr_cluster = EmrCreateJobFlowOperator(
    task_id="create_emr_cluster",
    job_flow_overrides=JOB_FLOW_OVERRIDES,
    aws_conn_id="aws_default",
    dag=dag,
)

# Add your steps to the EMR cluster
step_adder = EmrAddStepsOperator(
    task_id="add_steps",
    job_flow_id="{{ task_instance.xcom_pull(task_ids='create_emr_cluster', key='return_value') }}",
    aws_conn_id="aws_default",
    steps=SPARK_STEPS,
    dag=dag,
)

last_step = len(SPARK_STEPS) - 1

step_checker = EmrStepSensor(
    task_id="watch_step",
    job_flow_id="{{ task_instance.xcom_pull('create_emr_cluster', key='return_value') }}",
    step_id="{{ task_instance.xcom_pull(task_ids='add_steps', key='return_value')["
            + str(last_step)
            + "] }}",
    aws_conn_id="aws_default",
    dag=dag,
)

terminate_emr_cluster = EmrTerminateJobFlowOperator(
    task_id="terminate_emr_cluster",
    job_flow_id="{{ task_instance.xcom_pull(task_ids='create_emr_cluster', key='return_value') }}",
    aws_conn_id="aws_default",
    dag=dag,
)

start >> create_emr_cluster >> step_adder >> step_checker >> terminate_emr_cluster >> end
