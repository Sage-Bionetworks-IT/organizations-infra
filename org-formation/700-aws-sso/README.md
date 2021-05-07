### Purpose of these templates
The templates in this folder enable [AWS SSO](https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html)
in the Management account. SSO is used to enable human access to accounts within the organization,
both to the console as well as through the CLI.

#### Setup SSO

Follow these instructions to setup AWS SSO and integrate it with Jumpcloud IDP

1. Login to AWS console as admin
2. Goto SSO console and Enable SSO
3. Setup JC IDP integration with SSO using the
   [JC instructions](https://support.jumpcloud.com/support/s/article/Single-Sign-On-SSO-With-AWS-SSO)
4. Copy the "AWS SSO Sign-in URL" from AWS SAML 2.0 authentication and paste it into the JC SSO setting "Login URL"
5. In JC SSO setting "Enable management of User Groups and Group Membership in this application" to allow
   JC to manage AWS SSO user and groups with SCIM.
6. In the AWS SSO identity source setting select "Enable automatic provisioning"
   *Copy the "SCIM endpoint" and "Access Token" from AWS and paste it into the JC SCIM settings "SP base URL" and "SP API Token" fields.
7. Setup JC users/groups and give access to JC SSO app.
8. Check that JC users/groups are automatically synced to AWS SSO
9. Verify that JC app from the JC user login portal has access to the AWS account(s) and can sign into the account from JC.
