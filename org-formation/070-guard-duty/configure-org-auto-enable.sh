#!/usr/bin/env bash
#
# Configures GuardDuty organization membership for the delegated administrator
# (SecurityCentralAccount) in every region:
#   - Enrolls existing org accounts as members. The member list comes from the
#     us-east-1 detector's Enabled members, so coverage matches us-east-1 and
#     suspended/external (invite-based) accounts are not touched.
#   - Sets auto-enrollment so new accounts joining the org get GuardDuty, with
#     protection features matching the us-east-1 organization configuration.
#
# This is a companion to the CloudFormation stack — CloudFormation does not support
# AWS::GuardDuty::OrganizationConfiguration or org membership, so this must be run
# via CLI. The delegated administrator must already be enabled in each region
# (see ./enable-delegated-admin.sh).
#
# Prerequisites:
#   - AWS CLI v2, jq
#   - Credentials with permission to call guardduty:ListDetectors, guardduty:ListMembers,
#     guardduty:CreateMembers and guardduty:UpdateOrganizationConfiguration
#     in the SecurityCentralAccount (140124849929)
#
# Usage:
#   Assume a role in SecurityCentralAccount, then run:
#     ./configure-org-auto-enable.sh
#   Set DRY_RUN=1 to print the commands without running them.

set -euo pipefail

SOURCE_REGION=us-east-1

# Keep in sync with guardDutyRegions in _tasks.yaml and REGIONS in enable-delegated-admin.sh
REGIONS=(
  us-east-1
  us-east-2
  us-west-1
  us-west-2
  ca-central-1
  eu-west-1
  eu-west-2
  eu-west-3
  eu-central-1
  eu-north-1
  ap-northeast-1
  ap-northeast-2
  ap-northeast-3
  ap-southeast-1
  ap-southeast-2
  ap-south-1
  sa-east-1
)

# Matches the us-east-1 organization configuration; features not listed stay NONE.
FEATURES=(
  Name=S3_DATA_EVENTS,AutoEnable=ALL
  Name=EKS_AUDIT_LOGS,AutoEnable=ALL
  Name=EBS_MALWARE_PROTECTION,AutoEnable=ALL
  Name=RDS_LOGIN_EVENTS,AutoEnable=ALL
  Name=LAMBDA_NETWORK_LOGS,AutoEnable=ALL
  Name=RUNTIME_MONITORING,AutoEnable=ALL
)

# CreateMembers accepts at most 50 accounts per call
BATCH_SIZE=50

run() {
  if [ -n "${DRY_RUN:-}" ]; then
    echo "  DRY_RUN: $*"
  else
    "$@"
  fi
}

source_detector_id=$(aws guardduty list-detectors --region "${SOURCE_REGION}" --query 'DetectorIds[0]' --output text)
members=$(aws guardduty list-members --detector-id "${source_detector_id}" --region "${SOURCE_REGION}" \
  --query 'Members[?RelationshipStatus==`Enabled`].{AccountId: AccountId}' \
  --output json)
member_count=$(jq length <<< "${members}")
echo "Found ${member_count} Enabled members in ${SOURCE_REGION}."

for region in "${REGIONS[@]}"; do
  echo "Configuring GuardDuty org membership in ${region}..."

  detector_id=$(aws guardduty list-detectors --region "${region}" --query 'DetectorIds[0]' --output text)

  if [ -z "$detector_id" ] || [ "$detector_id" = "None" ]; then
    echo "  WARNING: No detector found in ${region}, skipping."
    continue
  fi

  if [ "$region" != "$SOURCE_REGION" ]; then
    for ((i = 0; i < member_count; i += BATCH_SIZE)); do
      batch=$(jq -c ".[${i}:$((i + BATCH_SIZE))]" <<< "${members}")
      run aws guardduty create-members \
        --detector-id "${detector_id}" \
        --account-details "${batch}" \
        --region "${region}" \
        --query 'UnprocessedAccounts' \
        --output text
    done
  fi

  run aws guardduty update-organization-configuration \
    --detector-id "${detector_id}" \
    --auto-enable-organization-members NEW \
    --features "${FEATURES[@]}" \
    --region "${region}"

  echo "  Done (detector: ${detector_id})"
done

echo "All regions configured."
