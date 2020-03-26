/*====
This terraform build can only run once if environments persist. This builds the service that the consumer task will run in
We can use the apply command to rebuild and the destroy command to delete all the environments in terraform
======*/

/*====
Cloudwatch Log Group
======*/
resource "aws_cloudwatch_log_group" "airflow_log_group" {
  name = "airflow-${var.environment}"
  tags = {
    Environment = var.environment
    Application = "airflow"
  }
}

/*====
ECR repository to store our Docker images
======*/
resource "aws_ecr_repository" "airflow" {
  name = "${var.repository_name}-${var.environment}"
}
