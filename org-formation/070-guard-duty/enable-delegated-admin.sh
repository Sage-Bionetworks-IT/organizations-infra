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
# When to run:
#   This script is NOT run by CI. Run it manually (it is idempotent) after a region is
#   added to guardDutyRegions in _tasks.yaml, once the change has merged and CI has
#   deployed the detector there, then run ./configure-org-auto-enable.sh. It is also safe
#   to re-run to restore the delegated administrator if it was removed in any region.
#   It is not needed for feature changes or for new accounts. See README.md.
#
# Prerequisites:
#   - AWS CLI v2
#   - python3 with PyYAML (regions are read from guardDutyRegions in _tasks.yaml)
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

source "$(dirname "${BASH_SOURCE[0]}")/_guardduty-regions.sh"
load_guardduty_regions
echo "Regions (from guardDutyRegions in _tasks.yaml): ${REGIONS[*]}"

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
