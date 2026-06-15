### Purpose of these templates
The templates in this folder enable [GuardDuty](https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html) in each account. Amazon GuardDuty is a continuous security monitoring service that analyzes and processes the following Data sources: VPC Flow Logs, AWS CloudTrail management event logs, Cloudtrail S3 data event logs, and DNS logs.

GuardDuty supports a management-member model, which this stack assumes. `SecurityCentralAccount` is the GuardDuty delegated administrator; all other accounts are member accounts.

**Note:** the delegated-administrator designation itself (the AWS Organizations `EnableOrganizationAdminAccount` call that must run in the management/master account) is **not** managed by this IaC — it was bootstrapped manually and lives outside this repo. This stack does not include `AWS::GuardDuty::OrganizationAdminAccount`. What is codified here:

- `AWS::GuardDuty::Detector` deployed to `SecurityCentralAccount` in every region listed in the `guardDutyRegions` parameter (defined in `_tasks.yaml`). This is a subset of commercial regions — opt-in regions and newer regions are excluded. Expand the list as needed.
- `AWS::GuardDuty::OrganizationConfiguration` with `AutoEnableOrganizationMembers: NEW` so that new accounts joining the org are auto-enrolled. Existing accounts retain their current state — accounts that are intentionally suspended stay suspended. (We deliberately avoid `ALL` here, which would re-enable every suspended account on apply. To re-enable a specific account, do it explicitly via the GuardDuty console or the `UpdateMemberDetectors` API.) This resource depends on the delegated-admin relationship already being in place.
