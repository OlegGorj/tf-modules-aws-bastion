.ONESHELL:
SHELL := /bin/bash
.PHONY: help set-env init update plan plan-destroy show graph apply output taint
# Strips 'build-' from the folder name and uses this as the storage folder in S3.
BUCKETKEY = $(shell basename "$$(pwd)" | sed 's/terraform-//')


help:
