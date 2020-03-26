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
  master_password = var.airflowpw
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.rds-param-group.name
  db_subnet_group_name = aws_db_subnet_group.rds-subnet-group.name
  vpc_security_group_ids = flatten([
    split(",", var.sg_security_groups[var.environment])])
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
    Name = "sg-bigdata-ovenschedule-${var.environment}-${count.index}"
    VPC = data.aws_vpc.vpc.id
    ManagedBy = "terraform"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = false
  }

}
