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
