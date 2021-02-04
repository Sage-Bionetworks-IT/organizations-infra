# Overview
Install, configure and manage the AWS AdminCentral account.


## Instructions to create or update CF stacks

```
# Update CF stacks with sceptre:
# sceptre launch-stack prod <stack_name>
```

The above should setup resources for the AWS account.  Once the infrastructure
for the account has been setup you can access and view the account using the
[AWS console](https://AWS-account-ID-or-alias.signin.aws.amazon.com/console).

*Note - This project depends on CF templates from other accounts.*

## VPN Gateway
This account is setup to be the VPN Gateway.  A VPC peering connection is required to
allow the VPN access to other VPCs.  To setup VPC peering from the VPN VPC to another
VPC run the following template.

```
set parameters in conf/prod/peering-bridge-prod.yaml
run 'sceptre launch-stack prod peering-bridge-prod'
```

The [VPCPeer.yaml template](./cf_templates/VPCPeer.yaml) should setup the VPC peering
from the VPN VPC to the *$PeerVPC* in the account identified by *$PeerAccountName*.
This template should be run for each VPC peering connection therefore a
`unique stack-name should be given` for each run of this template.

**Note** - VPCPeer.yaml requires that the *$PeerVPC* be setup with [CrossAccountRoleTemplate.json](https://github.com/awslabs/aws-cloudformation-templates/blob/master/aws/solutions/VPCPeering/CrossAccountRoleTemplate.json)
template which was added to the [essentials.yaml](https://github.com/Sage-Bionetworks/aws-infra/blob/master/cf_templates/essentials.yaml)
template.  An additional configuration step is required on the PeerVPC end to
complete this setup, run the [peer-route-config.yaml](https://github.com/Sage-Bionetworks/aws-infra/blob/master/cf_templates/peer-route-config.yaml)
template to complete the configuration.


## Continuous Integration
We have configured Travis to deploy CF template updates.  Travis deploys using
[sceptre](https://sceptre.cloudreach.com/latest/about.html)


# Contributions

## Issues
* https://sagebionetworks.jira.com/projects/BRIDGE

## Builds
* https://travis-ci.org/Sage-Bionetworks/admincentral-infra

## Secrets
* We use the [AWS SSM](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html)
to store secrets for this project.  Sceptre retrieves the secrets using
a [sceptre ssm resolver](https://github.com/cloudreach/sceptre/tree/v1/contrib/ssm-resolver)
and passes them to the cloudformation stack on deployment.
