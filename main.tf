###############################################################################
# variables
###############################################################################
variable "env" {}
variable "instance_type" {}
variable "bastion_key_name" {}
variable "bastion_key_path" {}
variable "vpc_id" {}
variable "vpc_cidr" {}
variable "subnet_ids" {}
variable "shell_username" {}
variable "region" {}
variable "state_bucket" {}
variable "ip_allow1" {}
variable "ip_allow2" {}
variable "ip_allow3" {}
variable "ip_allow4" {}
variable "ip_allow5" {}

###############################################################################
# RESOURCES
###############################################################################




###############################################################################
# Outputs
###############################################################################
output "public_ip" {
  value = "${aws_eip.bastion.public_ip}"
}

output "private_ip" {
  value = "${aws_instance.bastion.private_ip}"
}

output "ami_image_id" {
  value = "${data.aws_ami.bastion.image_id}"
}

output "ami_creation_date" {
  value = "${data.aws_ami.bastion.creation_date}"
}

output "ami_name" {
  value = "${data.aws_ami.bastion.name}"
}

#
