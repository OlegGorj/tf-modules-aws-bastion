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

variable "cred-file" {
  default = "~/.aws/credentials"
}

variable "namespace" {
  default = "awscloud.io"
}
variable "name" {
  default = "testcluster"
}

###############################################################################
# RESOURCES
###############################################################################
terraform {
  backend "s3" {
    encrypt = true
    acl     = "private"
  }
}

provider "aws" {
  region                   = "${var.region}"
  shared_credentials_file  = "${var.cred-file}"
  profile                  = "${var.env}"
}

module "vpc" {
  source    = "git::https://github.com/OlegGorj/tf-modules-aws-vpc.git?ref=dev-branch"
  namespace = "${var.namespace}"
  stage     = "${var.env}"
  name      = "${var.name}"
  cidr_block = "10.0.0.0/18"
  tags      = {Name = "TestVPN", environment = "dev", terraform = "true"}
}


locals {
  # Note: newbits=1 in cidrsubnet(module.vpc.vpc_cidr_block, 1, ..) will give me 2 subnets
  ca_central_1a_public_cidr_block  = "${cidrsubnet(module.vpc.vpc_cidr_block, 2, 0)}"
  ca_central_1a_private_cidr_block = "${cidrsubnet(module.vpc.vpc_cidr_block, 2, 1)}"
  ca_central_1b_private_cidr_block = "${cidrsubnet(module.vpc.vpc_cidr_block, 2, 2)}"
}

module "public_subnets" {
  source            = "git::https://github.com/oleggorj/tf-modules-aws-subnet.git?ref=dev-branch"
  namespace         = "${var.namespace}"
  stage             = "${var.env}"
  name              = "public subnet 1A"
  subnet_names      = ["web1"]
  vpc_id            = "${module.vpc.vpc_id}"
  cidr_block        = "${local.ca_central_1a_public_cidr_block}"
  type              = "public"
  igw_id            = "${module.vpc.igw_id}"
  availability_zone = "ca-central-1a"
  attributes        = ["ca-central-1a"]
  tags              = {environment = "dev", terraform = "true", type = "public", name = "web", az = "ca-central-1a"}
}

module "private_subnets_1" {
  source            = "git::https://github.com/oleggorj/tf-modules-aws-subnet.git?ref=dev-branch"
  namespace         = "${var.namespace}"
  stage             = "${var.env}"
  name              = "private subnet 1A"
  subnet_names      = ["cassandra"]
  vpc_id            = "${module.vpc.vpc_id}"
  cidr_block        = "${local.ca_central_1a_private_cidr_block}"
  type              = "private"
  ngw_id            = "${module.public_subnets.ngw_id}"
  availability_zone = "ca-central-1a"
  attributes        = ["ca-central-1a"]
  tags              = {environment = "dev", terraform = "true", type = "private", name = "database", az = "ca-central-1a"}
}
module "private_subnets_2" {
  source            = "git::https://github.com/oleggorj/tf-modules-aws-subnet.git?ref=dev-branch"
  namespace         = "${var.namespace}"
  stage             = "${var.env}"
  name              = "private subnet 1B"
  subnet_names      = ["cassandra"]
  vpc_id            = "${module.vpc.vpc_id}"
  cidr_block        = "${local.ca_central_1b_private_cidr_block}"
  type              = "private"
  ngw_id            = "${module.public_subnets.ngw_id}"
  availability_zone = "ca-central-1b"
  attributes        = ["ca-central-1b"]
  tags              = {environment = "dev", terraform = "true", type = "private", name = "database", az = "ca-central-1b"}
}

resource "aws_key_pair" "key" {
  key_name   = "${var.env}"
  public_key = "${file("~/.ssh/dev_key.pub")}"
}

#data "terraform_remote_state" "vpc" {
#  backend = "s3"
#  config {
#    region     = "${var.region}"
#    bucket     = "${var.state_bucket}"
#    key        = "terraform/vpc/${var.env}.tfstate"
#    profile    = "${var.env}"
#    encrypt    = 1
#    acl        = "private"
#    kms_key_id = "${var.kms_key_id}"
#  }
#}

# call bastion module
module "bastion" {
  source           = "git::https://github.com/OlegGorj/tf-modules-aws-bastion.git?ref=dev-branch"
  env              = "${var.env}"
  region           = "${var.region}"
  instance_type    = "${var.ec2_bastion_instance_type}"
  bastion_key_name = "${var.key_name}"
  bastion_key_path = "${var.key_path}"
  vpc_id           = "${module.vpc.vpc_id}"
  vpc_cidr         = "${module.vpc.vpc_cidr_block}"
  subnet_ids       = "${module.public_subnets.subnet_ids}"
  shell_username   = "${var.ec2_bastion_user}"
  state_bucket     = "${var.state_bucket}"
}

###############################################################################
# Outputs
###############################################################################
output "environment" {
  value = "${var.env}"
}

#output "bastion_public_ip" {
#  value = "${module.bastion.public_ip}"
#}
#
#output "bastion_private_ip" {
#  value = "${module.bastion.private_ip}"
#}
#
#output "bastion_user" {
#  value = "${var.ec2_bastion_user}"
#}
#
#output "bastion_ami_image_id" {
#  value = "${module.bastion.ami_image_id}"
#}
#
#output "bastion_ami_creation_date" {
#  value = "${module.bastion.ami_creation_date}"
#}
#
#output "bastion_ami_name" {
#  value = "${module.bastion.ami_name}"
#}
