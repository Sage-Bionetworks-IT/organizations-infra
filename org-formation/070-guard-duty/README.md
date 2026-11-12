### Purpose of these templates
The templates in this folder enable [GuardDuty](https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html) in each account. Amazon GuardDuty is a continuous security monitoring service that analyzes and processes the following Data sources: VPC Flow Logs, AWS CloudTrail management event logs, Cloudtrail S3 data event logs, and DNS logs.

GuardDuty supports a management-member model, which this stack assumes. `SecurityCentralAccount` is the GuardDuty delegated administrator; all other accounts are member accounts.

The CloudFormation stack (`guardduty.yaml`) deploys an `AWS::GuardDuty::Detector` to `SecurityCentralAccount` only, in every region listed in the `guardDutyRegions` parameter (defined in `_tasks.yaml`). This is a subset of commercial regions — opt-in regions and newer regions are excluded. Expand the list as needed.

A detector in `SecurityCentralAccount` alone does **not** enable GuardDuty in the other accounts. The delegated administrator designation and org membership are both **per region**, and CloudFormation cannot manage either, so they are handled by companion CLI scripts:

1. `enable-delegated-admin.sh` — run in the organization management account. Calls `EnableOrganizationAdminAccount` in each region so `SecurityCentralAccount` is the GuardDuty delegated administrator there.
2. `configure-org-auto-enable.sh` — run in `SecurityCentralAccount` as `OrganizationAccountAccessRole` (the `RestrictDisableGuardduty` SCP blocks `CreateMembers` for SSO roles; see the script header for a profile that assumes it from the management account). In each region it enrolls the existing org accounts as members (using the us-east-1 `Enabled` member list as the source of truth) and sets the organization configuration to `AutoEnableOrganizationMembers: NEW` with protection features copied at run time from the us-east-1 organization configuration (`DescribeOrganizationConfiguration`), so us-east-1 is also the source of truth for features: change them there, then re-run the script. Existing accounts that are intentionally suspended in us-east-1 are not enrolled. (We deliberately avoid `ALL` here, which would re-enable every suspended account on apply. To re-enable a specific account, do it explicitly via the GuardDuty console or the `UpdateMemberDetectors` API.)

Both scripts read their region list from `guardDutyRegions` in `_tasks.yaml` (via `_guardduty-regions.sh`, which requires `python3` with PyYAML), so that parameter is the single source of truth.

### When to run the scripts
CI deploys only the CloudFormation stack (on merge to `master`); **neither script runs automatically.** Both are idempotent and accept `DRY_RUN=1`, so when in doubt, run a dry run and review it.

| Change | What to do |
|---|---|
| Add a region | Add it to `guardDutyRegions` in `_tasks.yaml` and merge, so CI deploys the detector there. Then run `enable-delegated-admin.sh`, then `configure-org-auto-enable.sh`. |
| Change protection features | Change them in the us-east-1 organization configuration (GuardDuty console or `UpdateOrganizationConfiguration`), then run `configure-org-auto-enable.sh` to copy them to the other regions. |
| Re-enable a suspended account (or otherwise make an existing account an `Enabled` member in us-east-1) | Run `configure-org-auto-enable.sh` so the account is enrolled in the other regions too. |
| New account joins the organization | Nothing. Auto-enable (`NEW`) enrolls it in every configured region. |
| Remove a region | Not handled by the scripts. Follow [Removing a region](#removing-a-region) **before** removing it from `guardDutyRegions`. |

### Removing a region
Neither script removes or disables anything. They only loop over the regions in `guardDutyRegions`, so a region taken off the list is simply ignored. Just deleting the region from `_tasks.yaml` causes problems:

- **Member accounts keep running GuardDuty and keep being billed** in that region. Per AWS, removing the delegated administrator "does not disable GuardDuty for member accounts"; they are only detached from SecurityCentral, so their findings are no longer aggregated anywhere.
- **The stack deletion is likely to fail.** org-formation tries to delete the stack, and with it the SecurityCentral detector, in the removed region. GuardDuty requires that "all member accounts must be disassociated or deleted before you can suspend or disable GuardDuty," so expect the delete, and that CI deploy, to fail while members remain.
- **Findings are lost** once the detector is deleted. Export them first if you need them.

To remove a region `R` cleanly, do these steps in order. These commands aren't scripted and have no `DRY_RUN`, so check the account list from `list-members` before running the commands that change anything.

1. **In SecurityCentralAccount, as `OrganizationAccountAccessRole`** (the `RestrictDisableGuardduty` SCP blocks these actions for SSO roles; use the profile from the `configure-org-auto-enable.sh` header):
   ```bash
   export AWS_PROFILE=OrganizationAccountAccessRole-Security-Central
   D=$(aws guardduty list-detectors --region R --query 'DetectorIds[0]' --output text)
   # Stop enrolling new accounts in R
   aws guardduty update-organization-configuration --region R --detector-id "$D" \
     --auto-enable-organization-members NONE
   # Member account IDs in R. The next three calls accept at most 50 IDs each;
   # with more members than that, run them in batches.
   IDS=$(aws guardduty list-members --region R --detector-id "$D" --only-associated false \
     --query 'Members[].AccountId' --output text)
   # Suspend GuardDuty in the member accounts (stops monitoring and charges; findings are kept)
   aws guardduty stop-monitoring-members --region R --detector-id "$D" --account-ids $IDS
   # Detach them and remove them from the member list
   aws guardduty disassociate-members --region R --detector-id "$D" --account-ids $IDS
   aws guardduty delete-members --region R --detector-id "$D" --account-ids $IDS
   ```
   Suspended member detectors stay in the member accounts, in a suspended state with no GuardDuty charges. Deleting those too has to be done from each member account.
2. **In the management account**, remove the delegated administrator for `R`:
   ```bash
   AWS_PROFILE=Administrator-Organization aws guardduty disable-organization-admin-account \
     --region R --admin-account-id 140124849929
   ```
3. **Remove `R` from `guardDutyRegions`** in `_tasks.yaml` and merge. CI deletes the stack and the SecurityCentral detector in `R`.

After that, `enable-delegated-admin.sh` and `configure-org-auto-enable.sh` no longer touch `R`.
