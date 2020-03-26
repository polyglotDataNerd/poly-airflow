#intializes variables from the ecs module to take variibles from the stage enviorment i.e. production, production
module "infra" {
  source = "../modules/infra"
  awsaccess = var.awsaccess
  awssecret = var.awssecret
  environment = var.environment
  vpc_cidr = var.vpc_cidr
  public_subnets = var.public_subnets
  private_subnets  = var.private_subnets
  region = var.region
  availability_zone = var.availability_zone
  sg_security_groups = var.sg_security_groups
  ecr_account_path = var.ecr_account_path
  ecs_IAMROLE = var.ecs_IAMROLE
  ecs_cluster = var.ecs_cluster
  image = var.image
  repository_name = var.repository_name
  airflowpw = var.airflowpw
}