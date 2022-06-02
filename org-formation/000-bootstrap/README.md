# Bootstrap

This page provides info on how to setup a new AWS account using org-formation.
Org-formation allows us to fully automate the creation and management of new AWS accounts.

## Required Tools:

* Install [node](1)
* Install [org-formation](2)

## Create Account

Org-formation’s approach to account creation and management centers around AWS
organizations where there is one Master/Management account and multiple member accounts.
Management accounts require bootstrapping while member accounts do not.

### Setup Management Account

Management account require manual bootstrapping however it only needs to be created
once to manage many member accounts.

1. Create an google group or email for the new AWS management account
   (i.e. aws.ManagementAccount@company.com)
2. Manually create a new AWS account and setup payment for it.
3. Make it an organizations account
4. Go to AWS cloudformation console and `create stack` with
   [org-ci-service-access.yaml](https://raw.githubusercontent.com/Sage-Bionetworks/aws-infra/master/templates/IAM/org-ci-service-access.yaml)
   template to bootstrap the account with a service user and role.
   Name the stack `bootstrap-ci-service-access`
5. Get the service user key, secret key and role from the cloudformation stack outputs.
6. Configure an AWS CLI profile with the CiServiceUser and CiServiceRole.
7. Logout of the root account.
8. make a new folder for the management account and cd into the folder.
9. setup an [org-formation project](https://github.com/org-formation/org-formation-reference)
   (i.e. run “npx org-formation init --profile management-profile  --region us-east-1 --verbose”)
10. now you should have files for org-formation you can put under source control and setup
    CI/CD to deploy it to an AWS account.
11. to deploy run perform-tasks command
    (i.e “npx org-formation perform-tasks --profile management-role --verbose --print-stack organization-tasks.yaml”)
12. read the org-formation configuration and
    [account management docs](https://github.com/org-formation/org-formation-cli/blob/master/docs/features.pdf)
    and learn how they work.
13. As a next step it is recommended to setup SSO to give users access to the management account.
    Setting up SAML provider on AWS can be done with the org-formation's
    [Community::IAM::SamlProvider](https://github.com/org-formation/aws-resource-providers/tree/master/iam/saml-provider)

### Setup Member Accounts

The power of org-formation is in it’s ability automate the creation and management of
many member accounts. Org-formation handles all the bootstrapping required for member accounts.

Create an google group or email for the new AWS member account (i.e. aws.MemberAccount1@company.com)

Add a yaml section to organizations.yaml file like soo..
```yaml
  MemberOneAccount:
    Type: OC::ORG::Account
    Properties:
      AccountName: org-sagebase-member-one
      RootEmail: member-one@sagebase.org
      Alias: org-sagebase-member-one
      Tags:
        <<: !Include ./_default_org_tags.yaml
        Department: SysBio
        Project: amp-ad
        # Anna G confirmed that AMP-AD charges should technically
        # be charged to STRIDES account but this tag works
        CostCenter: NIA AMP-AD CC / 101500
        AccountOwner: member-one@sagebase.org
        budget-alarm-threshold: 1000
        budget-alarm-threshold-email-recipient: member-one@sagebase.org
```

run “npx org-formation perform-tasks --profile management-role --verbose --print-stack organization-tasks.yaml”

Org-formation creates the new new member account1 thru the management account.
Through this account creation process AWS will create a special role in the member account.
It’s the AWSServiceRoleForOrganizations role.

Once the account is created the AWSServiceRoleForOrganizations role can be used to
access the member account.  Org-formation will also deploy all cloud resources defined
in it’s templates to the member account.

#### Access Member Accounts

The idea around accessing member accounts centers around assuming cross account roles.
If you have access to the management account with permission to assume the
AWSServiceRoleForOrganizations on the member account then you can get access to
the member account.

To access the member account:
1. login to the management account
2. goto AWS console → switch roles
3. enter the [Account and Role info](./switch-role.png)

__Note__: You can also access the member account with the AWS CLI by using
the CLI to assume the AWSServiceRoleForOrganizations role.

[1]: https://nodejs.org/en/download/package-manager/
[2]: https://github.com/org-formation/org-formation-cli
