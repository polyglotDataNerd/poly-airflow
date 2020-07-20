data "aws_vpc" vpc {
  tags = {
    Name = "vpc-${var.environment}"
  }
}

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

# Database
resource "aws_db_subnet_group" "rds-subnet-group" {
  name = "rds-subnet-group-${var.environment}"
  subnet_ids = flatten([data.aws_subnet_ids.private_subnets.ids])
  tags = {
    Name = "rds-group-${var.environment}"
    Subnets = "private"
    Environment = var.environment
    Tier = "Airflow"
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
  master_password = var.airflowpw
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.rds-param-group.name
  db_subnet_group_name = aws_db_subnet_group.rds-subnet-group.name
  vpc_security_group_ids = flatten([data.aws_security_group.db_sg.id, data.aws_security_group.default_sg.id])
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
//  count = "1"
//  db_instance_identifier = aws_rds_cluster_instance.db_airflow_instance[count.index].id
//    feature_name = "s3Import"
//  role_arn = "arn:aws:iam::712639424220:role/RDS"
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
    Name = "airflow-${var.environment}-${count.index}"
    VPC = data.aws_vpc.vpc.id
    ManagedBy = "terraform"
    Environment = var.environment
    Tier = "airflow DB"
  }

  lifecycle {
    create_before_destroy = false
  }

}
