#!/usr/bin/env bash
#
# Configures GuardDuty organization auto-enrollment for the delegated administrator
# (SecurityCentralAccount). New accounts joining the org will automatically have
# GuardDuty enabled. Existing accounts retain their current state.
#
# This is a companion to the CloudFormation stack — CloudFormation does not support
# AWS::GuardDuty::OrganizationConfiguration, so this must be run via CLI.
#
# Prerequisites:
#   - AWS CLI v2
#   - Credentials with permission to call guardduty:UpdateOrganizationConfiguration
#     in the SecurityCentralAccount (140124849929)
#
# Usage:
#   Assume a role in SecurityCentralAccount, then run:
#     ./configure-org-auto-enable.sh

set -euo pipefail

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
  echo "Configuring GuardDuty org auto-enable in ${region}..."

  detector_id=$(aws guardduty list-detectors --region "${region}" --query 'DetectorIds[0]' --output text)

  if [ -z "$detector_id" ] || [ "$detector_id" = "None" ]; then
    echo "  WARNING: No detector found in ${region}, skipping."
    continue
  fi

  aws guardduty update-organization-configuration \
    --detector-id "${detector_id}" \
    --auto-enable-organization-members NEW \
    --region "${region}"

  echo "  Done (detector: ${detector_id})"
done

echo "All regions configured."
