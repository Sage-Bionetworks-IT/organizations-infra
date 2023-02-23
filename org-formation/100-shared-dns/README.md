## Purpose
These hosted zones will contain DNS records for general-purpose services
such as DCA and Schematic.

Wildcard certs are generated for the apex records and are intended to be
shared by all services hosted in the zone by passing the ARN of the
appropriate certificate to the CDK application deploying the service.

Once a service has been created by the CDK application, create a DNS CNAME
record in the appropriate hosted zone with a value pointing to the name of the
ALB created in, and exported by, the CDK application.
