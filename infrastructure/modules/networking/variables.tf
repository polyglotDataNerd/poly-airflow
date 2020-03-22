/*these are the modular variables that will be mapped to the env variables*/

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default = "10.0.0.0/16"
}
variable "public_subnets" {
  description = "CIDR for the public subnet"
  #public will have an IP starting with 1
  type = "map"
}

variable "private_subnets" {
  description = "CIDR for the private subnet"
  #private will have an IP starting with 2
  type = "map"
}

variable "environment" {
  description = "The environment"
}

variable "region" {
  description = "The region to launch the bastion host"
}

variable "availability_zone" {
  type        = "list"
  description = "The az that the resources will be launched"
}

variable "security_groups_id" {
  description = "SG to use"
  type = "string"
}

//variable "ssl_cert_query" {
//  type = "string"
//  description = "cert for query.sweetgreen.com"
//}