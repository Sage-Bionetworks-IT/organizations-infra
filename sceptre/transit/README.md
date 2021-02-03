# Overview
A project to install, configure and manage org-sagebase-transit account.
The purpose of this account is to run the AWS transit gateway as the
"hub" of our hub and spoke architecture.

![alt text][architecture]


## Workflow
AWS enforces a specific workflow when setting up the Transit Gateway in a hub
and spoke architecture.

1. Setup the transit gateway in the central/hub account.
2. Create a transit gateway route table in the hub account.
3. Share the transit gateway in the hub account (VPC settings).
4. Share the transit gateway to spoke accounts with the Resource Access Manager.
5. Accept invitations from spoke account in the Resource Access Manager.
6. Create attachments to the transit gateway hub from spoke accounts.
7. Add ("Associate") spoke TGW attachments to the hub transit gateway route table.

## Setup Transit Gateway

### Setup Hub VPC
The transit gateway hub VPC is created with [unionstation](config/prod/unionstationvpc.yaml)
file.  That TGW is shared out to our spoke accounts defined in by
[sceptre_user_data.TgwSpokes](config/prod/sage-tgw.yaml).

### Add spoke VPC
The Hub VPC is already setup and only need to be done once.  Spokes may be connected to the
hub with the following workflow:

1. Create a PR in this repo with new `TgwSpokes` in [sage-tgw.yaml](config/prod/sage-tgw.yaml)
and [sagetgw-routes.yaml](config/prod/sage-tgw-routes.yaml).  Look at existing PRs as
[examples](https://github.com/Sage-Bionetworks/transit-infra/pull/23).
2. Review and merge PR
3. Once merged and deployed the TGW will be shared to the spoke account and VPC routes
will be setup to route traffic from the hub to the spoke VPC.
4. Login to spoke account with admin user/role and accept the sharing invitation
in Resource Access Manager -> Shared with me -> Resource Shares ->
accept the invitation
5. Once the invitation is accepted the shared transit gateway (from "hub")
should appear in the spoke account's VPC -> TransitGateway

#### Setup Spoke Attachment
Setting up a spoke requires setting up routes on the Hub VPC and on the spoke VPC.
This section is to setup the routes on the spoke end.

__NOTE__: Make sure hub VPC invitation has been accepted in `Add spoke VPC` before continuing

1. Create a PR in the spoke repo similar to
[tgw-spoke-BridgeServer2-vpc.yaml](https://github.com/Sage-Bionetworks/Bridge-infra/tree/prod/config/prod/tgw-spoke-BridgeServer2-vpc.yaml)
to setup the attachment and routes from spoke to hub VPC.
Look at existing PR as an [example](https://github.com/Sage-Bionetworks/Bridge-infra/pull/142)
2. Review and merge PR
3. Once merged and deployed the TGW there will be a VPC route from spoke
to hub VPC.  There will also be a new security group that will allow the
hub (unionstation) access to the resources in the spoke account.

### Allow Traffic Between VPCs
The key to allowing traffic between the hub (unionstation) VPC and the spoke VPC
is to apply the `TgwSecurityGroup` to the resource in the spoke account.

__Note:__ The `TgwSecurityGroup` SG name will be something like `tgw-spoke-BridgeVpc-TgwSecurityGroup-HC8K48Q48USV`

Workflow to test access:
1. Provision EC2 in unionstation with SSH access
2. Provision a private EC2 in spoke account (i.e org-sagebase-bridgedev) and apply the `TgwSecurityGroup`
to the instance.
3. SSH into unionstation EC2 and attempt to access (ping/ssh/etc..) the EC2 in the spoke account.


## Setup AWS client VPN
We setup AWS client VPN leveraging routes that were setup by the transit gateway
configuration.  The AWS client VPN is created with
[sage-client-vpn.yaml](config/prod/sage-client-vpn.yaml) file.

### Setup IDP
We federate Jumpcloud users to the VPN with
[Jumpcloud SSO](https://support.jumpcloud.com/support/s/article/Single-Sign-On-SSO-with-AWS-Client-VPN)
and [jumpcloud-idp.yaml](config/prod/jumpcloud-idp.yaml).  This allows users to login
to the VPN with their Jumpcloud credentials.  Once they are logged in they
will have access to resources in AWS VPCs.

### Setup Jumpcloud SSO
We need to setup two SSO apps in jumpcloud because it does not support multiple ACS URLs.
We need one SSO for the VPN connection and another one for the VPN self service portal.

Follow [instructions](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/client-authentication.html)
to create a certificate using [easy-rsa](https://github.com/OpenVPN/easy-rsa)
then import the certifcate to the AWS certificate manager

Create a `transitvpn` SSO app for VPN access:
  * SP Entity ID: `urn:amazon:webservices:clientvpn`
  * ACS URL: `http://127.0.0.1:35001`
  * Enable `Declare Redirect Endpoint` option
  * IDP URL: `https://sso.jumpcloud.com/saml2/transitvpn`
  * Attributes: `FirstName=firstname`, `LastName=lastname`, `NameID=email`
  * Enable `Group Attributes option` and set it to `memberOf`

Create a `transitvpnssp` SSO app for the VPN self service portal access:
  * SP Entity ID: `urn:amazon:webservices:clientvpn`
  * ACS URL: `http://127.0.0.1:35001`
  * Enable `Declare Redirect Endpoint` option
  * IDP URL: `https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml`
  * Attributes: `FirstName=firstname`, `LastName=lastname`, `NameID=email`
  * Enable `Group Attributes option` and set it to `memberOf`

Deploy [sage-client-vpn.yaml](config/prod/sage-client-vpn.yaml) to create the
AWS client VPN endpoint.  __Note:__ the `ServerCertificateArn` parameter value should
be the certificate that was created by easy-rsa and imported into the
AWS cerfiticate manager.


### Manage VPN Access
VPN user access is managed by [sceptre_user_data.TgwSpokes](config/prod/sage-client-vpn.yaml).
Modify the `TgwSpokes` definition to update Jumpcloud user access to VPCs.

__Note:__ `AccessGroups` must match Jumpcloud groups

Once the configurations are setup users will get access to specific VPCs after logging into
the VPN.

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
