#!/usr/bin/env bash
#
# Designates SecurityCentralAccount as the GuardDuty delegated administrator in every
# region where the CloudFormation stack deploys a detector. The designation is per
# region; without it, the SecurityCentral detector in that region has no members and
# no other account in the org gets GuardDuty there.
#
# CloudFormation does not support this, so it must be run via CLI. Run this before
# ./configure-org-auto-enable.sh.
#
# Prerequisites:
#   - AWS CLI v2
#   - Credentials in the organization management account (531805629419) with permission
#     to call guardduty:EnableOrganizationAdminAccount and
#     guardduty:ListOrganizationAdminAccounts
#
# Usage:
#   Log in to the management account, then run with that profile:
#     aws sso login --profile Administrator-Organization
#     AWS_PROFILE=Administrator-Organization ./enable-delegated-admin.sh
#   Set DRY_RUN=1 to print the commands without running them.

set -euo pipefail

EXPECTED_ACCOUNT_ID=531805629419

caller_account=$(aws sts get-caller-identity --query Account --output text)
if [ "$caller_account" != "$EXPECTED_ACCOUNT_ID" ]; then
  echo "ERROR: Running as account ${caller_account}, expected ${EXPECTED_ACCOUNT_ID}." >&2
  echo "Run with AWS_PROFILE=Administrator-Organization (current AWS_PROFILE=${AWS_PROFILE:-<unset>})." >&2
  exit 1
fi

ADMIN_ACCOUNT_ID=140124849929  # SecurityCentralAccount

# Keep in sync with guardDutyRegions in _tasks.yaml and REGIONS in configure-org-auto-enable.sh
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

for region in "${REGIONS[@]}"; do
  echo "Checking GuardDuty delegated administrator in ${region}..."

  status=$(aws guardduty list-organization-admin-accounts --region "${region}" \
    --query "AdminAccounts[?AdminAccountId=='${ADMIN_ACCOUNT_ID}'].AdminStatus | [0]" \
    --output text)

  if [ "$status" = "ENABLED" ]; then
    echo "  Already enabled, skipping."
    continue
  fi

  cmd=(aws guardduty enable-organization-admin-account
    --admin-account-id "${ADMIN_ACCOUNT_ID}"
    --region "${region}")

  if [ -n "${DRY_RUN:-}" ]; then
    echo "  DRY_RUN: ${cmd[*]}"
  else
    "${cmd[@]}"
    echo "  Done"
  fi
done

echo "All regions configured."
