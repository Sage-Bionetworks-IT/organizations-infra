#!/usr/bin/env bash
#
# Configures GuardDuty organization membership for the delegated administrator
# (SecurityCentralAccount) in every region:
#   - Enrolls existing org accounts as members. The member list comes from the
#     us-east-1 detector's Enabled members, so coverage matches us-east-1 and
#     suspended/external (invite-based) accounts are not touched.
#   - Sets auto-enrollment so new accounts joining the org get GuardDuty, with
#     protection features copied from the us-east-1 organization configuration
#     (read via DescribeOrganizationConfiguration at run time). us-east-1 is the
#     source of truth: change features there, then re-run this script to propagate.
#
# This is a companion to the CloudFormation stack — CloudFormation does not support
# AWS::GuardDuty::OrganizationConfiguration or org membership, so this must be run
# via CLI. The delegated administrator must already be enabled in each region
# (see ./enable-delegated-admin.sh).
#
# When to run:
#   This script is NOT run by CI; the deploy pipeline only applies the CloudFormation
#   stack. Run it manually (it is idempotent) when:
#   - A region is added to guardDutyRegions in _tasks.yaml: after the change merges and
#     CI deploys the detector, run ./enable-delegated-admin.sh, then this script.
#   - Protection features change: change them in the us-east-1 organization
#     configuration (console or CLI), then run this script to copy them to the other
#     regions.
#   - An existing account becomes an Enabled member in us-east-1 outside of
#     auto-enable (e.g. a suspended account is re-enabled), so it is enrolled in the
#     other regions too.
#   Not needed for new accounts joining the organization; auto-enable (NEW) enrolls them
#   in every configured region.
#   Removing a region is not handled by these scripts; see README.md.
#
# Prerequisites:
#   - AWS CLI v2, jq
#   - python3 with PyYAML (regions are read from guardDutyRegions in _tasks.yaml)
#   - Credentials with permission to call guardduty:ListDetectors, guardduty:ListMembers,
#     guardduty:DescribeOrganizationConfiguration, guardduty:CreateMembers, guardduty:UpdateOrganizationConfiguration and
#     organizations:ListAccounts in the SecurityCentralAccount (140124849929)
#
# Usage:
#   The RestrictDisableGuardduty SCP (see ../_scp.yaml) denies guardduty:CreateMembers to
#   everything except OrganizationAccountAccessRole, so SSO roles in SecurityCentralAccount
#   cannot run this. Assume that role from the management account instead, e.g. with this
#   profile in ~/.aws/config:
#     [profile OrganizationAccountAccessRole-Security-Central]
#     role_arn = arn:aws:iam::140124849929:role/OrganizationAccountAccessRole
#     source_profile = Administrator-Organization
#   then run:
#     aws sso login --profile Administrator-Organization
#     AWS_PROFILE=OrganizationAccountAccessRole-Security-Central ./configure-org-auto-enable.sh
#   Set DRY_RUN=1 to print the commands without running them.

set -euo pipefail

EXPECTED_ACCOUNT_ID=140124849929

caller_account=$(aws sts get-caller-identity --query Account --output text)
if [ "$caller_account" != "$EXPECTED_ACCOUNT_ID" ]; then
  echo "ERROR: Running as account ${caller_account}, expected ${EXPECTED_ACCOUNT_ID}." >&2
  echo "Run with AWS_PROFILE=OrganizationAccountAccessRole-Security-Central (current AWS_PROFILE=${AWS_PROFILE:-<unset>})." >&2
  exit 1
fi

SOURCE_REGION=us-east-1

source "$(dirname "${BASH_SOURCE[0]}")/_guardduty-regions.sh"
load_guardduty_regions
if [[ " ${REGIONS[*]} " != *" ${SOURCE_REGION} "* ]]; then
  echo "ERROR: SOURCE_REGION ${SOURCE_REGION} is not in guardDutyRegions." >&2
  exit 1
fi
echo "Regions (from guardDutyRegions in _tasks.yaml): ${REGIONS[*]}"

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

# Copy protection-feature settings (including NONE) from the us-east-1 organization
# configuration. Some features that DescribeOrganizationConfiguration returns can't be
# sent back through UpdateOrganizationConfiguration, so they are skipped:
#   - EKS_RUNTIME_MONITORING: legacy form of RUNTIME_MONITORING, which supersedes it.
#   - AI_ANALYST: not an accepted feature name for UpdateOrganizationConfiguration
#     (the API rejects it with "one or more provided feature names are invalid").
NON_UPDATABLE_FEATURES='["EKS_RUNTIME_MONITORING", "AI_ANALYST"]'
features=$(aws guardduty describe-organization-configuration \
  --detector-id "${source_detector_id}" --region "${SOURCE_REGION}" --output json |
  jq -c --argjson skip "${NON_UPDATABLE_FEATURES}" '[.Features[]?
          | select(.Name as $n | $skip | index($n) | not)
          | {Name, AutoEnable}
            + (if .AdditionalConfiguration
               then {AdditionalConfiguration: [.AdditionalConfiguration[] | {Name, AutoEnable}]}
               else {} end)]')
if [ "$(jq length <<< "${features}")" -eq 0 ]; then
  echo "ERROR: No features found in the ${SOURCE_REGION} organization configuration." >&2
  exit 1
fi
echo "Features (from ${SOURCE_REGION} organization configuration):"
jq -r '.[] | "  \(.Name)=\(.AutoEnable)"
             + (if .AdditionalConfiguration
                then " (" + ([.AdditionalConfiguration[] | "\(.Name)=\(.AutoEnable)"] | join(", ")) + ")"
                else "" end)' <<< "${features}"

member_ids=$(aws guardduty list-members --detector-id "${source_detector_id}" --region "${SOURCE_REGION}" \
  --query 'Members[?RelationshipStatus==`Enabled`].AccountId' \
  --output json)
# The CLI requires Email in each AccountDetails entry, but ListMembers returns null
# for org-managed members, so take emails from Organizations instead.
org_accounts=$(aws organizations list-accounts --query 'Accounts[].{AccountId: Id, Email: Email}' --output json)
members=$(jq -c --argjson ids "${member_ids}" '[.[] | select(.AccountId as $id | $ids | index($id))]' <<< "${org_accounts}")
member_count=$(jq length <<< "${members}")
if [ "${member_count}" -ne "$(jq length <<< "${member_ids}")" ]; then
  echo "ERROR: Some ${SOURCE_REGION} members were not found in the organization." >&2
  exit 1
fi
echo "Found ${member_count} Enabled members in ${SOURCE_REGION}."

for region in "${REGIONS[@]}"; do
  echo "Configuring GuardDuty org membership in ${region}..."

  detector_id=$(aws guardduty list-detectors --region "${region}" --query 'DetectorIds[0]' --output text)

  if [ -z "$detector_id" ] || [ "$detector_id" = "None" ]; then
    echo "  WARNING: No detector found in ${region}, skipping."
    continue
  fi

  # Not every feature is available in every region (e.g. AI_ANALYST in ap-south-1), so
  # only send the features and additional configurations this region reports.
  region_config=$(aws guardduty describe-organization-configuration \
    --detector-id "${detector_id}" --region "${region}" --output json)
  region_features=$(jq -c --argjson cfg "${region_config}" '
    ($cfg.Features // [] | map({key: .Name, value: [.AdditionalConfiguration[]?.Name]}) | from_entries) as $avail
    | [.[] | select($avail[.Name] != null)
           | if .AdditionalConfiguration
             then .Name as $n | .AdditionalConfiguration |= map(select(.Name as $a | $avail[$n] | index($a)))
             else . end
           | if .AdditionalConfiguration == [] then del(.AdditionalConfiguration) else . end]' <<< "${features}")
  skipped=$(jq -r --argjson kept "${region_features}" '[.[].Name] - [$kept[].Name] | join(", ")' <<< "${features}")
  if [ -n "${skipped}" ]; then
    echo "  Not available in ${region}, skipping: ${skipped}"
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
    --features "${region_features}" \
    --region "${region}"

  echo "  Done (detector: ${detector_id})"
done

echo "All regions configured."
