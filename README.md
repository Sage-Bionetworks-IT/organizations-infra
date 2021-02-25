# Overview
Install, configure and manage the AWS organizations management account
and all its member accounts.

We use a combination of [org-formation][1] and [sceptre][2] to deploy AWS cloud resources
using [cloudformation][4].

## Deployments
We [boostrapped](./org-formation/000-bootstrap/README.md)
our AWS management account before deployments can happen.

### org-formation

Deploy resources to master and all member accounts

* install [nodejs][3]
* cd org-formation
* run 'npm install'
* run `npx org-formation process-tasks --profile master-profile --verbose --print-stack organization-tasks.yaml`

__Note__: master-profile is a profile that can assume the account's `organizations-admin` role

### sceptre

* create a python 3.x [virtualenv](https://packaging.python.org/guides/installing-using-pip-and-virtual-environments/)
* run `pip install sceptre sceptre-ssm-resolver sceptre-date-resolver git+git://github.com/Sceptre/sceptre-file-resolver.git`
* cd sceptre/_folder_  (i.e. sceptre/sandbox)
* uncomment `# profile: {{ var.profile | default("default") }}` in config/configs.yaml
* run `sceptre --var "profile=member-profile" --var "region=us-east-1" launch prod/AccountAlertTopics.yaml`

__Note__: member-profile is a profile that can assume the member account's `OrganizationAccountAccessRole` role

### Automation
We have setup [Github actions](https://github.com/Sage-Bionetworks-IT/organizations-infra/actions) to automate
deployments to the AWS management and all member accounts. The deployment runs on every merge to the master branch.

Org-formation manages deployments to specific accounts using
[organization Bindings](https://github.com/org-formation/org-formation-cli/blob/master/docs/cloudformation-resources.md#organizationbinding-where-to-create-which-resource)

Sceptre manages deployments to specific accounts with designated config folders (i.e. config/dev or config/prod).


## Contributions
Contributions are welcome.

Requirements:
* Install [pre-commit](https://pre-commit.com/#install) app
* Clone this repo
* Run `pre-commit install` to install the git hook.

## Testing
As a pre-deployment step we syntatically validate our sceptre and
cloudformation yaml files with [pre-commit](https://pre-commit.com).

Please install pre-commit, once installed the file validations will
automatically run on every commit.  Alternatively you can manually
execute the validations by running `pre-commit run --all-files`.
Please install pre-commit, once installed the file validations will
automatically run on every commit.

## Issues
* https://sagebionetworks.jira.com/projects/IT

## Builds
* https://travis-ci.org/Sage-Bionetworks/organizations-infra

## Secrets
* We use the [AWS SSM](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html)
to store secrets for this project.  Sceptre retrieves the secrets using
a [sceptre ssm resolver](https://github.com/cloudreach/sceptre/tree/v1/contrib/ssm-resolver)
and passes them to the cloudformation stack on deployment.


[1]: https://github.com/org-formation/org-formation-cli
[2]: https://github.com/Sceptre/sceptre
[3]: https://nodejs.org/en/download/package-manager/
[4]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html
