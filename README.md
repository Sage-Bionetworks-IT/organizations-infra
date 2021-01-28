# Overview
Install, configure and manage the AWS organizations account.

## Deployments

### org-formation

Deploy resources to master and all member accounts

* install [nodejs][3]
* cd org-formation
* npx org-formation print-tasks --profile master-profile --verbose --print-stack organization-tasks.yaml

### sceptre

Deploy resources to master and all member accounts

* install [lerna][4]
* cd sceptre
* npx lerna run deploy --stream

We use lerna to recursively execute deployment `scripts` (in package.json files) in all sub directories.


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
[4]: https://lerna.js.org/
