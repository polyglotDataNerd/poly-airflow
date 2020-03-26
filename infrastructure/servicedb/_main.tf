/*
  This is the main entry point to the terraform build. Terraform looks at .tf files in alphabetical order so the underscore (_) is key
  for it to initialize first.
*/
provider "aws" {
  access_key = var.awsaccess
  secret_key = var.awssecret
  region = "us-west-2"
}
