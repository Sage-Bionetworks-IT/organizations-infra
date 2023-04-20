### Purpose of these templates
The templates in this folder set up convenient redirects to other difficult to
remember URL locations.

### DNS for CDK ALBs
Some CDK applications create an ALB configured with a custom host name but are
not able to create the corresponding CNAME record because DNS is managed
centrally in the SageIT account, and so the record is created in org-formation
here. The CDK application will export its load balancer's name so that it can
easily be referenced when creating the CNAME record here. Once the application
has been deployed, a record can be created for each load balancer like in
[this example commit](https://github.com/Sage-Bionetworks-IT/organizations-infra/commit/1753dfab78cee0956ec4e265110131c3d73d8053).
