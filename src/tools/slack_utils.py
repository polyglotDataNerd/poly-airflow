import datetime
import os

from slack import WebClient
from airflow.models import Variable


def _get_slack_airflow_app_token():
    try:
        token = Variable.get("AIRFLOW_SLACK_APP_TOKEN")
        return token
    except KeyError:
        raise AssertionError("Environment variable AIRFLOW_SLACK_APP_TOKEN does not exist")


def slack_defaults(context, task_type):
    """
    Function to handle switching between a task failure and success.
    """
    dag_context = context["dag"]
    dag_name = dag_context.dag_id
    task_name = context["task"].task_id
    task_id = context["task_instance"].task_id
    execution_date_value = context["logical_date"]
    execution_date_epoch = datetime.datetime.now().strftime("%s")
    execution_date_pretty = execution_date_value.strftime(
        "%a, %b %d, %Y at %-I:%M %p UTC"
    )
    # log_link = "context.get('task_instance').log_url"
    log_link = "http://airflow.poly-de-prod.com/home"
    log_link_markdown = f"<{log_link}|View Logs>"
    dag_owners = [f"<@{x.strip()}>" for x in dag_context.default_args.get('owner', 'data-engineers').split(",")]
    slack_names = ",".join(dag_owners)
    slack_channel = dag_context.params.get(
        "slack_channel_override", "#airflow"
    )
    color_green = "#1aaa55"
    color_red = "#a62d19"
    if task_type == "success":
        color = color_green
        task_id = "slack_succeeded"
        task_text = "Task succeeded! :party_dino:"

    if task_type == "failure":
        color = color_red
        task_id = "slack_failed"
        task_text = "Task failure! :epicfail:"

    attachment = [
        {
            "mrkdwn_in": ["title", "value"],
            "color": color,
            "fields": [
                {"title": "DAG", "value": dag_name, "short": True},
                {"title": "Owner", "value": slack_names, "short": True},
                {"title": "Task", "value": task_name, "short": True},
                {"title": "Timestamp", "value": execution_date_pretty, "short": True},
                {"title": "Logs", "value": log_link_markdown, "short": True}
            ],
            "footer": "Airflow",
            "ts": execution_date_epoch,
        }
    ]
    return attachment, task_id, slack_channel, task_text


def slack_failed_task(context):
    slack_token = _get_slack_airflow_app_token()
    attachment, task_id, slack_channel, task_text = slack_defaults(context, "failure")
    slack_client = WebClient(slack_token)
    return slack_client.chat_postMessage(attachments=attachment, text=task_text, channel=slack_channel)


def slack_succeeded_task(context):
    slack_token = _get_slack_airflow_app_token()
    attachment, task_id, slack_channel, task_text, = slack_defaults(context, "success")
    slack_client = WebClient(slack_token)
    return slack_client.chat_postMessage(attachments=attachment, text=task_text, channel=slack_channel)
