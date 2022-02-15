# Overview
Setup and configure the AWS client Virtual Private Network (VPN) in the
org-sagebase-transit account.

![alt text][architecture]

## Setup AWS client VPN
We setup the AWS client VPN leveraging routes that were created by the
[transit gateway](../710-tgw/README.md) configuration.

### Setup IDP
We federate users to the VPN with [Jumpcloud SSO](https://support.jumpcloud.com/support/s/article/Single-Sign-On-SSO-with-AWS-Client-VPN)
which allows users to login to the VPN with their Jumpcloud credentials.
This will also allow us to manage VPC access thru Jumcploud user groups.

### Setup Jumpcloud
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

### Setup AWS SAML Providers
After setting up Jumpcloud SSO we can let org-formation deploy the [_tasks.yaml](_tasks.yaml)
file which will create the AWS SAML providers.

## Add VPN routes

Following workflow to allow VPN users access to VPCs:

Create a PR in this repo with the following changes to [_tasks.yaml](_tasks.yaml):
1. Add a new entry to the `Vpn.TemplatingContext.TgwSpokes` dictionary.
2. The `CIDR` is the VPC IP address that the VPN should allow access to.
3. The `AccessGroup` value(s) must match a Jumpcloud defined `User Group`. This allows
the Jumpcloud user group(s) access to a VPC defined by its CIDR.

Once merged and deployed the VPN routes will be updated to route traffic from the
hub VPC to the spoke VPCs.

__Note__:
* It is recommended to only add one VPC at a time which means you should split up your PRs to add one spoke VPC per PR.
* The `ServerCertificateArn` parameter value should
be the certificate that was created by easy-rsa and imported into the
AWS cerfiticate manager.

## VPN User Workflow
VPN users must use a VPN client to access cloud resources

* Login to the [Sage IT VPN portal](https://vpn.sageit.org)
* Download the VPN client configuration file
* Download the AWS Client VPN application
* Install and run the client VPN app
* Load the configuration file into the VPN client:

File -> Manage Profiles -> Add Profile -> select the downloaded configuration file -> Add Profile -> Done

* Now use the VPN client to `connect`

Once connected you should have access to cloud resources.  Access to resources is managed in Jumpcloud with User Groups.


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


[architecture]: client-vpn-arch.png "client vpn architecture"
