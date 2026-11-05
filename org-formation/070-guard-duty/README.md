### Purpose of these templates
The templates in this folder enable [GuardDuty](https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html) in each account. Amazon GuardDuty is a continuous security monitoring service that analyzes and processes the following Data sources: VPC Flow Logs, AWS CloudTrail management event logs, Cloudtrail S3 data event logs, and DNS logs.

GuardDuty supports a management-member model, which this stack assumes. `SecurityCentralAccount` is the GuardDuty delegated administrator; all other accounts are member accounts.

The CloudFormation stack (`guardduty.yaml`) deploys an `AWS::GuardDuty::Detector` to `SecurityCentralAccount` only, in every region listed in the `guardDutyRegions` parameter (defined in `_tasks.yaml`). This is a subset of commercial regions — opt-in regions and newer regions are excluded. Expand the list as needed.

A detector in `SecurityCentralAccount` alone does **not** enable GuardDuty in the other accounts. The delegated administrator designation and org membership are both **per region**, and CloudFormation cannot manage either, so they are handled by companion CLI scripts:

1. `enable-delegated-admin.sh` — run in the organization management account. Calls `EnableOrganizationAdminAccount` in each region so `SecurityCentralAccount` is the GuardDuty delegated administrator there.
2. `configure-org-auto-enable.sh` — run in `SecurityCentralAccount` as `OrganizationAccountAccessRole` (the `RestrictDisableGuardduty` SCP blocks `CreateMembers` for SSO roles; see the script header for a profile that assumes it from the management account). In each region it enrolls the existing org accounts as members (using the us-east-1 `Enabled` member list as the source of truth) and sets the organization configuration to `AutoEnableOrganizationMembers: NEW` with protection features matching us-east-1. Existing accounts that are intentionally suspended in us-east-1 are not enrolled. (We deliberately avoid `ALL` here, which would re-enable every suspended account on apply. To re-enable a specific account, do it explicitly via the GuardDuty console or the `UpdateMemberDetectors` API.)

When adding a region: deploy the stack, then run script 1, then script 2. Both scripts are idempotent and accept `DRY_RUN=1`.
