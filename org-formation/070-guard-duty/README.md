### Purpose of these templates
The templates in this folder enable [GuardDuty](https://docs.aws.amazon.com/guardduty/latest/ug/what-is-guardduty.html) in each account. Amazon GuardDuty is a continuous security monitoring service that analyzes and processes the following Data sources: VPC Flow Logs, AWS CloudTrail management event logs, Cloudtrail S3 data event logs, and DNS logs.

GuardDuty supports a management-member model, which this stack assumes. `SecurityCentralAccount` is the GuardDuty delegated administrator; all other accounts are member accounts.

The CloudFormation stack (`guardduty.yaml`) deploys an `AWS::GuardDuty::Detector` to `SecurityCentralAccount` only, in every region listed in the `guardDutyRegions` parameter (defined in `_tasks.yaml`). This is a subset of commercial regions — opt-in regions and newer regions are excluded. Expand the list as needed.

A detector in `SecurityCentralAccount` alone does **not** enable GuardDuty in the other accounts. The delegated administrator designation and org membership are both **per region**, and CloudFormation cannot manage either. They are handled by [`guardduty_org.py`](https://github.com/Sage-Bionetworks/infra-utils/tree/master/aws/guardduty) in the `Sage-Bionetworks/infra-utils` repo, which has subcommands for each job:

- `enable-admin`: run in the organization management account. Makes `SecurityCentralAccount` the GuardDuty delegated administrator in each region.
- `configure-members`: run in `SecurityCentralAccount` as `OrganizationAccountAccessRole` (the `RestrictDisableGuardduty` SCP blocks `CreateMembers` for SSO roles). In each region it enrolls the org accounts that are `Enabled` members in us-east-1, and sets `AutoEnableOrganizationMembers: NEW` with protection features copied from the us-east-1 organization configuration. us-east-1 is the source of truth for both members and features. Accounts intentionally suspended in us-east-1 are not enrolled. (We deliberately avoid `ALL`, which would re-enable every suspended account. To re-enable a specific account, do it explicitly via the GuardDuty console or the `UpdateMemberDetectors` API.)
- `add-region` and `remove-region`: the add and remove procedures below, for one region.

The tool reads its region list from `guardDutyRegions` in this directory's `_tasks.yaml` (passed with `--tasks-file`), so that parameter is the single source of truth. Its README covers installation, credentials and usage.

### When to run the tool
CI deploys only the CloudFormation stack (on merge to `master`); **the tool never runs automatically.** Every subcommand is idempotent and accepts `--dry-run`, so when in doubt, do a dry run and review it. In the commands below, `$TASKS` is the path to this `_tasks.yaml` in an up-to-date checkout of `master`.

| Change | What to do |
|---|---|
| Add a region | Add it to `guardDutyRegions` in `_tasks.yaml` and merge, so CI deploys the detector there. Then run `guardduty_org.py add-region R --tasks-file $TASKS --management-profile ... --security-profile ...` (or `enable-admin`, then `configure-members`, with `--region R`). |
| Change protection features | Change them in the us-east-1 organization configuration (GuardDuty console or `UpdateOrganizationConfiguration`), then run `guardduty_org.py configure-members` to copy them to the other regions. |
| Re-enable a suspended account (or otherwise make an existing account an `Enabled` member in us-east-1) | Run `guardduty_org.py configure-members` so the account is enrolled in the other regions too. |
| New account joins the organization | Nothing. Auto-enable (`NEW`) enrolls it in every configured region. |
| Remove a region | Run `guardduty_org.py remove-region` **before** removing it from `guardDutyRegions`. See [Removing a region](#removing-a-region). |

### Removing a region
Taking a region off `guardDutyRegions` doesn't remove or disable anything by itself, and causes problems if done first:

- **Member accounts keep running GuardDuty and keep being billed** in that region. Per AWS, removing the delegated administrator "does not disable GuardDuty for member accounts"; they are only detached from SecurityCentral, so their findings are no longer aggregated anywhere.
- **The stack deletion is likely to fail.** org-formation tries to delete the stack, and with it the SecurityCentral detector, in the removed region. GuardDuty requires that "all member accounts must be disassociated or deleted before you can suspend or disable GuardDuty," so expect the delete, and that CI deploy, to fail while members remain.
- **Findings are lost** once the detector is deleted. Export them first if you need them.

To remove a region `R` cleanly:

1. Run a dry run, review it, then run it for real (it asks you to type the region name to confirm):
   ```bash
   guardduty_org.py remove-region R --tasks-file $TASKS \
     --management-profile Administrator-Organization \
     --security-profile OrganizationAccountAccessRole-Security-Central --dry-run
   ```
   This stops auto-enable in `R`, suspends, disassociates and deletes every member there (suspending stops monitoring and charges; findings are kept), and removes the delegated administrator in `R`. Suspended member detectors stay in the member accounts, in a suspended state with no GuardDuty charges. Deleting those too has to be done from each member account.
2. **Remove `R` from `guardDutyRegions`** in `_tasks.yaml` and merge. CI deletes the stack and the SecurityCentral detector in `R`.

After that, the tool no longer touches `R`.
