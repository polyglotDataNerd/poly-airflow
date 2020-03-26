variable "awsaccess" {
  type = string
}
variable "awssecret" {
  type = string
}
variable "environment" {
  description = "env will be passed as an arguement in the build"
}
variable "image" {
  type = string
  description = "ecs repo image name"
}

variable "airflowpw" {
  type = "string"
  description = "airflow database pw"
}

variable "region" {
  description = "Region that the instances will be created"
  default = "us-west-2"
}

variable "availability_zone" {
  type = "list"
  description = "The AZ that the resources will be launched"
  default = [
    "us-west-2a",
    "us-west-2b",
    "us-west-2c"]
}

# airflow

variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
  default = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "data private subnets"
  type = "map"
  default = {
    development = "subnet-060f8827abd9bd383,subnet-058680ba725ebb2f7,subnet-0286cc0d2662611fb"
    production = "subnet-05495ba617a541515,subnet-0a87c15bfc4e4517c,subnet-0958f31b1b8ec88fa"
  }
}

variable "public_subnets" {
  description = "The private subnets to use"

  type = "map"
  default = {
    development = "subnet-08e3238a8cee527b9,subnet-0874ad3ae83d93ec1,subnet-05d804a98a94486c5"
    production = "subnet-01116e90917c89682,subnet-0e366fd4cac7ca471,subnet-0c7e6328e3e3b59ce"
  }
}

variable "sg_security_groups" {
  description = "security groups"
  type = "map"
  default = {
    development = "sg-0f19043c517477b48,sg-02edcf11599c5c96b,sg-00656a2aecbd02caf"
    production = "sg-04bd133673c9e6436,sg-0b16ce13b03cf9fc6"
  }
}

variable "ecs_IAMROLE" {
  description = "The IAM role for the container"
  type = string
  default = "arn:aws:iam::712639424220:role/admin"
}

variable "repository_name" {
  description = "repository name for container images"
  type = string
  default = "airflow"
}

variable "ecr_account_path" {
  description = "ecr path for data aws account"
  type = string
  default = "712639424220.dkr.ecr.us-west-2.amazonaws.com"
}

variable "ecs_cluster" {
  description = "ecs clutser"
  type = string
  default = "services-cluster"
}
