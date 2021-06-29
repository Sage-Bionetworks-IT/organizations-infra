### Purpose of these templates
The templates in this folder enable [AWS SSO](https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html)
in the Management account. SSO is used to enable human access to accounts within the organization,
both to the console as well as through the CLI.

#### Setup SSO

Follow these instructions to setup AWS SSO and integrate it with Jumpcloud IDP. This is a one time setup.

1. Login to AWS console as admin.
2. Goto SSO console and [Enable SSO](https://docs.aws.amazon.com/singlesignon/latest/userguide/step1.html).
3. Goto SSO settings and [disable MFA](https://docs.aws.amazon.com/singlesignon/latest/userguide/how-to-disable-mfa.html)
   because we already require MFA on our IDP.
4. Setup JC IDP integration with SSO using the
   [JC instructions](https://support.jumpcloud.com/support/s/article/Single-Sign-On-SSO-With-AWS-SSO)
5. Copy the "AWS SSO Sign-in URL" from AWS SAML 2.0 authentication and paste it into the JC SSO setting "Login URL"
6. In JC SSO setting "Enable management of User Groups and Group Membership in this application" to allow
   JC to manage AWS SSO user and groups with SCIM.
7. In the AWS SSO identity source setting select "Enable automatic provisioning" then
   copy the "SCIM endpoint" and "Access Token" from AWS and paste it into the JC SCIM settings "SP base URL" and
   "SP API Token" fields.
8. Setup JC users/groups and give access to JC SSO app.
9. Check that JC users/groups are automatically synced to AWS SSO
10. Verify that JC app from the JC user login portal has access to the AWS account(s) and can sign into the
    account from JC.

#### Setup Account Access

Follow these instructions to setup Jumpcloud user access to AWS accounts.

1. Login to Jumpcloud admin console
2. Create a JC user group
3. Map the JC user group to the AWS SSO application
4. Login to the Sage AWS Organization account and goto SSO console.  An SSO user
   group ID (i.e. 906769aa66-5d23a723-54f3-4c08-a67b-311e555f4e85) will automatically
   be created for the new group.
5. Add a new resource to ./_tasks.yaml with the new policy, role and matching AWS SSO group ID.
6. Deploy the resource.
7. In JC admin console map users to the JC user group

#### Test AWS Account Access

1. Login to the Jumpcloud user portal with the user that was mapped to the JC user group.
2. Select applications -> AWS SSO
3. The account with the role should appear for the user to select.
