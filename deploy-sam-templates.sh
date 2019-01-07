#!/bin/bash
set -ex

# The purpose of this script is to deploy SAM cloudformation
# templates to AWS.  Sceptre does not support deploying SAM
# yet (https://github.com/cloudreach/sceptre/issues/324) 
# so we use the awscli which has a special CF `deploy` command
# specifically for SAM templates.

CF_BUCKET="bootstrap-awss3cloudformationbucket-19qromfd235z9"  # in org-sagebase-admincentral account

# deploy rotate-credentials
curl \
https://s3.amazonaws.com/$CF_BUCKET/aws-infra/master/rotate-credentials.yaml \
--create-dirs -o remote-templates/rotate-credentials.yaml

aws cloudformation deploy \
--capabilities CAPABILITY_IAM \
--template-file remote-templates/rotate-credentials.yaml \
--stack-name rotate-credentials \
--no-fail-on-empty-changeset \
--parameter-overrides DisableKeys="true" SendEmail="true" SenderEmail="it@sagebase.org" SendReport="true"

