/*these are the env variables that will be mapped to the modular variables when instantiated in the env build*/
variable "awsaccess" {}
variable "awssecret" {}
variable "environment" {
  description = "env will be passed as an arguement in the build"
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

# Networking
variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  #private will have an IP starting with (7,8,9)
  type = "map"
  description = "The CIDR block of the private subnet"
  default = {
    production = "10.0.10.0/24,10.0.11.0/24,10.0.12.0/24"
    development = "10.0.4.0/24,10.0.5.0/24,10.0.6.0/24"
  }
}

variable "private_subnets" {
  type = "map"
  description = "The CIDR block of the private subnet"
  default = {
    production = "10.0.13.0/24,10.0.14.0/24,10.0.15.0/24"
    development = "10.0.7.0/24,10.0.8.0/24,10.0.9.0/24"
  }
}


//variable "ssl_cert_query" {
//  type = "string"
//  description = "cert for query.sweetgreen.com"
//  default = "arn:aws:acm:us-west-2:447388672287:certificate/d6391050-8151-452d-af56-854943b5d6b0"
//}

variable "eips" {
  description = "sg data private subnets"
  type = "map"
  default = {
    development = "eipalloc-06876862e7a9b9692"
    production = "eipalloc-06876862e7a9b9697"
  }
}
