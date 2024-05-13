## Org-Formation Overview

We use [org-formation](https://github.com/org-formation/org-formation-cli/) to
deploy CloudFormation stacks to various accounts within our organization.

The various directories here group the stacks logically, and are
prefixed with numbers to enforce the order they are deployed in.

### Run First

- 000 [Initial Bootstrapping](./000-bootstrap) \
  Description of manual bootstrapping required before the first deploy.
- 005 [CloudFormation Types](./005-types) \
  Register custom types with CloudFormation.

### FinOps

- 040 [AWS Budgets](./040-budgets) \
  Configure budget alerts in AWS Budgets for tagged accounts.
- 050 [AWS Cost Explorer](./050-costs) \
  Configure anomaly detection, cost categories, and deploy related Lambdas.

### Security

- 070 [GuardDuty](./070-guard-duty) \
  Configure GuardDuty for all accounts.
- 075 [Security Hub](./075-security-hub) \
  Configure Security Hub for all accounts.
- 077 [Macie](./077-macie) \
  Configure AWS Macie for all accounts.
- 090 [Systems Manager](./090-systems-manager) \
  Configure Systems Manager for all accounts.
- 725 [vpc flow logs](./725-vpc-flow-logs) \
  Use AWS config to enable VPC flow logs

### Shared Application Infrastructure

- 100 [Shared DNS](./100-shared-dns) \
  Manage DNS zones and related wildcard ACM certificates for infrastructure
  shared with CDK applications.

### Global Account Configuration

- 200 [Baseline](./200-baseline) \
  Set global password policy and bootstrap all accounts for CDK.
- 300 [Account Defaults](./300-account-defaults) \
  Configure all accounts via custom CloudFormation types, deploy miscellaneous
  infrastructure expected in all accounts.

### Access and Connectivity

- 600 [IAM Access](./600-access) \
  Manage service accounts and cross-account access.
- 650 [JumpCloud IdP](./650-identity-providers) \
  Manage JumpCloud integration.
- 700 [AWS SSO](./700-aws-sso) \
  Manage access via AWS SSO.
- 705 [IP Address Manager](./705-ipam) \
  Configure IPAM account with required permissions.
- 710 [Transit Gateway](./710-tgw) \
  Configure Organization-wide hub-and-spoke network.
- 720 [AWS VPN Clients](./720-client-vpn) \
  Configure VPN client access.

### CloudWatch Persistence

- 730 [CloudWatch to S3](./730-cloudwatch-to-S3) \
  Persist CloudWatch data to S3.

### Application Redirects

- 800 [Redirects](./800-redirects) \
  Create S3 buckets used for HTTP 3xx redirects, and DNS CNAME records used by
  CDK applications.
