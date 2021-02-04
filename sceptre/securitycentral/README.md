# Overview
Install, configure and manage the
[AWS Sage central security account](https://sagebionetworks.jira.com/wiki/spaces/IT/pages/577044503/Sage+AWS+Logging).
It is used as a secure account to store security information accross multiple AWS accounts.
The use of a security account is an [established best practice](https://aws.amazon.com/blogs/architecture/central-logging-in-multi-account-environments).
It helps security teams detect malicious activities both in real-time and during incident response.
It provides protection to log data in case it is accidentally or intentionally deleted.  It also
helps application teams correlate and analyze log data across multiple application tiers.


## Guard Duty
Guard duty findings from selected Sage accounts are sent to AWS Guardduty in securitycentral.

## Instructions to create or update CF stacks

```
# Update CF stacks with sceptre:
# sceptre launch prod <stack_name>
```

The above should setup resources for the AWS account.  Once the infrastructure
for the account has been setup you can access and view the account using the
[AWS console](https://AWS-account-ID-or-alias.signin.aws.amazon.com/console).

*Note - This project depends on CF templates from [aws-infra repo](https://github.com/Sage-Bionetworks/aws-infra).*

## Setup Guard Duty Aggregation
Steps to guard duty aggregation from source account to Logcentral
 1. Create a PR to add a member account resource, similar to
    [GDSynapseProdMember resource](https://github.com/Sage-Bionetworks/securitycentral-infra/blob/master/templates/guardduty-master.yaml)
 2. Create a PR to add a new [sceptre stack config](https://github.com/Sage-Bionetworks/synapseprod-infra/pull/9)
    to setup a guard duty member on the source account.

## Continuous Integration
We have configured Travis to deploy CF template updates.  Travis deploys using
[sceptre](https://sceptre.cloudreach.com/latest/about.html)

# Contributions

## Issues
* https://sagebionetworks.jira.com/projects/IT

## Builds
* https://travis-ci.org/Sage-Bionetworks/securitycentral-infra

## Secrets
* We use the [AWS SSM](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html)
to store secrets for this project.  Sceptre retrieves the secrets using
a [sceptre ssm resolver](https://github.com/cloudreach/sceptre/tree/v1/contrib/ssm-resolver)
and passes them to the cloudformation stack on deployment.
