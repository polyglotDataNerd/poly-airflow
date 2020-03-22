/*
Within the terraform CLI there is the command output.

terraform output environment

This command will output whatever is in the .tfstate file. It's basically a pointer to the metadata of what was created in the build.

*/

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "security_groups_ids" {
  value = ["${aws_security_group.bd-security-group.id}"]
}

output "bastion_public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}