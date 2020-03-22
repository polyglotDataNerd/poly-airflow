/*intializes variables from the networking module to take variibles from the stage enviorment i.e. production, production
this of this like an init in python OR constructor in an OOP language
*/
module "networking" {
  source = "../modules/networking"
  environment = var.environment
  vpc_cidr = var.vpc_cidr

  public_subnets = var.public_subnets
  private_subnets  = var.private_subnets

  region = var.region
  availability_zone = var.availability_zone
  security_groups_id = "${var.environment}-sg"
//  ssl_cert_query = var.ssl_cert_query
}