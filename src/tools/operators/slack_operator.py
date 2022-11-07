from airflow.providers.slack.operators.slack import SlackAPIPostOperator as AirflowSlackAPIPostOperator


class SlackAPIPostOperator(AirflowSlackAPIPostOperator):
    def execute(self, context):
        """Extend slack message with link to task log."""
        ti = context["ti"]
        ti_slack = None

        # Try to get task instance for upstream task.
        upstream_task_ids = list(self.upstream_task_ids)
        if upstream_task_ids:
            # Take first upstream task.
            upstream_task_id = upstream_task_ids[0]

            dag_run = ti.get_dagrun()
            # `get_task_instance` will return None, if no match.
            ti_slack = dag_run.get_task_instance(upstream_task_id)
        # Fallback to current task instance if no upstream found.
        ti_slack = ti_slack or ti

        self.text = "{text} (<{log_url}|{dag_id}.{task_id}>)".format(
            text=self.text,
            log_url=ti_slack.log_url,
            dag_id=ti_slack.dag_id,
            task_id=ti_slack.task_id,
        )

        return super().execute(context=context)
