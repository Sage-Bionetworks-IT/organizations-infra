## Purpose

Manage hosted zones and wildcard certificates for those zones.

Wildcard certs are generated for the apex records and are intended to be
shared by all services hosted in the zone by passing the ARN of the
appropriate certificate to the hosting service (e.g. CloudFront or an ALB).

Once the hosting service is deployed with the appropriate certificate, create
a DNS CNAME record to redirect our custom domain name to the AWS domain name
used by the hosting service.

Each wildcard cert will need to be manually verified before it can be used.

### finops.sageit.org

This zone is intended for cost-tracking automation, such as lambda-mips-api.

The wildcard certificate created for this zone is expected to be used elsewhere
in org-formation, but not by external infra projects (such as CDK applications).

### app.sagebionetworks.org

This zone is intended for user-facing applications, such as DCA.

CDK applications will export a CloudFormation output with the AWS domain
name for the created ALB. Create a DNS CNAME record in the appropriate
hosted zone with a value pointing to the AWS domain name of the ALB.

### api.sagebionetworks.org

This zone is intended for application-facing applications, such as Schematic.

CDK applications will export a CloudFormation output with the AWS domain
name for the created ALB. Create a DNS CNAME record in the appropriate
hosted zone with a value pointing to the AWS domain name of the ALB.

## Per-Account Certificates

Certificates must exist in the same account they will be used in, and so we
must create a copy of our wildcard certificate in an application account before
the application can be deployed to that account. For example, [the list of
accounts for `app.sagebionetworks.org`](https://github.com/Sage-Bionetworks-IT/organizations-infra/blob/master/org-formation/100-shared-dns/_tasks.yaml#L70).

### Validating New Certificates

When adding a new account to the list for a certificate, the newly-created
certificate must be validated before the CloudFormation stack will succeed.
To validate the certificate:

1. Log in to AWS Console for the application account.
1. Navigate to the new certificate in AWS Certificate Manager.
1. Note the name and value of the needed CNAME record. We only need the host portion of the name (before the first period).
1. Log out of the application account.
1. Log in to AWS Console for the SageIT account.
1. Navigate to the appropriate zone for our new certificate in Route 53.
1. Add a CNAME record with the noted name and value.

It can take several minutes for the validation to complete once the CNAME
record has been created. If the CloudFormation stack fails due to a
timeout validating the certificate, the deploy pipeline can be re-run.

### Providing Certificate ARNs

CDK applications need to configure their certificate ARN in `cdk.json`.
To provide this value to CDK application developers, navigate to the
desired certificate in AWS Certificate Manager. The ARN is listed under
"Certificate status".
