# Overview
A project to install, configure and manage an AWS account.

## Purpose
The purpose of this project is to build a self service provisioning
system using the
[AWS service catalog](https://docs.aws.amazon.com/servicecatalog/latest/adminguide/introduction.html).

We are leveraging the [AWS service catalog reference architecure](https://github.com/Sage-Bionetworks/service-catalog-library)
to build out the service catalog.

## Instructions to create or update CF stacks

```
# Update CF stacks with sceptre:
# sceptre launch-stack prod <stack_name>
```

The above should setup resources for the AWS account.  Once the infrastructure
for the account has been setup you can access and view the account using the
[AWS console](https://AWS-account-ID-or-alias.signin.aws.amazon.com/console).

*Note - This project depends on CF templates from other accounts.*

## Contributions
Contributions are welcome.

Requirements:
* Install [pre-commit](https://pre-commit.com/#install) app
* Clone this repo
* Run `pre-commit install` to install the git hook.

## Testing

### Pre-Commit
As a pre-deployment step we syntatically validate our sceptre and
cloudformation yaml files with [pre-commit](https://pre-commit.com).

Please install pre-commit, once installed the file validations will
automatically run on every commit. Alternatively you can manually
execute the validations by running `pre-commit run --all-files`.
Please install pre-commit, once installed the file validations will
automatically run on every commit.

### Functional Testing
The process to test the functionality of an AMI and it's integration with our
Service Catalog products is to first create a test AMI, upload a modified
product template to S3, and create a new Service Catalog product in the
scipool dev account to verify manually from https://sc-dev.sageit.org/

The deploy pipelines for both our packer repos and our service catalog library
will create artifacts for branches that begin with `test/` in the sandbox
account, allowing anyone with write access to the packer repos to create test
AMIs, and anyone with write access to service-catalog-library to upload test
templates for service catalog to S3.

1. Commit changes to the packer repo to update or modify the AMI on a branch
   that starts with `test/`, and push directly to the origin repo.
1. Manually create an EC2 instance in the `itsandbox` account from the test AMI
   for any initial system validation, then terminate it.
1. Commit changes to `service-catalog-library` on a branch that starts with
   `test/` to update the desired template, and push directly to the origin repo.
1. Create a pull request for `organizations-infra` to add a new Service Catalog
   product to `scipool-dev` with 'test' in the name for the test template.
1. Provision the test product from http://sc-dev.sageit.org to validate AMI
   integration with the product template
1. Create a pull request for the packer repo to modify the AMI.
1. Create a pull request for `service-catalog-library` to reference the new AMI.
1. Create a pull request for `organizations-infra` to remove the test product and
   update the target product with the new template version.

## Issues
* https://sagebionetworks.jira.com/projects/IT

## Secrets
* We use the [AWS SSM](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html)
to store secrets for this project.  Sceptre retrieves the secrets using
a [sceptre ssm resolver](https://github.com/cloudreach/sceptre/tree/v1/contrib/ssm-resolver)
and passes them to the cloudformation stack on deployment.
