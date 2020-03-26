/*====
ECS task definitions, this resource is only useful when building a service. It looks for a cluster or service (container)
to resgister task to.
======*/
data "aws_vpc" vpc {
  tags = {
    Name = "vpc-${var.environment}"
  }
}

# Database
resource "aws_db_subnet_group" "rds-subnet-group" {
  name = "rds-subnet-group-${var.environment}"
  subnet_ids = flatten([
    split(",", var.private_subnets[var.environment])])
  tags = {
    Name = "rds-group-${var.environment}"
    Subnets = "private"
    Environment = var.environment
  }
}

resource "aws_rds_cluster_parameter_group" "rds-param-group" {
  name = "rds-param-group-${var.environment}"
  family = "aurora-postgresql10"
  description = "RDS production param group cluster parameter group"
  //  parameter {
  //    name = "lower_case_table_names"
  //    value = "1"
  //    apply_method = "pending-reboot"
  //  }
  tags = {
    Name = "rds-param-group-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_rds_cluster" "airflow_cluster" {
  cluster_identifier = "airflow-cluster-${var.environment}"
  engine = "aurora-postgresql"
  engine_version = "10.7"
  availability_zones = var.availability_zone
  database_name = "airflow"
  master_username = "airflow"
  master_password = "Airflow789*!*"
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.rds-param-group.name
  db_subnet_group_name = aws_db_subnet_group.rds-subnet-group.name
  vpc_security_group_ids = flatten([
    split(",", var.sg_security_groups[var.environment])])
  //  iam_roles = [
  //    "arn:aws:iam::712639424220:role/RDS"]
  //  lifecycle {ignore_changes = [iam_roles]}
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot = true
  storage_encrypted = true
  tags = {
    Name = "airflow-cluster"
    Environment = var.environment
  }
}

//resource "aws_db_instance_role_association" "example" {
//  db_instance_identifier = aws_rds_cluster_instance.db_airflow_instance.id
//  feature_name           = "s3Import"
//  role_arn               = "arn:aws:iam::712639424220:role/RDS"
//}

resource "aws_rds_cluster_instance" "db_airflow_instance" {
  count = "1"
  identifier = "airflow-inst-${var.environment}-${count.index}"
  engine = "aurora-postgresql"
  engine_version = "10.7"
  cluster_identifier = aws_rds_cluster.airflow_cluster.id
  instance_class = "db.t3.medium"
  db_subnet_group_name = aws_db_subnet_group.rds-subnet-group.name
  publicly_accessible = false

  tags = {
    Name = "sg-bigdata-ovenschedule-${var.environment}-${count.index}"
    VPC = data.aws_vpc.vpc.id
    ManagedBy = "terraform"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = false
  }

}

//# Service
//resource "aws_ecs_task_definition" "airflow" {
//  family = "airflow-${var.environment}"
//  requires_compatibilities = [
//    "FARGATE"]
//  network_mode = "awsvpc"
//  cpu = "4 vCPU"
//  memory = "20 GB"
//  execution_role_arn = var.ecs_IAMROLE
//  task_role_arn = var.ecs_IAMROLE
//  container_definitions = <<EOF
//        [
//            {
//              "name": "airflow-definition",
//              "image": "${var.image}",
//              "essential": true,
//              "logConfiguration": {
//                "logDriver": "awslogs",
//                "options": {
//                  "awslogs-group": "airflow-${var.environment}",
//                  "awslogs-region": "us-west-2",
//                  "awslogs-stream-prefix": "airflow"
//                }
//              }
//            }
//      ]
//  EOF
//}
//
//data "aws_ecs_task_definition" "airflowservice" {
//  task_definition = aws_ecs_task_definition.airflow.family
//}
//
//resource "aws_ecs_service" "airflowservice" {
//  name = "airflow-service-${var.environment}"
//  task_definition = "${aws_ecs_task_definition.airflow.family}:${max("${aws_ecs_task_definition.airflow.revision}", "${data.aws_ecs_task_definition.airflowservice.revision}")}"
//  desired_count = 4
//  launch_type = "FARGATE"
//  cluster = var.ecs_cluster
//
//  network_configuration {
//    security_groups = [
//      var.sg_security_groups[var.environment]]
//    subnets = [
//      var.private_subnets[var.environment]]
//  }
//
//}