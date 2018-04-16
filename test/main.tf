###############################################################################
# variables
###############################################################################
variable "region" {}
variable "env" {}
variable "account_id" {}
variable "key_path" {}
variable "key_name" {}
variable "ec2_bastion_instance_type" {}
variable "ec2_bastion_user" {}
variable "state_bucket" {}
variable "kms_key_id" {}
variable "ip_allow1" {}
variable "ip_allow2" {}
variable "ip_allow3" {}
variable "ip_allow4" {}
variable "ip_allow5" {}


###############################################################################
# RESOURCES
###############################################################################

provider "aws" {
  region                   = "${var.region}"
  shared_credentials_file  = "${var.cred-file}"
  allowed_account_ids      = ["${var.account_id}"]
  profile                  = "${var.env}"
}

terraform {
  backend "s3" {
    bucket = "aws-terraform-state-bucket"
    key = "vpc-with-bastionbox.tfstate"
    region = "us-west-1"
    profile = "dev"
    encrypt = true
    acl     = "private"
  }
}

resource "aws_key_pair" "key" {
  key_name   = "${var.environment}"
  public_key = "${file("~/.ssh/dev_key.pub")}"
}

# call bastion module
module "bastion" {
  source           = "modules/bastion"
  env              = "${var.env}"
  region           = "${var.region}"
  instance_type    = "${var.ec2_bastion_instance_type}"
  bastion_key_name = "${var.key_name}"
  bastion_key_path = "${var.key_path}"
  vpc_id           = "${data.terraform_remote_state.vpc.vpc_id}"
  vpc_cidr         = "${data.terraform_remote_state.vpc.vpc_cidr}"
  subnet_ids       = "${data.terraform_remote_state.vpc.public_subnet_ids}"
  shell_username   = "${var.ec2_bastion_user}"
  ip_allow1        = "${var.ip_allow1}"
  ip_allow2        = "${var.ip_allow2}"
  ip_allow3        = "${var.ip_allow3}"
  ip_allow4        = "${var.ip_allow4}"
  ip_allow5        = "${var.ip_allow5}"
  state_bucket     = "${var.state_bucket}"
}

###############################################################################
# Outputs
###############################################################################
output "environment" {
  value = "${var.env}"
}

output "bastion_public_ip" {
  value = "${module.bastion.public_ip}"
}

output "bastion_private_ip" {
  value = "${module.bastion.private_ip}"
}

output "bastion_user" {
  value = "${var.ec2_bastion_user}"
}

output "bastion_ami_image_id" {
  value = "${module.bastion.ami_image_id}"
}

output "bastion_ami_creation_date" {
  value = "${module.bastion.ami_creation_date}"
}

output "bastion_ami_name" {
  value = "${module.bastion.ami_name}"
}
