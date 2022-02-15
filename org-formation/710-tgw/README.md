# Overview
Setup and configure the AWS transit gateway (TGW) in the org-sagebase-transit account.
It will act as the "hub" of our [hub and spoke architecture][1] to manage network
traffic to our VPCs.

![alt text][architecture]

## Design
There are many possible [design patterns for a TGW][2].  Our TGW is configured in a fully
isolated network pattern similar to this diagram.

![alt text][fully_isolated_network_design]

__Notes__:
* The Transit VPC is named "unionstationvpc".
* We use the AWS client VPN instead of a direct connect.


## Workflow
AWS enforces a specific workflow when setting up the Transit Gateway in a hub
and spoke architecture.

1. Setup the transit gateway in the central/hub account.
2. Create a transit gateway route table in the hub account.
3. Share the transit gateway in the hub account (VPC settings).
4. Share the transit gateway to spoke accounts with the Resource Access Manager.
5. Accept invitations from spoke account in the Resource Access Manager.

Note: We have enabled auto accept invitations in our AWS organization account which
means that invitations are automatically accepted when TGW is shared to any AWS account
that is part of the Sage organizations account.

If the account is NOT in the organization then you must manually accept the sharing invitation:
* Login to spoke account with admin user/role
* Accept the sharing invitation in the Resource Access Manager -> Shared with me ->
Resource Shares -> accept the invitation

6. Create attachments to the transit gateway hub from spoke accounts.
7. Add ("Associate") spoke TGW attachments to the hub transit gateway route table.

## Setup Transit Gateway
We have setup automation for the above workflow using [org-formation][3]

### Setup Hub VPC
The Hub VPC, `unionstationvpc`, is already setup and only need to be done once.
Once the TGW hub is deployed we only need to connect additional VPCs in spoke accounts
to the hub.

### Add spoke VPC
Spokes may be connected to the hub with the following workflow:

Create a PR in this repo with the following changes to [_tasks.yaml](_tasks.yaml):
1. If it doesn't already exist, add a spoke account to `TransitGateway.Parameters.Principals` parameter.
This is used to share the TGW to spoke accounts.
2. Add a new entry to the `TransitGatewayRoutes.TemplatingContext.TgwSpokes` dictionary.
This is used to setup routes from unionstation VPC to VPCs in spoke accounts.
3. Add a new entry to the `Mappings` dictionary.  This is used to setup the TGW attachments
and routes in spoke accounts.
4. Review and merge PR 

Once merged and deployed the TGW routes will be updated to route traffic from the
hub VPC to the spoke VPC.

__Note__: It is recommended to only add one VPC at a time which means you should split up your PRs to add one spoke VPC per PR.

### Test TGW routes

Workflow to test routes:
1. Provision a private EC2 in `unionstationvpc`
2. Create a security group to allow `ICMP` ingress traffice
3. Apply security group to EC2
4. Repeate provision EC2 steps in the spoke account.

You should be able to ping the EC2 in spoke VPC from the EC2 in the `unionstationvpc` and vice versa.
You should *NOT* be able to ping an EC2 in one spoke VPC to an EC2 in another spoke VPC.

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

## Secrets
* We use the [AWS SSM](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html)
to store secrets for this project.  Sceptre retrieves the secrets using
a [sceptre ssm resolver](https://github.com/cloudreach/sceptre/tree/v1/contrib/ssm-resolver)
and passes them to the cloudformation stack on deployment.


[architecture]: transit-gateway-arch.png "hub and spoke architecture"
[fully_isolated_network_design]: fully_isolated_network_design.png  "fully isolated network design"  
[1]: https://aws.amazon.com/blogs/networking-and-content-delivery/automating-aws-transit-gateway-attachments-to-a-transit-gateway-in-a-central-account        "hub and spoke architecture"
[2]: https://docs.aviatrix.com/HowTos/tgw_design_patterns.html "tgw design patterns"
[3]: https://github.com/org-formation/org-formation-cli "org-formation"