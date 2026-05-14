### Purpose of these templates
The templates in this folder enable [GuardDuty](https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html) in each account. Amazon GuardDuty is a continuous security monitoring service that analyzes and processes the following Data sources: VPC Flow Logs, AWS CloudTrail management event logs, Cloudtrail S3 data event logs, and DNS logs.

GuardDuty supports a management-member model, which this stack assumes. `SecurityCentralAccount` is the GuardDuty delegated administrator; all other accounts are member accounts.

**Note:** the delegated-administrator designation itself (the AWS Organizations `EnableOrganizationAdminAccount` call that must run in the management/master account) is **not** managed by this IaC — it was bootstrapped manually and lives outside this repo. This stack does not include `AWS::GuardDuty::OrganizationAdminAccount`. What is codified here:

- `AWS::GuardDuty::Detector` deployed to `SecurityCentralAccount` in every region listed in the `guardDutyRegions` parameter (see `org-formation/_parameters.yaml`), which covers all commercial regions where GuardDuty is supported.
- `AWS::GuardDuty::OrganizationConfiguration` with `AutoEnableOrganizationMembers: ALL` to enroll every current member account and auto-enroll new accounts. This resource depends on the delegated-admin relationship already being in place.

### Notifications

`notifications.yaml` is deployed to every account, but only in `primaryRegion` (us-east-1). Each stack creates:

| Resource  | Description |
|-----------| ----------- |
| SNS topic | `guardduty-topic` — subscribed to the account's `RootEmail` from `organization.yaml` (resolved via `!GetAtt CurrentAccount.RootEmail`) |
| EventBridge rule | `detect-guardduty-finding` — fires on `aws.guardduty` "GuardDuty Finding" events with `severity >= 7.0` (High only) and targets the SNS topic |

Each account owner receives email notifications for High-severity findings detected in their account in `primaryRegion`. SecurityCentralAccount (as delegated admin) additionally receives propagated events for every member-account finding in `primaryRegion`, so `aws.securitycentral@sagebase.org` has an aggregate view by email for that region.

**Why notifications run only in `primaryRegion`:** SNS email subscriptions require a one-time confirmation click per (account, region). Deploying the stack in all `guardDutyRegions` would generate ~20 confirmation emails per account, which is impractical. Detection itself still runs in every region in `guardDutyRegions`, so threats anywhere are still discovered; non-`primaryRegion` findings remain visible in the GuardDuty console — the SecurityCentralAccount delegated admin aggregates findings across all regions. If email coverage for additional regions is needed later, extend the `Region:` binding in `_tasks.yaml`.

The first email to each `RootEmail` is an SNS subscription confirmation that the owner must click once to activate delivery.
