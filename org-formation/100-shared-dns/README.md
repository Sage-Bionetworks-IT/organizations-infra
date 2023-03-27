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
