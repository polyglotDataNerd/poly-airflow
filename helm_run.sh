Airflowhost=$(aws ssm get-parameters --names /mysql/airflow/db/de/host --query Parameters[0].Value --with-decryption --output text)
Airflowuid=$(aws ssm get-parameters --names /mysql/airflow/db/de/uid --query Parameters[0].Value --with-decryption --output text)
Airflowpwd=$(aws ssm get-parameters --names /mysql/airflow/db/de/pwd --query Parameters[0].Value --with-decryption --output text)

helm upgrade --debug --install \
--wait --timeout 3m \
--atomic \
-f ./helm/env/stage.yaml \
--set image.repository=${{ steps.login-ecr.outputs.registry }}/poly/airflow \
--set image.tag=${{ github.sha }} \
--set db_password=${Airflowpwd} \
--namespace=airflow \
airflow ./helm/airflow-helm