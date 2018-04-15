# Terraform Module: AWS Bastion

Templated Terraform module to implement Bastion node

## Overview

Builds the following infrastructure

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

Prerequisites:
- existing CMK in AWS KMS
- generated keys pair

How to use Bastion module:

```bash
export ENVIRONMENT="dev"

export AWS_REGION="us-east-1"
export AWS_PROFILE="default"

export AWS_STATE_BUCKET="tf-state-bucket"

export AWS_KMS_ARN="arn:aws:kms:us-east-1:4545454545:key/xxxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxxx"
export TF_VAR_kms_key_id=${AWS_KMS_ARN}
```


---
