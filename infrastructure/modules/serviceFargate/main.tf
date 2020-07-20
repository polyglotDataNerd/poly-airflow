/*====
VPC
======*/
data "aws_vpc" vpc {
  tags = {
    Name = "vpc-${var.environment}"
  }
}

/*====
Subnets
======*/

data aws_subnet_ids "private_subnets" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name = "tag:Name"
    values = ["us-west-2a-private-subnet-${var.environment}", "us-west-2b-private-subnet-${var.environment}", "us-west-2c-private-subnet-${var.environment}", "us-west-2d-private-subnet-${var.environment}"]
  }
  tags = {
    Environment = var.environment
    Tier = "Private"
  }
}

data aws_subnet_ids "public_subnets" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name = "tag:Name"
    values = ["us-west-2a-public-subnet-${var.environment}", "us-west-2b-public-subnet-${var.environment}", "us-west-2c-public-subnet-${var.environment}", "us-west-2d-public-subnet-${var.environment}"]
  }
  tags = {
    Environment = var.environment
    Tier = "Public"
  }
}


/*====
Security group
====*/

data aws_security_group "default_sg" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    Name = "bd-security-group-${var.environment}"
    Tier = "Default"
  }
}

data aws_security_group "db_sg" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    Name = "bd-security-group-dbs-${var.environment}"
    Tier = "Databases"
  }
}

resource "aws_security_group" "airflow_security_group" {
  name = "airflow-front-security-group-${var.environment}"
  description = "airflow alb access rules"
  vpc_id = data.aws_vpc.vpc.id

  # HTTP access from anywhere
  ingress {
    from_port = "80"
    to_port = "80"
    protocol = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  #airflow Port
  ingress {
    from_port = "8080"
    to_port = "8080"
    protocol = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"]
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

/*====
Service Discovery Private Service
service discovery for ECS server to talk to ECS client without ALB
https://aws.amazon.com/blogs/aws/amazon-ecs-service-discovery/
====*/
//resource "aws_service_discovery_private_dns_namespace" "airflow_prvs_dns" {
//  name = "airflow-${var.environment}"
//  description = "private dns namespace for airflow discovery service: ${var.environment}"
//  vpc = data.aws_vpc.vpc.id
//}
//
//
//resource "aws_service_discovery_service" "airflow_prvs_service" {
//  name = "airflow"
//
//  dns_config {
//    /*
//    already defined in the server, need to get Route 53 DNS to map to discoery service:
//
//    aws_service_discovery_private_dns_namespace.airflow_prvs_dns: CANNOT_CREATE_HOSTED_ZONE: The VPC that you chose, vpc-0f6ca4e0694881aee
//    in region us-west-2, is already associated with another private hosted zone that has an overlapping name space, sg.airflow
//    */
//    namespace_id = aws_service_discovery_private_dns_namespace.airflow_prvs_dns.id
//    dns_records {
//      ttl = 100
//      type = "A"
//    }
//
//    routing_policy = "MULTIVALUE"
//  }
//
//  health_check_custom_config {
//    failure_threshold = 1
//  }
//}
/*====
Service Discovery Private Service
====*/

/*====
Load Balancer Public Service
====*/
resource "aws_lb" "airrflowlb" {
  name = "alb-airflow-${var.environment}"
  internal = false
  load_balancer_type = "application"
  security_groups = flatten([
    data.aws_security_group.default_sg.id,
    data.aws_security_group.db_sg.id,
    aws_security_group.airflow_security_group.id])
  subnets = flatten(data.aws_subnet_ids.public_subnets.ids)
  # enable_cross_zone_load_balancing = true -> network only
  enable_deletion_protection = false

  tags = {
    Name = "alb-airflow-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_alb_target_group" "airflow_tgtgrp_host" {
  name = "airflow-grp-${var.environment}"
  target_type = "ip"
  port = 8080
  protocol = "HTTP"
  vpc_id = data.aws_vpc.vpc.id
  health_check {
    path = "/"
    port = "traffic-port"
    protocol = "HTTP"
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 30
    timeout = 10
    matcher = "302"
  }
  depends_on = [
    aws_lb.airrflowlb]
}

resource "aws_alb_listener" "alb_listener_host" {
  load_balancer_arn = aws_lb.airrflowlb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.airflow_tgtgrp_host.arn
    type = "forward"
  }
}

resource "aws_route53_zone" "r53_private_zone" {
  /*
  Need to have a registered domain for the Alias to work in route 53:
  https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/using-domain-names-with-elb.html
  */
  name = "data.airflow.com"
  tags = {
    Environment = var.environment
  }
}

//resource "aws_route53_record" "af" {
//  zone_id = aws_route53_zone.r53_private_zone.id
//  name = "airflow"
//  type = "A"
//
//  alias {
//    name = aws_lb.airrflowlb.dns_name
//    zone_id = aws_lb.airrflowlb.zone_id
//    evaluate_target_health = true
//  }
//}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.r53_private_zone.id
  name = "www"
  type = "A"

  alias {
    name = aws_lb.airrflowlb.dns_name
    zone_id = aws_lb.airrflowlb.zone_id
    evaluate_target_health = true
  }
}
/*====
Load Balancer
====*/


# Service
resource "aws_ecs_task_definition" "airflow" {
  family = "airflow-${var.environment}"
  requires_compatibilities = [
    "FARGATE"]
  network_mode = "awsvpc"
  cpu = "1024"
  memory = "2048"
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
              "cpu": 1024,
              "memory": 2048,
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

  /*service_registries {
    registry_arn = aws_service_discovery_service.airflow_prvs_service.arn
    container_name = "airflow-service-${var.environment}"
  }*/

  load_balancer {
    container_name = "airflow-definition-${var.environment}"
    container_port = 8080
    target_group_arn = aws_alb_target_group.airflow_tgtgrp_host.arn
  }

  depends_on = [
    aws_alb_listener.alb_listener_host]

  network_configuration {
    security_groups = flatten([
      data.aws_security_group.default_sg.id,
      data.aws_security_group.db_sg.id,
      aws_security_group.airflow_security_group.id])
    subnets = flatten(data.aws_subnet_ids.private_subnets.ids)
    assign_public_ip = true
  }
}