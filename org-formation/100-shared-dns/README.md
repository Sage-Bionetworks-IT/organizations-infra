## Purpose

Manage hosted zones and wildcard certificates for those zones.

Wildcard certs are generated for the apex records and are intended to be
shared by all services hosted in the zone by passing the ARN of the
appropriate certificate to the hosting service (e.g. CloudFront or an ALB).

Once the hosting service is deployed with the appropriate certificate, create
a DNS CNAME record to redirect our custom domain name to the AWS domain name
used by the hosting service.

Each wildcard cert will need to be manually verified before it can be used.

### sageit.org

This hosted zone was created manually and is shared between finops
microservices and some auth redirects (SSO and VPN).

A wildcard certificate has been created for this zone in sceptre:
./sceptre/sageit/config/prod/sageit-org-acm-cert.yaml

This directory is used for creating additional certificates in other
accounts and their associated DNS records.

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
