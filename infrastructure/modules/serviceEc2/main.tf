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

  # HTTP access from anywhere
  ingress {
    from_port = "80"
    to_port = "80"
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port = "443"
    to_port = "443"
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  #HUE
  ingress {
    from_port = "8888"
    to_port = "8888"
    protocol = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  #ZEPPELIN
  ingress {
    from_port = "8890"
    to_port = "8890"
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
Load Balancer
====*/
resource "aws_lb" "airrflowlb" {
  name = "alb-airflow-${var.environment}"
  internal = true
  load_balancer_type = "application"
  security_groups = flatten([
    split(",", var.sg_security_groups[var.environment]),
    aws_security_group.airflow_security_group.id])
  subnets = flatten([
    split(",", var.private_subnets[var.environment])])
  # enable_cross_zone_load_balancing = true -> network only
  enable_deletion_protection = false

  tags = {
    Name = "alb-airflow-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_alb_target_group" "airflow_alb_grp" {
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
    "aws_lb.airrflowlb"]
}

resource "aws_alb_listener" "alb_airflow_listener" {
  load_balancer_arn = aws_lb.airrflowlb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.airflow_alb_grp.arn
    type = "forward"
  }
}

resource "aws_route53_zone" "r53_private_zone" {
  name = "airflow.${var.environment}"
  tags = {
    Environment = var.environment
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.r53_private_zone.id
  name = "service"
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

/*====
Auto Scaling
====*/

resource "aws_iam_instance_profile" "ecs-instance-profile" {
  name = "ecs-instance-profile"
  path = "/"
  role = "admin"
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "aws_launch_configuration" "launch_config" {
  name = "airflow-launch-${var.environment}"
  image_id = "ami-088dbc54f17f8a1a2"
  # $0.34 per hour -> c5.2xlarge
  instance_type = "c5.2xlarge"
  iam_instance_profile = aws_iam_instance_profile.ecs-instance-profile.id

  root_block_device {
    volume_type = "standard"
    volume_size = 100
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

  security_groups = flatten([
    split(",", var.sg_security_groups[var.environment]),
    aws_security_group.airflow_security_group.id])
  associate_public_ip_address = false
  key_name = "bastion-${var.environment}"
  user_data = <<EOF
                #!/bin/bash

                sudo yum update -y
                sudo yum install -y ecs-init
                sudo service docker start
                sudo start ecs

                echo ECS_CLUSTER=${var.ecs_cluster} >> /etc/ecs/ecs.config
              EOF
}

resource "aws_autoscaling_group" "ecs-autoscaling-group" {
  name = "ecs-autoscaling-group"
  max_size = 2
  min_size = 1
  desired_capacity = 1
  vpc_zone_identifier = flatten([
    split(",", var.private_subnets[var.environment])])
  launch_configuration = aws_launch_configuration.launch_config.name
  health_check_type = "ELB"
}


# Service
resource "aws_ecs_task_definition" "airflow" {
  family = "airflow-${var.environment}"
  requires_compatibilities = [
    "EC2"]
  network_mode = "awsvpc"
  cpu = "8 vCPU"
  memory = "14 GB"
  execution_role_arn = var.ecs_IAMROLE
  task_role_arn = var.ecs_IAMROLE
  container_definitions = <<EOF
        [
            {
              "name": "airflow-service-${var.environment}",
              "image": "${var.image}",
              "essential": true,
              "portMappings": [
                {
                    "containerPort": 8080,
                    "hostPort": 8080,
                    "protocol": "tcp"
                }
              ],
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

data "aws_ecs_task_definition" "airflow" {
  task_definition = aws_ecs_task_definition.airflow.family
  depends_on = [
    "aws_ecs_task_definition.airflow"]
}


resource "aws_ecs_service" "airflowservice" {
  name = "airflow-${var.environment}"
  task_definition = "${aws_ecs_task_definition.airflow.family}:${max("${aws_ecs_task_definition.airflow.revision}", "${data.aws_ecs_task_definition.airflow.revision}")}"
  desired_count = 1
  launch_type = "EC2"
  cluster = var.ecs_cluster

  load_balancer {
    container_name = "airflow-service-${var.environment}"
    container_port = "8080"
    target_group_arn = aws_alb_target_group.airflow_alb_grp.arn
  }

  depends_on = [
    aws_alb_listener.alb_airflow_listener]

  network_configuration {
    security_groups = flatten([
      split(",", var.sg_security_groups[var.environment]),
      aws_security_group.airflow_security_group.id])
    subnets = flatten([
      split(",", var.private_subnets[var.environment])])
  }
}