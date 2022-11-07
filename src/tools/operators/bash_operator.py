from airflow.operators.bash_operator import BashOperator as AirflowBashOperator


class BashOperator(AirflowBashOperator):
    def __init__(self, *args, project=None, script=None, executable=None, bash_command=None, **kwargs):
        if executable is None:
            script_file = script.split(" ")[0]
            if script_file.endswith(".py"):
                executable = "python3"
            elif script_file.endswith(".ipy"):
                executable = "ipython --colors=NoColor"
            else:
                raise ValueError("Unknown {0} script file to run".format(script_file))

        extended_bash_command = '''
            export PYTHONUNBUFFERED=TRUE
            export TERM=xterm
            set -ex
            cd $AIRFLOW_HOME/projects/{project}/ &&
            if [ -f "requirements.txt" ]; then
                python3 -m pip install -r requirements.txt
            fi &&
            pip freeze &&
            mkdir data &&
            {executable} {script}
        '''.format(
            project=project,
            executable=executable,
            script=script,
        )
        if bash_command is not None:
            extended_bash_command = '''
                {extended_bash_command} &&
                {bash_command}
            '''.format(
                extended_bash_command=extended_bash_command,
                bash_command=bash_command,
            )

        super().__init__(*args, bash_command=extended_bash_command, **kwargs)
