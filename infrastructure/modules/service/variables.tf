variable "awsaccess" {
  type = string
}
variable "awssecret" {
  type = string
}
variable "environment" {
  type = string
}

variable "image" {
  type = string
  description = "ecs repo image name"
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
}

variable "availability_zone" {
  type = "list"
  description = "The azs to use"
}


variable "private_subnets" {
  type = "map"
  description = "The private subnets to use"
}

variable "public_subnets" {
  type = "map"
  description = "The private subnets to use"
}

variable "ecs_IAMROLE" {
  description = "The IAM role for the container"
  type = string
}


variable "repository_name" {
  description = "repository name for container images"
  type = string
}

variable "ecs_cluster" {
  description = "repository name for container images"
  type = string
}

variable "ecr_account_path" {
  description = "ecr path for data aws account"
  type = string
}

variable "region" {
  description = "Region that the instances will be created"
}

variable "sg_security_groups" {
  type = "map"
  description = "sg security groups"
}

