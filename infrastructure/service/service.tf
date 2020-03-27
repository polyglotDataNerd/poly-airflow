/*intializes variables from the airflow module to take variibles from the stage enviorment i.e. production, production
this of this like an init in python OR constructor in an OOP language
*/
module "airflow" {
  source = "../modules/serviceEc2"
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