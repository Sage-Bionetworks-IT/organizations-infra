### Purpose of these templates
The templates in this folder enable [GuardDuty](https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html) in each account. Amazon GuardDuty is a continuous security monitoring service that analyzes and processes the following Data sources: VPC Flow Logs, AWS CloudTrail management event logs, Cloudtrail S3 data event logs, and DNS logs.

GuardDuty supports a management-member model, which this stack uses. `SecurityCentralAccount` is configured as the GuardDuty delegated administrator; all other accounts are member accounts. `AWS::GuardDuty::OrganizationConfiguration` with `AutoEnableOrganizationMembers: ALL` ensures every current member account is enrolled and new accounts are auto-enrolled.

Detector + organization configuration are deployed to SecurityCentralAccount in every region listed in the `guardDutyRegions` parameter (see `org-formation/_parameters.yaml`), which covers all commercial regions where GuardDuty is supported.

### Notifications

`notifications.yaml` is deployed to every account in every GuardDuty region. Each stack creates:

| Resource  | Description |
|-----------| ----------- |
| SNS topic | `guardduty-topic` — subscribed to the account's `RootEmail` from `organization.yaml` (resolved via `!GetAtt CurrentAccount.RootEmail`) |
| EventBridge rule | `detect-guardduty-finding` — fires on `aws.guardduty` "GuardDuty Finding" events with `severity >= 7.0` (High only) and targets the SNS topic |

Each account owner receives email notifications for High-severity findings in their own account. SecurityCentralAccount (as delegated admin) additionally receives propagated events for every member-account finding, so `aws.securitycentral@sagebase.org` ends up with an org-wide view automatically.

The first email to each `RootEmail` is an SNS subscription confirmation that the owner must click to activate delivery.
