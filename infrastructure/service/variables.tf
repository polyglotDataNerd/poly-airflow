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
    development = "subnet-0f4ebcd81c931204d,subnet-0eb5dfcfba3a4fb68,subnet-0d3e3b264a9477ea8"
    production = "subnet-05495ba617a541515,subnet-0a87c15bfc4e4517c,subnet-0958f31b1b8ec88fa"
  }
}

variable "public_subnets" {
  description = "The private subnets to use"

  type = "map"
  default = {
    development = "subnet-0313038e00df4d119,subnet-071fa357209f1a663,subnet-0ba98e91b2811c53d"
    production = "subnet-01116e90917c89682,subnet-0e366fd4cac7ca471,subnet-0c7e6328e3e3b59ce"
  }
}

variable "sg_security_groups" {
  description = "security groups"
  type = "map"
  default = {
    development = "sg-0f9f4f1b897dcc0b3,sg-07ae3d637de3cf36b"
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
