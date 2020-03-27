/*====
ECS task definitions, this resource is only useful when building a service. It looks for a cluster or service (container)
to resgister task to.
======*/

data "aws_vpc" vpc {
  tags = {
    Name = "vpc-${var.environment}"
  }
}

/*====
Security group
====*/
resource "aws_security_group" "airflow_security_group" {
  name = "airflow-front-security-group-${var.environment}"
  description = "airflow alb access rules"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }

  #airflow Port
  ingress {
    from_port = "8080"
    to_port = "8080"
    protocol = "TCP"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Name = "airflow-security-group-${var.environment}"
    Description = "airflow WEB UI"
  }
}

/*
service discovery for ECS server to talk to ECS client without ALB
https://aws.amazon.com/blogs/aws/amazon-ecs-service-discovery/
*/
resource "aws_service_discovery_private_dns_namespace" "airflow_prvs_dns" {
  name = "airflow-${var.environment}"
  description = "private dns namespace for airflow discovery service: ${var.environment}"
  vpc = data.aws_vpc.vpc.id
}

/*====
Service Discovery
====*/
resource "aws_service_discovery_service" "airflow_prvs_service" {
  name = "airflow"

  dns_config {
    /*
    already defined in the server, need to get Route 53 DNS to map to discoery service:

    aws_service_discovery_private_dns_namespace.airflow_prvs_dns: CANNOT_CREATE_HOSTED_ZONE: The VPC that you chose, vpc-0f6ca4e0694881aee
    in region us-west-2, is already associated with another private hosted zone that has an overlapping name space, sg.airflow
    */
    namespace_id = aws_service_discovery_private_dns_namespace.airflow_prvs_dns.id
    dns_records {
      ttl = 100
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# Service
resource "aws_ecs_task_definition" "airflow" {
  family = "airflow-${var.environment}"
  requires_compatibilities = [
    "FARGATE"]
  network_mode = "awsvpc"
  cpu = "4 vCPU"
  memory = "20 GB"
  execution_role_arn = var.ecs_IAMROLE
  task_role_arn = var.ecs_IAMROLE
  container_definitions = <<EOF
        [
            {
              "name": "airflow-definition-${var.environment}",
              "image": "${var.image}",
              "essential": true,
              "portMappings": [
                {
                    "containerPort": 8080,
                    "hostPort": 8080,
                    "protocol": "tcp"
                }
              ],
              "cpu": 4024,
              "memory": 20000,
              "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                  "awslogs-group": "airflow-${var.environment}",
                  "awslogs-region": "us-west-2",
                  "awslogs-stream-prefix": "airflow"
                }
              }
            }
      ]
  EOF
}

data "aws_ecs_task_definition" "airflowservice" {
  task_definition = aws_ecs_task_definition.airflow.family
  depends_on = [
    "aws_ecs_task_definition.airflow"]
}


resource "aws_ecs_service" "airflowservice" {
  name = "airflow-service-${var.environment}"
  task_definition = "${aws_ecs_task_definition.airflow.family}:${max("${aws_ecs_task_definition.airflow.revision}", "${data.aws_ecs_task_definition.airflowservice.revision}")}"
  desired_count = 1
  launch_type = "FARGATE"
  cluster = var.ecs_cluster

  service_registries {
    registry_arn = aws_service_discovery_service.airflow_prvs_service.arn
    container_name = "airflow-service-${var.environment}"
  }

  network_configuration {
    security_groups = flatten([
      split(",", var.sg_security_groups[var.environment]),
      aws_security_group.airflow_security_group.id])
    subnets = flatten([
      split(",", var.private_subnets[var.environment])])
  }
}