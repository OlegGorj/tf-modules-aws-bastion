.ONESHELL:
SHELL := /bin/bash
.PHONY: help set-env init update plan plan-destroy show graph apply output taint
# Strips 'build-' from the folder name and uses this as the storage folder in S3.
BUCKETKEY = $(shell basename "$$(pwd)" | sed 's/terraform-//')


help:


init: validate set-env
	@rm -rf .terraform/*
	@terraform init \
		-backend-config="region=$(AWS_REGION)" \
        -backend-config="bucket=$(AWS_STATE_BUCKET)" \
        -backend-config="profile=$(AWS_PROFILE)" \
        -backend-config="key=terraform/$(BUCKETKEY)/$(ENVIRONMENT).tfstate" \
        -backend-config="encrypt=1" \
        -backend-config="acl=private" \
        -backend-config="kms_key_id=$(AWS_KMS_ARN)"

set-env:
	@if [ -z $(ENVIRONMENT) ]; then\
         echo "ENVIRONMENT was not set"; exit 10;\
     fi
	@echo -e "\nRemoving existing ENVIRONMENT.tfvars from local directory"
	@find . -maxdepth 1 -type f -name '*.tfvars' ! -name example_ENV.tfvars -exec rm -f {} \;
	@echo -e "\nPulling fresh $(ENVIRONMENT).tfvars from s3://$(AWS_STATE_BUCKET)/terraform/$(BUCKETKEY)/"
	@aws s3 cp s3://$(AWS_STATE_BUCKET)/terraform/$(BUCKETKEY)/$(ENVIRONMENT).tfvars . --profile=$(AWS_PROFILE)


validate:
	@for i in $$(find -type f -name "*.tf" -exec dirname {} \; | grep -v "/test"); do \
        terraform validate "$$i"; \
        if [ $$? -ne 0 ]; then \
                echo "Failed Terraform .tf file validation"; \
                echo; \
                exit 1; \
        fi; \
    done
