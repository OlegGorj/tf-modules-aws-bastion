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
// Get us the newest Ubuntu base ami
data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    filter {
      name   = "owner-id"
      values = ["099720109477"] # Canonical
    }
}

resource "aws_iam_role" "instance_role" {

  name = "${var.env}-bastion-instance-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "instance_policy" {
  name = "${var.env}-bastion-instance-role-policy"
  role = "${aws_iam_role.instance_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${var.state_bucket}",
                "arn:aws:s3:::${var.state_bucket}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "S3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::${var.state_bucket}/ssh/${var.env}/machine-user/*",
                "arn:aws:s3:::${var.state_bucket}/ssh/${var.env}/common/*",
                "arn:aws:s3:::${var.state_bucket}/ansible/${var.env}/bastion/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets",
                "elasticache:Describe*"
            ],
            "Resource": "*"
        }
    ]
}
EOF

  # Allows the IAM role enough time to propagate through AWS
  provisioner "local-exec" {
    command = <<EOT
            echo "Sleeping for 10 seconds to allow the IAM role enough time to propagate through AWS";
            sleep 10;
            echo "IAM role should be propagated, proceeding.";
EOT
  }
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.env}-bastion-instance-profile"
  role = "${aws_iam_role.instance_role.name}"
}

resource "aws_security_group" "bastion" {
  name        = "${var.env}_security_group"
  vpc_id      = "${var.vpc_id}"
  description = "Bastion security group"

  tags {
    Name      = "${var.env}_bastion_sg"
    TERRAFORM = "true"
  }

  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["${var.ip_allow1}", "${var.ip_allow2}", "${var.ip_allow3}", "${var.ip_allow4}", "${var.ip_allow5}"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "bastion" {
  template = "${file("${path.module}/init.sh")}"

  vars {
    TERRAFORM_env      = "${var.env}"
    TERRAFORM_role     = "bastion"
    TERRAFORM_user     = "${var.shell_username}"
    TERRAFORM_hosts    = "localhost"
    TERRAFORM_region   = "${var.region}"
    TERRAFORM_s3bucket = "${var.state_bucket}"
  }
}

// Bastion does not run in an ASG. Without an EIP, everytime Bastion is destroyed/recreated
// it will get a new randomized EIP. This prevents the randomization.
resource "aws_eip" "bastion" {
  vpc      = true
  instance = "${aws_instance.bastion.id}"
}

resource "aws_instance" "bastion" {
  ami                    = "${data.aws_ami.bastion.id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.bastion_key_name}"
  subnet_id              = "${element(split(",", var.subnet_ids), count.index)}"
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
  user_data              = "${data.template_file.bastion.rendered}"
  iam_instance_profile   = "${aws_iam_instance_profile.bastion.name}"

  tags {
    Name      = "${var.env}_${replace(var.region,"-","")}_bastion"
    TYPE      = "bastion"
    ROLES     = "bastion"
    ENV       = "${var.env}"
    TERRAFORM = "true"
  }
}



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
