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

The above should setup resources for the AWS account. Once the infrastructure
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

### Pre-Merge Integration Testing

To validate the integration of AMI changes with Service Catalog products several
resources need to be created in AWS including a test AMI, a test CFN template
(uploaded to S3), and a test product in Service Catalog. Finally, the test
product can be provisioned from https://sc-dev.sageit.org/ for user-acceptance
testing of the changes to the AMI and/or CFN template.

This process has been automated by using standard deploy pipelines on test
branches. Automating the process improves test consistency and accuracy and
reduces the impact of human error.

Anyone with write access to the upstream repos can automate creating AMIs and
uploading CFN templates to S3 by pushing `test/*` branches directly to the
uptsream repo. For example, pushing a branch named `test/foo` directly to
`Sage-Bionetworks-IT/packer-rstudio` will create an AMI named
`packer-rstudio-test/foo` in `imagecentral`, and pushing a branch named
`test/bar` directly to `Sage-Bionetworks/service-catalog-library` will upload
the templates to `service-catalog-library/test/bar/` in the bootstrap bucket in
`admincentral`.

The standard PR development process is used to create a test product in Service
Catalog in this `scipool` sceptre project, such as in [this PR](https://github.com/Sage-Bionetworks-IT/organizations-infra/pull/1109).

The full process with automation is:

1. Commit changes to the target packer repo to modify the AMI on a branch that
   starts with `test/`, and push it directly to the upstream repo to create a
   test AMI.
   - Initial manual testing of the AMI can be performed by using it to boot an
     EC2 instance.
1. Commit changes to `service-catalog-library` on a branch that starts with
   `test/` to update the relevant template with the new AMI, and push directly
   to the origin repo to upload the templates to S3.
1. Create a pull request for `organizations-infra` to modify or add a template
   in [/sceptre/scipool/config/develop/](./config/develop) to deploy a Service
   Catalog test product in the `scipool-dev` account.
1. Provision the test product from http://sc-dev.sageit.org to manually validate
   AMI integration with the product template; and manually terminate when done.
1. Create a pull request for the packer repo to modify the AMI.
1. Create a pull request for `service-catalog-library` to reference the new AMI.
1. Create a pull request for `organizations-infra` to update the product templates
   in the production accounts [scipool-prod](./config/prod), [bmgf-ki](./config/dmgf-ki),
   and [strides](./config/strides).

The list of active packer repos that are used by Service Catalog products:

1. `Sage-Bionetworks-IT/packer-amazonlinux-docker`
1. `Sage-Bionetworks-IT/packer-base-ubuntu-jammy`
1. `Sage-Bionetworks-IT/packer-docker-server`
1. `Sage-Bionetworks-IT/packer-winserver-2022`

## Issues
* https://sagebionetworks.jira.com/projects/IT

## Secrets
* We use the [AWS SSM](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html)
to store secrets for this project.  Sceptre retrieves the secrets using
a [sceptre ssm resolver](https://github.com/cloudreach/sceptre/tree/v1/contrib/ssm-resolver)
and passes them to the cloudformation stack on deployment.
