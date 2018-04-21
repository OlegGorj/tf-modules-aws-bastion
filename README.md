[![GitHub release](https://img.shields.io/github/release/OlegGorj/tf-modules-aws-bastion.svg)](https://github.com/OlegGorj/tf-modules-aws-bastion/releases)
[![GitHub issues](https://img.shields.io/github/issues/OlegGorj/tf-modules-aws-bastion.svg)](https://github.com/OlegGorj/tf-modules-aws-bastion/issues)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/0c85a578cb0c4c85bddb373a6f3686ce)](https://app.codacy.com/app/oleggorj/tf-modules-aws-bastion?utm_source=github.com&utm_medium=referral&utm_content=OlegGorj/tf-modules-aws-bastion&utm_campaign=badger)

# Terraform Module: AWS Bastion

Templated Terraform module to implement Bastion node

## Overview

Builds the following infrastructure

- VPC
- Public subnet and 2 private subnets
- EC2 instance
- Route53 entries
- EIP because the bastion isn't in an ASG

> Note: this implementation uses remote terraform state and stores variables inside S3 bucket

`Makefile` contains all actions that you may need to deploy Bastion node (If you find that any additional actions are needed please let me know or create PR).
List of actions in `Makefile`:

- validate
- set-env
- init
- update
- plan
- plan-destroy
- show
- graph
- apply
- apply-target
- output
- taint
- destroy
- destroy-target

### Prerequisites:

- existing CMK in AWS KMS
- generated keys pair
- created S3 bucket to store TF state

## How to use Bastion module:

Example of `../environments/dev/dev.tfvars` file:

```bash
export ENVIRONMENT="dev"

export AWS_REGION="ca-central-1"
export AWS_PROFILE="default"

export AWS_STATE_BUCKET="tf-state-bucket"

export AWS_KMS_ARN="arn:aws:kms:ca-central-1:4545454545:key/xxxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxxx"
export TF_VAR_kms_key_id=${AWS_KMS_ARN}
```

Init terraform:

```bash

# example of usage is located under ./test directory
cd test

terraform init  \
    -backend-config="bucket=ca-central-1.aws-terraform-state-bucket" \
    -backend-config="key=terraform/dev/tf.tfstate" \
    -backend-config="region=ca-central-1" \
    -backend-config="profile=dev"  \
    -var-file=../environments/dev/dev.tfvars

```

Plan terraform:

```bash
terraform plan -var-file=../environments/dev/dev.tfvars -out=./terraform
```

Apply terraform:

```bash
terraform apply -var-file=../environments/dev/dev.tfvars
```





---
